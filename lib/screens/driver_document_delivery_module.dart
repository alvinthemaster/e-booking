import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_delivery_model.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/document_delivery_service.dart';
import '../services/philsms_service.dart';

class DriverDocumentDeliveryModule extends StatefulWidget {
  final String vanPlateNumber;

  const DriverDocumentDeliveryModule({
    super.key,
    required this.vanPlateNumber,
  });

  @override
  State<DriverDocumentDeliveryModule> createState() =>
      _DriverDocumentDeliveryModuleState();
}

class _DriverDocumentDeliveryModuleState extends State<DriverDocumentDeliveryModule> {
  final DocumentDeliveryService _deliveryService = DocumentDeliveryService();
  final PhilSmsService _smsService = PhilSmsService();

  final Map<String, bool> _isNotifying = {};
  final Map<String, bool> _isUpdatingStatus = {};

  bool _looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10;
  }

  Future<String> _resolveReceiverPhone(DocumentDelivery delivery) async {
    final receiver = delivery.receiverContact.trim();
    if (_looksLikePhone(receiver)) {
      return receiver;
    }
    throw Exception('Receiver phone number is missing or invalid.');
  }

  Future<String> _resolveSenderPhone(DocumentDelivery delivery) async {
    final senderFromDelivery = delivery.senderContact.trim();
    if (_looksLikePhone(senderFromDelivery)) {
      return senderFromDelivery;
    }

    if (delivery.userId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(delivery.userId)
          .get();
      final phone = (userDoc.data()?['phone'] as String? ?? '').trim();
      if (_looksLikePhone(phone)) {
        return phone;
      }
    }

    throw Exception('Sender phone number is missing or invalid.');
  }

  Future<void> _notifyReceiver(DocumentDelivery delivery) async {
    setState(() => _isNotifying[delivery.id] = true);

    PhilSmsResult result;
    String resolvedPhone = delivery.receiverContact;

    try {
      resolvedPhone = await _resolveReceiverPhone(delivery);
      final message =
          'GODTRASCO: Hi ${delivery.receiverName}, your document is ready for claiming/delivery. Ref: ${delivery.id.substring(0, delivery.id.length.clamp(0, 8)).toUpperCase()}.';

      result = await _smsService.sendSms(
        recipient: resolvedPhone,
        message: message,
      );
    } catch (e) {
      result = PhilSmsResult(success: false, message: e.toString());
    }

    await _deliveryService.addAuditLog(
      deliveryId: delivery.id,
      action: 'notify_receiver',
      success: result.success,
      message: result.message,
      metadata: {
        'to': _smsService.normalizePhone(resolvedPhone),
      },
    );

    if (!mounted) return;

    setState(() => _isNotifying[delivery.id] = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Receiver notified via SMS.'
              : 'Failed to notify receiver: ${result.message}',
        ),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _openCompleteDeliveryDialog(DocumentDelivery delivery) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CompleteDeliveryDialog(
        delivery: delivery,
        deliveryService: _deliveryService,
        smsService: _smsService,
        resolveSenderPhone: _resolveSenderPhone,
      ),
    );
  }

  Color _statusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return const Color(0xFF2196F3);
      case DeliveryStatus.arrived:
        return const Color(0xFF00A3A3);
      case DeliveryStatus.delivered:
        return const Color(0xFF4CAF50);
      case DeliveryStatus.cancelled:
        return Colors.grey;
    }
  }

  Future<void> _markArrived(DocumentDelivery delivery) async {
    setState(() => _isUpdatingStatus[delivery.id] = true);

    try {
      await _deliveryService.updateDeliveryStatus(
        delivery.id,
        DeliveryStatus.arrived,
      );

      await _deliveryService.addAuditLog(
        deliveryId: delivery.id,
        action: 'mark_arrived',
        success: true,
        message: 'Driver marked delivery as arrived.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated to Arrived.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isUpdatingStatus[delivery.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final uid = authProvider.currentUser?.uid;

    return StreamBuilder<List<DocumentDelivery>>(
      stream: _deliveryService.streamDeliveriesForVan(widget.vanPlateNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load document deliveries: ${snapshot.error}'),
          );
        }

        final deliveries = (snapshot.data ?? [])
            .where((d) => d.status != DeliveryStatus.cancelled)
            .toList();

        if (deliveries.isEmpty) {
          return const Center(
            child: Text('No document delivery transactions found.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: deliveries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final d = deliveries[index];
            final isDelivered = d.status == DeliveryStatus.delivered;
            final isArrived = d.status == DeliveryStatus.arrived;
            final paymentPaid = d.paymentStatus == 'paid';
            final isNotifyLoading = _isNotifying[d.id] == true;
            final isUpdatingStatus = _isUpdatingStatus[d.id] == true;
            final canAct = isArrived && !isDelivered;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, color: Color(0xFF2196F3)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ref: ${d.id.substring(0, d.id.length.clamp(0, 8)).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(d.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusColor(d.status).withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          d.status.label,
                          style: TextStyle(
                            color: _statusColor(d.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Sender: ${d.senderName} (${d.senderContact})'),
                  Text('Receiver: ${d.receiverName} (${d.receiverContact})'),
                  Text('Route: ${d.origin} → ${d.destination}'),
                  Text('Payment: ${d.paymentMethod} • ₱${d.paymentAmount.toStringAsFixed(2)}'),
                  Row(
                    children: [
                      Icon(
                        paymentPaid ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: paymentPaid ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentPaid ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          fontSize: 12,
                          color: paymentPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (d.claimedByName != null && d.claimedByName!.isNotEmpty)
                    Text('Claimed by: ${d.claimedByName}'),
                  const SizedBox(height: 10),
                  if (!isDelivered)
                    Column(
                      children: [
                        if (!isArrived)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isUpdatingStatus ? null : () => _markArrived(d),
                              icon: isUpdatingStatus
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.place_outlined),
                              label: const Text('Mark Arrived'),
                            ),
                          ),
                        if (!isArrived) const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: (!canAct || isNotifyLoading)
                                    ? null
                                    : () => _notifyReceiver(d),
                                icon: isNotifyLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.sms),
                                label: const Text('Notify Receiver'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: canAct ? () => _openCompleteDeliveryDialog(d) : null,
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Complete Delivery'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(
                      'Completed by driver ${uid != null ? '(user: $uid)' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CompleteDeliveryDialog extends StatefulWidget {
  final DocumentDelivery delivery;
  final DocumentDeliveryService deliveryService;
  final PhilSmsService smsService;
  final Future<String> Function(DocumentDelivery) resolveSenderPhone;

  const _CompleteDeliveryDialog({
    required this.delivery,
    required this.deliveryService,
    required this.smsService,
    required this.resolveSenderPhone,
  });

  @override
  State<_CompleteDeliveryDialog> createState() => _CompleteDeliveryDialogState();
}

class _CompleteDeliveryDialogState extends State<_CompleteDeliveryDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _claimedByCtrl;
  final TextEditingController _relationshipCtrl = TextEditingController();
  String _receiverType = 'Receiver';
  String _relationshipChoice = '';
  XFile? _receiptFile;
  Uint8List? _receiptBytes;
  String? _receiptFileName;
  bool _isSubmitting = false;
  bool _isCapturing = false;

  static const List<String> _relationshipOptions = [
    'Spouse',
    'Parent',
    'Sibling',
    'Child',
    'Relative',
    'Friend',
    'Staff',
    'Authorized Representative',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _claimedByCtrl = TextEditingController(text: widget.delivery.receiverName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  @override
  void dispose() {
    _claimedByCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List> _compressForFirestore(Uint8List bytes) async {
    const maxBytes = 650 * 1024;
    if (bytes.length <= maxBytes) return bytes;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unable to compress the photo.');
    }

    const targetWidths = [1280, 1024, 800, 640];
    for (final width in targetWidths) {
      final resized = decoded.width > width
          ? img.copyResize(decoded, width: width)
          : decoded;

      int quality = 85;
      while (quality >= 40) {
        final encoded = img.encodeJpg(resized, quality: quality);
        final compressed = Uint8List.fromList(encoded);
        if (compressed.length <= maxBytes) {
          return compressed;
        }
        quality -= 10;
      }
    }

    throw Exception('Photo too large. Try retaking closer.');
  }

  Future<void> _openCamera() async {
    if (_isCapturing || _isSubmitting) return;

    setState(() => _isCapturing = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null) {
        if (!mounted) return;
        setState(() => _isCapturing = false);
        return;
      }

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      } else if (image.path.isNotEmpty) {
        try {
          bytes = await File(image.path).readAsBytes();
        } catch (_) {
          bytes = await image.readAsBytes();
        }
      } else {
        bytes = await image.readAsBytes();
      }

      if (!mounted) return;
      setState(() {
        _receiptFile = image;
        _receiptFileName = image.name.isEmpty
            ? 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : image.name;
        _receiptBytes = bytes?.isEmpty == true ? null : bytes;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Receipt upload failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeDelivery() async {
    final claimedBy = _claimedByCtrl.text.trim();
    final relationshipOther = _relationshipCtrl.text.trim();
    final relationshipChoice = _relationshipChoice.trim();

    if (claimedBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter who received the document.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? relationshipLabel;
    if (_receiverType == 'Others') {
      if (relationshipChoice.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select relationship.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (relationshipChoice == 'Others' && relationshipOther.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please specify relationship.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      relationshipLabel =
          relationshipChoice == 'Others' ? relationshipOther : relationshipChoice;
    }

    final hasCapturedFile = _receiptFile?.path.isNotEmpty == true;
    final hasBytes = _receiptBytes != null && _receiptBytes!.isNotEmpty;
    if ((!hasCapturedFile && !hasBytes) || _receiptFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof of receipt photo is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Uint8List? uploadBytes = _receiptBytes;
      if ((uploadBytes == null || uploadBytes.isEmpty) &&
          _receiptFile?.path.isNotEmpty == true &&
          !kIsWeb) {
        uploadBytes = await File(_receiptFile!.path).readAsBytes();
      }

      if (uploadBytes == null || uploadBytes.isEmpty) {
        throw Exception('Unable to read the captured photo.');
      }

      uploadBytes = await _compressForFirestore(uploadBytes);

      await widget.deliveryService.completeDelivery(
        deliveryId: widget.delivery.id,
        receiverType: _receiverType,
        specifyRelationship: relationshipLabel,
        claimedByName: claimedBy,
        proofOfReceiptBase64: base64Encode(uploadBytes),
        proofOfReceiptFileName: _receiptFileName!,
      );

      await widget.deliveryService.addAuditLog(
        deliveryId: widget.delivery.id,
        action: 'complete_delivery',
        success: true,
        message: 'Delivery marked as completed by driver.',
        metadata: {
          'receiverType': _receiverType,
          'claimedByName': claimedBy,
          'relationship': relationshipLabel,
        },
      );

      final senderMessage = _receiverType == 'Receiver'
          ? 'Your document has been successfully received by $claimedBy.'
          : 'Your document has been successfully received by $claimedBy ($relationshipLabel).';

      final senderPhone = await widget.resolveSenderPhone(widget.delivery);

      final senderSmsResult = await widget.smsService.sendSms(
        recipient: senderPhone,
        message: senderMessage,
      );

      await widget.deliveryService.addAuditLog(
        deliveryId: widget.delivery.id,
        action: 'notify_sender_delivery_completed',
        success: senderSmsResult.success,
        message: senderSmsResult.message,
        metadata: {
          'to': widget.smsService.normalizePhone(senderPhone),
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            senderSmsResult.success
                ? 'Delivery completed and sender notified.'
                : 'Delivery completed, but sender SMS failed: ${senderSmsResult.message}',
          ),
          backgroundColor:
              senderSmsResult.success ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      await widget.deliveryService.addAuditLog(
        deliveryId: widget.delivery.id,
        action: 'complete_delivery',
        success: false,
        message: e.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? previewProvider =
        (!kIsWeb && _receiptFile?.path.isNotEmpty == true)
            ? FileImage(File(_receiptFile!.path))
            : (_receiptBytes != null && _receiptBytes!.isNotEmpty)
                ? MemoryImage(_receiptBytes!)
                : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: Color(0xFF2196F3)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Complete Delivery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Capture proof of receipt before finishing.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isCapturing
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _isCapturing
                              ? const Color(0xFFFFCC80)
                              : const Color(0xFFA5D6A7),
                        ),
                      ),
                      child: Text(
                        _isCapturing
                            ? 'Opening camera...'
                            : (_receiptFile == null
                                ? 'Waiting for photo'
                                : 'Photo ready'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isCapturing
                              ? const Color(0xFFF57C00)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    if (_receiptFileName != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _receiptFileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: previewProvider == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera,
                                  size: 32, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                'No photo captured',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use the camera to capture proof.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image(
                              key: ValueKey(_receiptFileName ?? 'receipt'),
                              image: previewProvider,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text('Preview unavailable'),
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _claimedByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Claimed By',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _receiverType,
                  decoration: const InputDecoration(
                    labelText: 'Receiver Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Receiver', child: Text('Receiver')),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _receiverType = v);
                        },
                ),
                if (_receiverType == 'Others') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _relationshipChoice.isEmpty ? null : _relationshipChoice,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      border: OutlineInputBorder(),
                    ),
                    items: _relationshipOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _relationshipChoice = value;
                              if (value != 'Others') {
                                _relationshipCtrl.clear();
                              }
                            });
                          },
                  ),
                  if (_relationshipChoice == 'Others') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _relationshipCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Specify Relationship',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isSubmitting || _isCapturing)
                            ? null
                            : _openCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          _receiptFile == null
                              ? 'Open Camera'
                              : 'Retake Photo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _completeDelivery,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isSubmitting
                            ? 'Processing...'
                            : 'Complete'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
