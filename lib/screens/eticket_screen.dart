import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../models/booking_models.dart';
import '../utils/currency_formatter.dart';

class ETicketScreen extends StatelessWidget {
  final String bookingId;

  const ETicketScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      appBar: AppBar(
        title: const Text('E-Ticket'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareTicket(context),
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return FutureBuilder<Booking?>(
            future: bookingProvider.getBookingById(bookingId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading booking: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final booking = snapshot.data;
              if (booking == null) {
                return const Center(
                  child: Text(
                    'Booking not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Success Animation/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your e-ticket has been generated',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 32),

                    // E-Ticket Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: const DecorationImage(
                                          image: AssetImage('assets/images/godtrasco_logo.png'),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GODTRASCO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Van Service',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Booking ID: ${booking.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Passenger Info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow(
                                  'Passenger Name',
                                  booking.passengerDetails?['name'] ??
                                      booking.userName,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Email',
                                  booking.passengerDetails?['email'] ??
                                      booking.userEmail,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Phone',
                                  booking.passengerDetails?['phone'] ?? 'N/A',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  'Booking Date',
                                  DateFormat(
                                    'MMM dd, yyyy - hh:mm a',
                                  ).format(booking.bookingDate),
                                ),

                                const SizedBox(height: 24),

                                // Route Info
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'FROM',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Glan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF2196F3),
                                      ),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'TO',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Gensan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Seat Info
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2196F3,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SEAT INFORMATION',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF2196F3),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Seats: ${booking.seatIds.join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2196F3),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: ${CurrencyFormatter.formatPesoWithDecimals(booking.totalAmount)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (booking.discountAmount > 0)
                                        Text(
                                          'Discount: ${CurrencyFormatter.formatDiscount(booking.discountAmount)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (booking.childCount > 0 || booking.petCount > 0 || booking.baggageCount > 0) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add-ons:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (booking.childCount > 0)
                                          Text(
                                            '  • Child: ${booking.childCount}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        if (booking.petCount > 0)
                                          Text(
                                            '  • Pet: ${booking.petCount}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        if (booking.baggageCount > 0)
                                          Text(
                                            '  • Baggage: ${booking.baggageCount}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Van Information
                                if (booking.vanPlateNumber != null || booking.vanDriverName != null || booking.vanDriverContact != null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'VAN INFORMATION',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (booking.vanPlateNumber != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.local_taxi,
                                                size: 16,
                                                color: Color(0xFF2196F3),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Plate Number: ${booking.vanPlateNumber}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (booking.vanPlateNumber != null && (booking.vanDriverName != null || booking.vanDriverContact != null))
                                          const SizedBox(height: 4),
                                        if (booking.vanDriverName != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Color(0xFF2196F3),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Driver: ${booking.vanDriverName}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (booking.vanDriverName != null && booking.vanDriverContact != null)
                                          const SizedBox(height: 4),
                                        if (booking.vanDriverContact != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 16,
                                                color: Color(0xFF2196F3),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Contact: ${booking.vanDriverContact}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),

                                if (booking.proofOfPaymentUrl != null ||
                                  booking.proofOfPaymentBase64 != null) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PROOF OF PAYMENT',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: booking.proofOfPaymentUrl != null
                                              ? Image.network(
                                                  booking.proofOfPaymentUrl!,
                                                  height: 200,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    final bytes = _decodeBase64Image(
                                                      booking.proofOfPaymentBase64,
                                                    );
                                                    if (bytes == null) {
                                                      return Container(
                                                        height: 120,
                                                        width: double.infinity,
                                                        color: Colors.grey[200],
                                                        alignment: Alignment.center,
                                                        child: const Text(
                                                          'Unable to load proof image',
                                                        ),
                                                      );
                                                    }
                                                    return Image.memory(
                                                      bytes,
                                                      height: 200,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                              : Builder(
                                                  builder: (context) {
                                                    final bytes = _decodeBase64Image(
                                                      booking.proofOfPaymentBase64,
                                                    );
                                                    if (bytes == null) {
                                                      return Container(
                                                        height: 120,
                                                        width: double.infinity,
                                                        color: Colors.grey[200],
                                                        alignment: Alignment.center,
                                                        child: const Text(
                                                          'No valid proof image found',
                                                        ),
                                                      );
                                                    }
                                                    return Image.memory(
                                                      bytes,
                                                      height: 200,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                ),
                                        ),
                                        if (booking.proofOfPaymentFileName != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            booking.proofOfPaymentFileName!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Dashed Divider
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: CustomPaint(painter: DashedLinePainter()),
                          ),

                          // QR Code Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text(
                                  'Show this QR code to the conductor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),

                                // QR Code
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: booking.qrCodeData ?? booking.id,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  booking.qrCodeData ?? booking.id,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Important Notes
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Notes:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Please arrive 15 minutes before departure\n'
                            '• Bring a valid ID for verification\n'
                            '• Keep this e-ticket on your phone\n'
                            '• Contact support if you need assistance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _downloadTicket(context, booking),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Download'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2196F3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home),
                                SizedBox(width: 8),
                                Text('Back to Home'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Uint8List? _decodeBase64Image(String? base64Data) {
    if (base64Data == null || base64Data.isEmpty) return null;

    try {
      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }

  Future<pw.Document> _buildTicketPdf(Booking booking) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'GODTRASCO E-Ticket',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Booking ID: ${booking.id}'),
          pw.Text('Passenger: ${booking.passengerDetails?['name'] ?? booking.userName}'),
          pw.Text('Email: ${booking.passengerDetails?['email'] ?? booking.userEmail}'),
          pw.Text('Phone: ${booking.passengerDetails?['phone'] ?? 'N/A'}'),
          pw.Text('Route: ${booking.origin} to ${booking.destination}'),
          pw.Text('Seats: ${booking.seatIds.join(', ')}'),
          pw.Text('Total: ${CurrencyFormatter.formatPesoWithDecimals(booking.totalAmount)}'),
          pw.Text('Payment Method: ${booking.paymentMethod}'),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: booking.qrCodeData ?? booking.id,
              width: 180,
              height: 180,
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  Future<void> _shareTicket(BuildContext context) async {
    try {
      final booking = await Provider.of<BookingProvider>(
        context,
        listen: false,
      ).getBookingById(bookingId);

      if (booking == null) {
        throw Exception('Booking not found');
      }

      final pdf = await _buildTicketPdf(booking);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'eticket_${booking.id}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to share ticket: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadTicket(BuildContext context, Booking booking) async {
    try {
      final pdf = await _buildTicketPdf(booking);
      await Printing.layoutPdf(
        name: 'eticket_${booking.id}.pdf',
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to download ticket: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
