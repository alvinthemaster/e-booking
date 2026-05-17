import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/document_delivery_model.dart';
import '../providers/seat_provider.dart';
import '../providers/payment_provider.dart';
import '../services/document_delivery_service.dart';
import '../widgets/van_seat_layout.dart';
import '../widgets/bus_seat_layout.dart';
import 'delivery_eticket_screen.dart';

/// Screen that lets the user submit a Document Delivery request.
///
/// It re-uses the existing seat map widgets in read-only mode (no seat
/// selection is allowed) and displays a document icon near the driver
/// area to indicate where the document cargo will be placed.
///
/// This screen does NOT touch seat availability, the bookings collection,
/// or any existing booking logic.
class DocumentDeliveryScreen extends StatefulWidget {
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final String vehicleType;
  final String? vanPlateNumber;
  final String? vanDriverName;

  const DocumentDeliveryScreen({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    this.vehicleType = 'van',
    this.vanPlateNumber,
    this.vanDriverName,
  });

  @override
  State<DocumentDeliveryScreen> createState() => _DocumentDeliveryScreenState();
}

class _DocumentDeliveryScreenState extends State<DocumentDeliveryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _senderNameCtrl = TextEditingController();
  final TextEditingController _senderContactCtrl = TextEditingController();
  final TextEditingController _receiverNameCtrl = TextEditingController();
  final TextEditingController _receiverContactCtrl = TextEditingController();
  final TextEditingController _otherNoteCtrl = TextEditingController();

  DocumentType _selectedDocType = DocumentType.envelope;
  String _selectedPaymentMethod = 'Physical Payment';
  static const double _deliveryFee = 100.0;
  static const double _bookingFee = 15.0;
  bool _isSubmitting = false;
  bool _seatsInitialized = false;
  Uint8List? _proofOfPaymentBytes;
  String? _proofOfPaymentFileName;

  final DocumentDeliveryService _deliveryService = DocumentDeliveryService();

  bool get _isGcashPayment => _selectedPaymentMethod == 'GCash';
  double get _effectiveBookingFee => _isGcashPayment ? _bookingFee : 0.0;
  double get _totalPayment => _deliveryFee + _effectiveBookingFee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSeats();
      _prefillSenderInfo();
    });
  }

  Future<void> _prefillSenderInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? senderName = user.displayName?.trim();
      String? senderPhone = user.phoneNumber?.trim();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();
      senderName = (senderName?.isNotEmpty == true)
          ? senderName
          : (data?['name'] as String?)?.trim();
      senderPhone = (senderPhone?.isNotEmpty == true)
          ? senderPhone
          : (data?['phone'] as String?)?.trim();

      if (!mounted) return;

      if (_senderNameCtrl.text.trim().isEmpty &&
          senderName != null &&
          senderName.isNotEmpty) {
        _senderNameCtrl.text = senderName;
      }

      if (_senderContactCtrl.text.trim().isEmpty &&
          senderPhone != null &&
          senderPhone.isNotEmpty) {
        _senderContactCtrl.text = senderPhone;
      }
    } catch (_) {
      // Non-blocking: keep form editable even if profile prefill is unavailable.
    }
  }

  Future<void> _pickProofOfPayment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Unable to read the selected file');
      }

      const maxBytes = 600 * 1024;
      if (bytes.length > maxBytes) {
        throw Exception('File is too large. Maximum is 600KB for Spark-safe upload.');
      }

      setState(() {
        _proofOfPaymentBytes = bytes;
        _proofOfPaymentFileName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload proof: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadGcashQr() async {
    try {
      final qrBytes = (await rootBundle.load('assets/images/gcash_qr.png'))
          .buffer
          .asUint8List();
      final qrImage = pw.MemoryImage(qrBytes);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'GCash Payment QR',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Image(
                  qrImage,
                  width: 220,
                  height: 220,
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Scan this QR in your GCash app to pay.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        name: 'gcash_qr_payment.pdf',
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download QR: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initSeats() async {
    // Initialize the seat layout in read-only mode (just to show the map)
    await Provider.of<SeatProvider>(context, listen: false).initializeSeats(
      routeId: widget.routeId,
      vehicleType: widget.vehicleType,
    );
    if (mounted) {
      setState(() => _seatsInitialized = true);
    }
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderContactCtrl.dispose();
    _receiverNameCtrl.dispose();
    _receiverContactCtrl.dispose();
    _otherNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String paymentStatus = 'pending';

      String? proofOfPaymentBase64;

      // GCash payment requires proof and digital payment simulation
      if (_isGcashPayment) {
        if (_proofOfPaymentBytes == null || _proofOfPaymentFileName == null) {
          throw Exception('Please upload proof of payment before continuing.');
        }
        proofOfPaymentBase64 = base64Encode(_proofOfPaymentBytes!);

        final paymentProvider =
            Provider.of<PaymentProvider>(context, listen: false)
              ..resetPaymentStatus();

        final success = await paymentProvider.processPayment(
          bookingId: 'DOC${DateTime.now().millisecondsSinceEpoch}',
          amount: _totalPayment,
          method: _selectedPaymentMethod,
        );

        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  paymentProvider.errorMessage ?? 'Payment failed. Try again.'),
              backgroundColor: Colors.red,
            ));
          }
          return;
        }
        paymentStatus = 'paid';
      }

      final delivery = DocumentDelivery(
        id: '',
        userId: '',
        routeId: widget.routeId,
        routeName: widget.routeName,
        origin: widget.origin,
        destination: widget.destination,
        senderName: _senderNameCtrl.text.trim(),
        senderContact: _senderContactCtrl.text.trim(),
        receiverName: _receiverNameCtrl.text.trim(),
        receiverContact: _receiverContactCtrl.text.trim(),
        documentType: _selectedDocType,
        documentTypeNote: _selectedDocType == DocumentType.other
            ? _otherNoteCtrl.text.trim()
            : null,
        createdAt: DateTime.now(),
        paymentMethod: _selectedPaymentMethod,
        deliveryFee: _deliveryFee,
        bookingFee: _effectiveBookingFee,
        paymentAmount: _totalPayment,
        paymentStatus: paymentStatus,
        proofOfPaymentBase64: proofOfPaymentBase64,
        proofOfPaymentFileName: _proofOfPaymentFileName,
        vanPlateNumber: widget.vanPlateNumber,
        vanDriverName: widget.vanDriverName,
      );

      final deliveryId = await _deliveryService.createDelivery(delivery);

      // Fetch the saved delivery with its generated ID
      final savedDelivery = DocumentDelivery(
        id: deliveryId,
        userId: delivery.userId,
        routeId: delivery.routeId,
        routeName: delivery.routeName,
        origin: delivery.origin,
        destination: delivery.destination,
        senderName: delivery.senderName,
        senderContact: delivery.senderContact,
        receiverName: delivery.receiverName,
        receiverContact: delivery.receiverContact,
        documentType: delivery.documentType,
        documentTypeNote: delivery.documentTypeNote,
        createdAt: delivery.createdAt,
        paymentMethod: delivery.paymentMethod,
        deliveryFee: delivery.deliveryFee,
        bookingFee: delivery.bookingFee,
        paymentAmount: delivery.paymentAmount,
        paymentStatus: delivery.paymentStatus,
        proofOfPaymentBase64: delivery.proofOfPaymentBase64,
        proofOfPaymentFileName: delivery.proofOfPaymentFileName,
        vanPlateNumber: delivery.vanPlateNumber,
        vanDriverName: delivery.vanDriverName,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DeliveryETicketScreen(delivery: savedDelivery),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Document Delivery'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2196F3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _seatsInitialized
          ? _buildBody()
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info Banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your document will be placed with the driver. '
                    'No passenger seat is reserved for document delivery.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Route Summary ────────────────────────────────────────────────
          _buildSectionHeader(Icons.route, 'Trip Details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTripPoint('From', widget.origin),
                ),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
                Expanded(
                  child: _buildTripPoint('To', widget.destination,
                      crossAxisAlignment: CrossAxisAlignment.end),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Seat Map (read-only, document icon shown) ────────────────────
          _buildSectionHeader(Icons.event_seat, 'Vehicle Layout'),
          const SizedBox(height: 4),
          Text(
            'Document cargo position is indicated by the 📄 icon near the driver.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Consumer<SeatProvider>(
              builder: (context, seatProvider, _) {
                // No-op tap handlers — document delivery never selects seats
                void noOp(_, __) {}

                if (seatProvider.vehicleType == 'bus') {
                  return BusSeatLayout(
                    seatProvider: seatProvider,
                    onSeatTap: noOp,
                    onSeatLongPress: noOp,
                    showDocumentIcon: true,
                  );
                }
                return VanSeatLayout(
                  seatProvider: seatProvider,
                  onSeatTap: noOp,
                  onSeatLongPress: noOp,
                  showDocumentIcon: true,
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          // Legend row
          Row(
            children: [
              _buildLegendChip(Colors.grey[200]!, 'Available'),
              const SizedBox(width: 8),
              _buildLegendChip(Colors.red[300]!, 'Reserved'),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.description,
                      color: Color(0xFF2196F3), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Document cargo',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Delivery Form ────────────────────────────────────────────────
          _buildSectionHeader(Icons.description, 'Delivery Details'),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Sender Name
                _buildFormCard(children: [
                  _buildLabel('Sender Information'),
                  const SizedBox(height: 6),
                  Text(
                    'Auto-filled from your account. You can still edit before submitting.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senderNameCtrl,
                    label: 'Sender Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _senderContactCtrl,
                    label: 'Sender Contact Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ]),

                const SizedBox(height: 12),

                // Receiver
                _buildFormCard(children: [
                  _buildLabel('Receiver Information'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _receiverNameCtrl,
                    label: 'Receiver Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _receiverContactCtrl,
                    label: 'Receiver Contact Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ]),

                const SizedBox(height: 12),

                // Document Type
                _buildFormCard(children: [
                  _buildLabel('Document Type'),
                  const SizedBox(height: 12),
                  _buildDocTypeDropdown(),
                  if (_selectedDocType == DocumentType.other) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _otherNoteCtrl,
                      label: 'Please describe the document',
                      icon: Icons.notes_outlined,
                      validator: (v) => (_selectedDocType == DocumentType.other &&
                              (v == null || v.trim().isEmpty))
                          ? 'Please describe the document'
                          : null,
                    ),
                  ],
                ]),

                const SizedBox(height: 28),

                // ── Payment ──────────────────────────────────────────────
                _buildSectionHeader(Icons.payment, 'Payment'),
                const SizedBox(height: 12),
                _buildFormCard(children: [
                  // Fee breakdown
                  _feeRow('Delivery Fee', _deliveryFee),
                  const SizedBox(height: 8),
                  _feeRow(
                    _isGcashPayment ? 'Booking Fee' : 'Booking Fee (Excluded)',
                    _effectiveBookingFee,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Text('\u20b1',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3))),
                          Text(
                            _totalPayment.toStringAsFixed(2),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _buildLabel('Payment Method'),
                  const SizedBox(height: 10),
                  ...['GCash', 'Physical Payment'].map((method) {
                    final isSelected = _selectedPaymentMethod == method;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedPaymentMethod = method;
                        if (!_isGcashPayment) {
                          _proofOfPaymentBytes = null;
                          _proofOfPaymentFileName = null;
                        }
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method == 'GCash'
                                  ? Icons.account_balance_wallet
                                  : Icons.payments,
                              color: isSelected
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                method,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: isSelected
                                      ? const Color(0xFF2196F3)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Radio<String>(
                              value: method,
                              groupValue: _selectedPaymentMethod,
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedPaymentMethod = v;
                                    if (!_isGcashPayment) {
                                      _proofOfPaymentBytes = null;
                                      _proofOfPaymentFileName = null;
                                    }
                                  });
                                }
                              },
                              activeColor: const Color(0xFF2196F3),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_isGcashPayment) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'GCash: scan the QR, complete payment, then upload your proof of payment.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/gcash_qr.png',
                              width: 170,
                              height: 170,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 170,
                                  height: 170,
                                  color: Colors.grey[100],
                                  alignment: Alignment.center,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text(
                                      'Missing assets/images/gcash_qr.png',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Use your GCash app to scan and pay',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _downloadGcashQr,
                        icon: const Icon(Icons.download),
                        label: const Text('Download GCash QR'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickProofOfPayment,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _proofOfPaymentFileName == null
                              ? 'Upload Proof of Payment'
                              : 'Change Uploaded Proof',
                        ),
                      ),
                    ),
                    if (_proofOfPaymentFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _proofOfPaymentFileName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (_proofOfPaymentBytes != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _proofOfPaymentBytes!,
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                  if (_selectedPaymentMethod == 'Physical Payment') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pay \u20b1${_deliveryFee.toStringAsFixed(0)} delivery fee to the driver when handing over your document. No booking fee is added for physical payment.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ]),

                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _selectedPaymentMethod == 'Physical Payment'
                                    ? Icons.send_outlined
                                    : Icons.payment,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedPaymentMethod == 'Physical Payment'
                                    ? 'Confirm Delivery Request'
                                    : 'Pay & Confirm Delivery',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _feeRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Row(
          children: [
            Text('\u20b1',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            Text(amount.toStringAsFixed(2),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTripPoint(String label, String value,
      {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF2196F3), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDocTypeDropdown() {
    return DropdownButtonFormField<DocumentType>(
      value: _selectedDocType,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.description_outlined,
            color: Colors.grey[500], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF2196F3), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: DocumentType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(type.label, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedDocType = val);
      },
    );
  }

  Widget _buildLegendChip(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey[400]!),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}
