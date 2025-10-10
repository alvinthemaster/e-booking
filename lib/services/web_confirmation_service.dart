import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_models.dart';

class WebConfirmationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  
  // Base URL for your web confirmation (you can change this to your domain)
  static const String baseUrl = 'https://alvinthemaster.github.io/e-booking/web';
  
  // Conductor PIN for confirmation (in production, store this securely)
  static const String conductorPin = '2024';

  /// Generate a secure confirmation token and URL for a booking
  Future<Map<String, String>> generateConfirmationToken(String bookingId) async {
    try {
      // Generate unique token
      final token = _uuid.v4();
      
      // Token expires in 24 hours
      final expiresAt = DateTime.now().add(const Duration(hours: 24));
      
      // Create confirmation URL
      final confirmationUrl = '$baseUrl/confirm.html?token=$token';
      
      // Store token data in Firestore
      await _firestore.collection('confirmation_tokens').doc(token).set({
        'bookingId': bookingId,
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isUsed': false,
        'confirmationStatus': 'pending',
      });
      
      // Update booking with token and URL
      await _firestore.collection('bookings').doc(bookingId).update({
        'confirmationToken': token,
        'tokenExpiresAt': Timestamp.fromDate(expiresAt),
        'confirmationStatus': 'pending',
        'confirmationUrl': confirmationUrl,
      });
      
      return {
        'token': token,
        'url': confirmationUrl,
      };
    } catch (e) {
      throw Exception('Failed to generate confirmation token: $e');
    }
  }

  /// Validate a confirmation token
  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final tokenDoc = await _firestore
          .collection('confirmation_tokens')
          .doc(token)
          .get();
      
      if (!tokenDoc.exists) {
        return {
          'isValid': false,
          'error': 'Invalid or expired token',
          'errorType': 'invalid_token'
        };
      }
      
      final tokenData = tokenDoc.data()!;
      final expiresAt = (tokenData['expiresAt'] as Timestamp).toDate();
      final isUsed = tokenData['isUsed'] ?? false;
      
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'isValid': false,
          'error': 'Token has expired',
          'errorType': 'expired_token'
        };
      }
      
      if (isUsed) {
        return {
          'isValid': false,
          'error': 'Token has already been used',
          'errorType': 'token_used'
        };
      }
      
      // Get booking details
      final bookingId = tokenData['bookingId'];
      final bookingDoc = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get();
      
      if (!bookingDoc.exists) {
        return {
          'isValid': false,
          'error': 'Booking not found',
          'errorType': 'booking_not_found'
        };
      }
      
      final booking = Booking.fromMap(bookingDoc.data()!);
      
      return {
        'isValid': true,
        'booking': booking,
        'token': token,
        'tokenData': tokenData,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Validation failed: $e',
        'errorType': 'validation_error'
      };
    }
  }

  /// Confirm boarding with conductor PIN
  Future<Map<String, dynamic>> confirmBoarding(String token, String pin) async {
    try {
      // Validate PIN
      if (pin != conductorPin) {
        return {
          'success': false,
          'error': 'Invalid conductor PIN',
          'errorType': 'invalid_pin'
        };
      }
      
      // Validate token first
      final validation = await validateToken(token);
      if (!validation['isValid']) {
        return {
          'success': false,
          'error': validation['error'],
          'errorType': validation['errorType']
        };
      }
      
      final booking = validation['booking'] as Booking;
      final now = DateTime.now();
      
      // Update booking status to onboard
      await _firestore.collection('bookings').doc(booking.id).update({
        'bookingStatus': 'onboard',
        'confirmationStatus': 'confirmed',
        'confirmedBy': 'conductor',
        'confirmedAt': Timestamp.fromDate(now),
      });
      
      // Mark token as used
      await _firestore.collection('confirmation_tokens').doc(token).update({
        'isUsed': true,
        'usedAt': Timestamp.fromDate(now),
        'confirmedBy': 'conductor',
      });
      
      return {
        'success': true,
        'message': 'Boarding confirmed successfully',
        'booking': booking,
        'confirmedAt': now,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Confirmation failed: $e',
        'errorType': 'confirmation_error'
      };
    }
  }

  /// Get booking details for web display
  Future<Map<String, dynamic>> getBookingForDisplay(String token) async {
    try {
      final validation = await validateToken(token);
      
      if (!validation['isValid']) {
        return validation;
      }
      
      final booking = validation['booking'] as Booking;
      
      return {
        'isValid': true,
        'booking': {
          'id': booking.id,
          'passengerName': booking.userName,
          'email': booking.userEmail,
          'route': '${booking.origin} → ${booking.destination}',
          'routeName': booking.routeName,
          'departureTime': booking.departureTime.toString(),
          'seatNumbers': booking.seatIds.join(', '),
          'numberOfSeats': booking.numberOfSeats,
          'totalAmount': booking.totalAmount,
          'paymentStatus': booking.paymentStatus.name,
          'bookingStatus': booking.bookingStatus.name,
          'vanDetails': {
            'plateNumber': booking.vanPlateNumber,
            'driverName': booking.vanDriverName,
            'driverContact': booking.vanDriverContact,
          },
          'bookingDate': booking.bookingDate.toString(),
        },
        'token': token,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Failed to get booking details: $e',
        'errorType': 'fetch_error'
      };
    }
  }

  /// Check if a booking already has an active confirmation token
  Future<String?> getExistingToken(String bookingId) async {
    try {
      final tokensQuery = await _firestore
          .collection('confirmation_tokens')
          .where('bookingId', isEqualTo: bookingId)
          .where('isUsed', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();
      
      if (tokensQuery.docs.isNotEmpty) {
        return tokensQuery.docs.first.data()['token'];
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cleanup expired tokens (should be run periodically)
  Future<void> cleanupExpiredTokens() async {
    try {
      final expiredTokens = await _firestore
          .collection('confirmation_tokens')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in expiredTokens.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Failed to cleanup expired tokens: $e');
    }
  }
}