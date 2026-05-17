import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PhilSmsResult {
  final bool success;
  final int? statusCode;
  final String message;
  final String? response;

  const PhilSmsResult({
    required this.success,
    this.statusCode,
    required this.message,
    this.response,
  });
}

class PhilSmsService {
  static const String _apiKey = String.fromEnvironment(
    'PHILSMS_API_KEY',
    defaultValue: '3026|byj3XBrWzBu0juloft2cOuEKJk7A2AQ6UX7gfkFL75d08edd',
  );
  static const String _senderId = String.fromEnvironment(
    'PHILSMS_SENDER_ID',
    defaultValue: 'PhilSMS',
  );

  // PhilSMS direct endpoint.
  // On Flutter Web, a CORS proxy is prepended automatically (demo only).
  static const String _philSmsEndpoint =
      'https://dashboard.philsms.com/api/v3/sms/send';
  static const String _corsProxy = 'https://corsproxy.io/?';

  static final Map<String, DateTime> _lastSendByRecipient = {};
  static const Duration _cooldownDuration = Duration(seconds: 30);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _buildBearerAuthHeader(String rawApiKey) {
    final token = rawApiKey.trim();
    if (token.isEmpty) return '';
    if (token.toLowerCase().startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  bool _looksUnauthenticated(Map<String, dynamic> data, String raw) {
    final message = (data['message']?.toString() ?? raw).toLowerCase();
    return message.contains('unauthenticated') ||
        message.contains('invalid token') ||
        message.contains('unauthorized');
  }

  Future<http.Response> _postSms({
    required String endpoint,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) {
    return http
        .post(
          Uri.parse(endpoint),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
  }

  /// Normalizes any PH number to +639XXXXXXXXX (PhilSMS docs sample format).
  String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('63') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 11) {
      return '+63${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('9')) return '+63$digits';
    return digits;
  }

  bool _isValidPHNumber(String normalized) =>
      RegExp(r'^\+63[0-9]{10}$').hasMatch(normalized);

  bool _isInCooldown(String normalizedPhone) {
    final last = _lastSendByRecipient[normalizedPhone];
    if (last == null) return false;
    return DateTime.now().difference(last) < _cooldownDuration;
  }

  ({bool success, String message}) _interpretProviderResult(
    int statusCode,
    Map<String, dynamic> data,
    String raw,
  ) {
    debugPrint('[PhilSMS] HTTP $statusCode | Response: $raw');

    if (statusCode == 401 || statusCode == 403) {
      return (
        success: false,
        message:
            'PhilSMS rejected the request (HTTP $statusCode — Unauthenticated). '
            'Your PHILSMS_API_KEY may be invalid, expired, or revoked. '
            'Go to app.philsms.com → Developers → Regenerate Token.',
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      return (success: false, message: 'PhilSMS HTTP $statusCode: $raw');
    }

    // PhilSMS sometimes returns HTTP 200 with status=error
    final statusText = data['status']?.toString().toLowerCase();
    if (statusText == 'error') {
      final errorMessage = data['message']?.toString() ?? '';
      if (errorMessage.toLowerCase().contains('unauthenticated')) {
        return (
          success: false,
          message:
              'PhilSMS token is invalid or expired (Unauthenticated). '
              'Generate a new token in app.philsms.com > Developers and update PHILSMS_API_KEY.',
        );
      }
      return (
        success: false,
        message: errorMessage.isNotEmpty
            ? errorMessage
            : 'PhilSMS returned status: error.',
      );
    }

    final explicitSuccess = data['success'];
    if (explicitSuccess is bool && !explicitSuccess) {
      return (
        success: false,
        message: data['message']?.toString() ?? 'PhilSMS returned success=false.',
      );
    }

    const accepted = {'success', 'accepted', 'queued', 'pending', 'sent'};
    if (statusText != null && accepted.contains(statusText)) {
      return (
        success: true,
        message: data['message']?.toString() ?? 'SMS queued by provider.',
      );
    }

    // Check nested data array (PhilSMS sometimes wraps result in data[])
    final nested = data['data'];
    if (nested is List && nested.isNotEmpty && nested.first is Map) {
      final first = Map<String, dynamic>.from(nested.first as Map);
      final nestedStatus = first['status']?.toString().toLowerCase() ?? '';
      if (accepted.contains(nestedStatus)) {
        return (
          success: true,
          message: data['message']?.toString() ?? 'SMS accepted by provider.',
        );
      }
      return (
        success: false,
        message: first['message']?.toString() ??
            data['message']?.toString() ??
            'Provider did not accept SMS. Status: $nestedStatus',
      );
    }

    if (data.containsKey('error') || data.containsKey('errors')) {
      return (
        success: false,
        message: data['message']?.toString() ??
            data['error']?.toString() ??
            'PhilSMS returned an error.',
      );
    }

    // HTTP 2xx with no error fields — treat as success
    return (
      success: true,
      message: data['message']?.toString() ?? 'SMS accepted by provider.',
    );
  }

  Future<void> _logSms({
    required String phoneNumber,
    required String message,
    required String status,
    String? response,
    int? statusCode,
    String sender = 'PhilSMS',
  }) async {
    try {
      await _firestore.collection('sms_logs').add({
        'phoneNumber': phoneNumber,
        'message': message,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'response': response,
        'statusCode': statusCode,
        'sender': sender,
        'requestedBy': _auth.currentUser?.uid,
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (_) {
      // Logging failures must not break SMS flow.
    }
  }

  Future<PhilSmsResult> sendSms({
    required String recipient,
    required String message,
  }) async {
    // ── Guard: API key ──────────────────────────────────────────────────────
    if (_apiKey.trim().isEmpty) {
      return const PhilSmsResult(
        success: false,
        message:
            'Missing PHILSMS_API_KEY. Pass --dart-define=PHILSMS_API_KEY=... when running Flutter.',
      );
    }

    // ── Guard: message ──────────────────────────────────────────────────────
    if (message.trim().isEmpty) {
      return const PhilSmsResult(
        success: false,
        message: 'SMS message is required.',
      );
    }

    // ── Normalize & validate phone ──────────────────────────────────────────
    final normalized = normalizePhone(recipient);
    if (!_isValidPHNumber(normalized)) {
      return PhilSmsResult(
        success: false,
        message:
            'Invalid Philippine mobile number: "$recipient". '
            'Expected format: 09XXXXXXXXX or 639XXXXXXXXX.',
      );
    }

    // ── Cooldown ────────────────────────────────────────────────────────────
    if (_isInCooldown(normalized)) {
      return const PhilSmsResult(
        success: false,
        message: 'Please wait before sending another SMS to this number.',
      );
    }

    // ── Build request ───────────────────────────────────────────────────────
    final normalizedNoPlus = normalized.startsWith('+')
        ? normalized.substring(1)
        : normalized;

    final bearerHeaders = {
      'Authorization': _buildBearerAuthHeader(_apiKey),
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final basicHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final requestAttempts = <({String label, Map<String, String> headers, Map<String, dynamic> body})>[
      (
        label: 'Bearer + +63 recipient',
        headers: bearerHeaders,
        body: {
          'recipient': normalized,
          'sender_id': _senderId,
          'message': message.trim(),
        },
      ),
      (
        label: 'Bearer + 63 recipient',
        headers: bearerHeaders,
        body: {
          'recipient': normalizedNoPlus,
          'sender_id': _senderId,
          'message': message.trim(),
        },
      ),
      (
        label: 'api_token body + +63 recipient',
        headers: basicHeaders,
        body: {
          'api_token': _apiKey.trim(),
          'recipient': normalized,
          'sender_id': _senderId,
          'message': message.trim(),
        },
      ),
      (
        label: 'api_token body + 63 recipient',
        headers: basicHeaders,
        body: {
          'api_token': _apiKey.trim(),
          'recipient': normalizedNoPlus,
          'sender_id': _senderId,
          'message': message.trim(),
        },
      ),
    ];

    // Flutter Web: prepend CORS proxy (demo only — PhilSMS does not set CORS headers)
    final endpoint = kIsWeb
        ? '$_corsProxy${Uri.encodeComponent(_philSmsEndpoint)}'
        : _philSmsEndpoint;

    // ── Debug log ───────────────────────────────────────────────────────────
    debugPrint('[PhilSMS] ══════════════════════════════════════');
    debugPrint('[PhilSMS] Platform : ${kIsWeb ? "Flutter Web" : "Native"}');
    debugPrint('[PhilSMS] Endpoint : $endpoint');
    debugPrint('[PhilSMS] Headers  : $bearerHeaders');
    debugPrint('[PhilSMS] ════════════════════════════════════════');

    try {
      PhilSmsResult? firstFailure;

      for (final attempt in requestAttempts) {
        debugPrint('[PhilSMS] Attempt  : ${attempt.label}');
        debugPrint('[PhilSMS] Body     : ${jsonEncode(attempt.body)}');

        final response = await _postSms(
          endpoint: endpoint,
          headers: attempt.headers,
          body: attempt.body,
        );

        debugPrint('[PhilSMS] Status   : ${response.statusCode}');
        debugPrint('[PhilSMS] Response : ${response.body}');

        Map<String, dynamic> data = {};
        try {
          data = Map<String, dynamic>.from(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        } catch (_) {
          data = {'raw': response.body};
        }

        final interpreted =
            _interpretProviderResult(response.statusCode, data, response.body);

        if (interpreted.success) {
          _lastSendByRecipient[normalized] = DateTime.now();

          await _logSms(
            phoneNumber: normalized,
            message: message.trim(),
            status: 'sent',
            response: response.body,
            statusCode: response.statusCode,
            sender: _senderId,
          );

          return PhilSmsResult(
            success: true,
            statusCode: response.statusCode,
            message: interpreted.message,
            response: response.body,
          );
        }

        firstFailure ??= PhilSmsResult(
          success: false,
          statusCode: response.statusCode,
          message: interpreted.message,
          response: response.body,
        );

        // Continue only for auth-style issues. Stop for other provider errors.
        if (!_looksUnauthenticated(data, response.body)) {
          break;
        }
      }

      await _logSms(
        phoneNumber: normalized,
        message: message.trim(),
        status: 'failed',
        response: firstFailure?.response,
        statusCode: firstFailure?.statusCode,
        sender: _senderId,
      );

      return firstFailure ??
          const PhilSmsResult(
            success: false,
            message: 'PhilSMS request failed without a detailed response.',
          );
    } on http.ClientException catch (e) {
      String detail = e.message;
      if (kIsWeb &&
          (detail.contains('XMLHttpRequest') ||
              detail.toLowerCase().contains('cors') ||
              detail.trim().isEmpty)) {
        detail =
            'CORS error on Flutter Web: The browser blocked the request to PhilSMS. '
            'This is a browser security restriction. '
            'Try running on a physical Android/iOS device instead, '
            'or use the CORS proxy (already active on web builds).';
      }
      debugPrint('[PhilSMS] ClientException: $detail');
      await _logSms(
        phoneNumber: normalized,
        message: message.trim(),
        status: 'error',
        response: detail,
      );
      return PhilSmsResult(success: false, message: detail);
    } on TimeoutException {
      debugPrint('[PhilSMS] Request timed out.');
      return const PhilSmsResult(
        success: false,
        message:
            'PhilSMS request timed out. Check internet connection and try again.',
      );
    } on FormatException catch (e) {
      debugPrint('[PhilSMS] FormatException: $e');
      return PhilSmsResult(
        success: false,
        message: 'Invalid PhilSMS response format: $e',
      );
    } catch (e) {
      debugPrint('[PhilSMS] Unexpected error: $e');
      return PhilSmsResult(
        success: false,
        message: 'SMS request error: $e',
      );
    }
  }
}
