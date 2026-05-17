import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking_models.dart';
import '../providers/payment_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/seat_provider.dart';
import '../services/email_service.dart';
import 'eticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Seat> selectedSeats;
  final double totalAmount;
  final double discountAmount;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final int childCount;
  final int petCount;
  final int baggageCount;
  final double addOnsAmount;
  final String? proofOfTripBase64;
  final String? proofOfTripFileName;

  const PaymentScreen({
    super.key,
    required this.selectedSeats,
    required this.totalAmount,
    required this.discountAmount,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    this.childCount = 0,
    this.petCount = 0,
    this.baggageCount = 0,
    this.addOnsAmount = 0.0,
    this.proofOfTripBase64,
    this.proofOfTripFileName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Uint8List? _proofOfPaymentBytes;
  String? _proofOfPaymentFileName;
  bool _isUploadingProof = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentProvider>(context, listen: false).resetPaymentStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Payment'),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
              onPressed: paymentProvider.isProcessing
                  ? null
                  : () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: const Color(0xFF2196F3),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Payment Summary',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildSummaryRow(
                              'Passenger:',
                              widget.passengerName,
                            ),
                            _buildSummaryRow(
                              'Seats:',
                              widget.selectedSeats.map((s) => s.id).join(', '),
                            ),
                            _buildSummaryRow('Email:', widget.passengerEmail),
                            const Divider(height: 20),
                            _buildSummaryRowWithPeso(
                              'Fare Subtotal:',
                              (widget.totalAmount - 15.0).toStringAsFixed(2),
                            ),
                            if (widget.discountAmount > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Discount Applied:',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          '-₱',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          widget.discountAmount.toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Add-ons section
                            if (widget.baggageCount > 0) ...[
                              if (widget.baggageCount > 0)
                                _buildSummaryRowWithPeso(
                                  'Baggage (${widget.baggageCount}):',
                                  (widget.baggageCount * 150).toStringAsFixed(2),
                                ),
                              _buildSummaryRowWithPeso(
                                'Add-ons Total:',
                                widget.addOnsAmount.toStringAsFixed(2),
                              ),
                            ],
                            
                            _buildSummaryRowWithPeso(
                              'Booking Fee:',
                              '15.00',
                            ),
                            const Divider(height: 20),
                            _buildSummaryRowWithPeso(
                              'Total Amount:',
                              (widget.totalAmount + widget.addOnsAmount).toStringAsFixed(2),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Methods
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payment,
                                  color: const Color(0xFF2196F3),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Choose Payment Method',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            ...paymentProvider.availablePaymentMethods.map((
                              method,
                            ) {
                              return _buildPaymentMethodTile(
                                method,
                                paymentProvider,
                              );
                            }),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'GCash only: scan the QR code below, complete payment, then upload your proof of payment.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // GCash QR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GCash QR Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
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
                                      width: 190,
                                      height: 190,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 190,
                                          height: 190,
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
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Use your GCash app to scan and pay',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _downloadGcashQr,
                                icon: const Icon(Icons.download),
                                label: const Text('Download GCash QR'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Proof of payment upload
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Proof of Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload your payment screenshot (JPG/PNG, max 4MB).',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: paymentProvider.isProcessing || _isUploadingProof
                                    ? null
                                    : _pickProofOfPayment,
                                icon: const Icon(Icons.upload_file),
                                label: Text(
                                  _proofOfPaymentFileName == null
                                      ? 'Upload Proof of Payment'
                                      : 'Change Uploaded Proof',
                                ),
                              ),
                            ),
                            if (_proofOfPaymentFileName != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _proofOfPaymentFileName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (_proofOfPaymentBytes != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _proofOfPaymentBytes!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Status
                      if (paymentProvider.currentStatus !=
                              PaymentStatus.pending ||
                          paymentProvider.errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: paymentProvider
                                .getPaymentStatusColor()
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: paymentProvider
                                  .getPaymentStatusColor()
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getStatusIcon(paymentProvider.currentStatus),
                                size: 48,
                                color: paymentProvider.getPaymentStatusColor(),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                paymentProvider.getPaymentStatusMessage(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: paymentProvider
                                      .getPaymentStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Payment Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                          paymentProvider.isProcessing ||
                            _isUploadingProof ||
                                paymentProvider.currentStatus ==
                                    PaymentStatus.paid
                            ? null
                            : () => _processPayment(paymentProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              paymentProvider.currentStatus ==
                                  PaymentStatus.paid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: paymentProvider.isProcessing || _isUploadingProof
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Processing Payment...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : paymentProvider.currentStatus ==
                                  PaymentStatus.paid
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'View E-Ticket',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPaymentMethodIcon(
                                      paymentProvider.selectedMethod,
                                    ),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Pay with ${paymentProvider.selectedMethod}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? const Color(0xFF2196F3) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowWithPeso(
    String label,
    String amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.pesoSign,
                size: isTotal ? 14 : 12,
                color: isTotal ? const Color(0xFF2196F3) : null,
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                  color: isTotal ? const Color(0xFF2196F3) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String method,
    PaymentProvider paymentProvider,
  ) {
    final isSelected = paymentProvider.selectedMethod == method;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          _getPaymentMethodIcon(method),
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600],
          size: 28,
        ),
        title: Text(
          method,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
          ),
        ),
        trailing: Radio<String>(
          value: method,
          groupValue: paymentProvider.selectedMethod,
          onChanged: (value) {
            if (value != null) {
              paymentProvider.setPaymentMethod(value);
            }
          },
          activeColor: const Color(0xFF2196F3),
        ),
        onTap: () {
          paymentProvider.setPaymentMethod(method);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
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

      // Firestore document limit is 1MB; keep image safely below when base64 encoded.
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

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'GCash':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  Future<void> _processPayment(PaymentProvider paymentProvider) async {
    try {
      // Add validation before processing
      if (widget.selectedSeats.isEmpty) {
        throw Exception('No seats selected');
      }

      if (_proofOfPaymentBytes == null || _proofOfPaymentFileName == null) {
        throw Exception('Please upload proof of payment before continuing.');
      }

      final proofDraftId = 'UVE${DateTime.now().millisecondsSinceEpoch}';
      final proofOfPaymentBase64 = base64Encode(_proofOfPaymentBytes!);

      final success = await paymentProvider.processPayment(
        bookingId: proofDraftId,
        amount: widget.totalAmount + widget.addOnsAmount,
        method: 'GCash',
      );

      if (success && mounted) {
        // Create booking with better error handling
        final bookingProvider = Provider.of<BookingProvider>(
          context,
          listen: false,
        );
        final seatProvider = Provider.of<SeatProvider>(context, listen: false);

        try {
          final bookingId = await bookingProvider.createBooking(
            routeId: widget.routeId, // Use the route ID passed from seat selection
            routeName: widget.routeName, // Use the route name passed from seat selection
            origin: widget.origin, // Use the origin passed from seat selection
            destination: widget.destination, // Use the destination passed from seat selection
            departureTime: DateTime.now().add(const Duration(hours: 2)),
            seatIds: widget.selectedSeats.map((seat) => seat.id).toList(),
            basePrice: widget.totalAmount - widget.discountAmount - 15.0, // Subtract discount and booking fee from total
            discountAmount: widget.discountAmount,
            totalAmount: widget.totalAmount + widget.addOnsAmount,
            childCount: widget.childCount,
            petCount: widget.petCount,
            baggageCount: widget.baggageCount,
            addOnsAmount: widget.addOnsAmount,
            paymentMethod: paymentProvider.selectedMethod,
            paymentStatus:
                paymentProvider.currentStatus, // Pass the current payment status
            passengerDetails: {
              'name': widget.passengerName,
              'email': widget.passengerEmail,
              'phone': widget.passengerPhone,
              'seats': widget.selectedSeats.map((seat) => {
                'id': seat.id,
                'hasDiscount': seat.hasDiscount,
              }).toList(),
              'regularSeats': widget.selectedSeats.where((s) => !s.hasDiscount).map((s) => s.id).toList(),
              'discountedSeats': widget.selectedSeats.where((s) => s.hasDiscount).map((s) => s.id).toList(),
            },
            proofOfTripBase64: widget.proofOfTripBase64,
            proofOfTripFileName: widget.proofOfTripFileName,
            proofOfPaymentBase64: proofOfPaymentBase64,
            proofOfPaymentFileName: _proofOfPaymentFileName,
          );

          // Reserve seats locally
          await seatProvider.reserveSelectedSeats();
          
          // Trigger immediate refresh of seat availability for all users on this route
          await seatProvider.refreshSeatAvailability(routeId: widget.routeId);

          // Small delay to ensure booking is fully saved
          await Future.delayed(const Duration(milliseconds: 500));

          // Get the created booking to access QR code data
          final createdBooking = await bookingProvider.getBookingById(bookingId);
          
          // Send e-ticket email (don't block navigation if email fails)
          if (createdBooking != null && createdBooking.qrCodeData != null) {
            EmailService.sendETicketEmail(
              booking: createdBooking,
              qrCodeData: createdBooking.qrCodeData!,
            ).then((emailSent) {
              if (mounted) {
                if (emailSent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ E-ticket sent to your email!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  // Email failed (likely running on web)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '📱 E-ticket created successfully!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Email not available on web. Use the mobile app or view your ticket in Booking History.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2196F3),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            }).catchError((error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ E-ticket created but email delivery failed. You can still view your ticket in Booking History.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            });
          }

          // Navigate to e-ticket
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ETicketScreen(bookingId: bookingId),
              ),
            );
          }
        } catch (bookingError) {
          // Handle booking creation errors specifically
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking failed: ${bookingError.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          
          // Reset payment status on booking failure
          paymentProvider.resetPaymentStatus();
        }
      } else if (!success) {
        // Payment failed, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentProvider.errorMessage ?? 'Payment failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('Payment processing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Reset payment status on any error
      paymentProvider.resetPaymentStatus();
    }
  }
}
