import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/document_delivery_model.dart';

/// E-ticket screen shown after a Document Delivery is confirmed and paid.
/// Displays delivery details + a QR code the conductor can scan.
class DeliveryETicketScreen extends StatelessWidget {
  final DocumentDelivery delivery;

  /// Hardcoded fee breakdown (must match document_delivery_screen.dart)
  static const double _deliveryFee = 100.0;
  static const double _bookingFee = 15.0;

  /// Firebase Hosting URL — same base as normal booking QR codes
  static const String _hostingUrl = 'https://e-ticket-2e8d0.web.app';

  const DeliveryETicketScreen({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final shortRef =
        delivery.id.isNotEmpty ? delivery.id.substring(0, 8).toUpperCase() : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Delivery E-Ticket',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 70, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delivery Confirmed!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your document delivery has been registered',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ── Ticket card ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description,
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GODTRASCO',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text('Document Delivery',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text('Ref: $shortRef',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),

                  // Route
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FROM',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(delivery.origin,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              color: Color(0xFF2196F3), size: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('TO',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(delivery.destination,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sender / Receiver
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _infoBlock(
                            title: 'Sender',
                            name: delivery.senderName,
                            contact: delivery.senderContact,
                            align: CrossAxisAlignment.start,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _infoBlock(
                            title: 'Receiver',
                            name: delivery.receiverName,
                            contact: delivery.receiverContact,
                            align: CrossAxisAlignment.end,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Document type + date
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _row(Icons.folder_open, Colors.orange,
                              'Document Type', delivery.documentType.label),
                          if (delivery.documentTypeNote != null &&
                              delivery.documentTypeNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _row(Icons.notes, Colors.orange, 'Note',
                                delivery.documentTypeNote!),
                          ],
                          const SizedBox(height: 8),
                          _row(
                            Icons.access_time,
                            Colors.grey,
                            'Date',
                            DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(delivery.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Payment info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Method',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600])),
                              Row(
                                children: [
                                  Icon(
                                    delivery.paymentMethod == 'GCash'
                                        ? Icons.account_balance_wallet
                                        : Icons.payments,
                                    size: 15,
                                    color: const Color(0xFF2196F3),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(delivery.paymentMethod,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          _feeBreakdownRow('Delivery Fee',
                              '\u20b1${_deliveryFee.toStringAsFixed(2)}'),
                          const SizedBox(height: 6),
                          _feeBreakdownRow('Booking Fee',
                              '\u20b1${_bookingFee.toStringAsFixed(2)}'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Row(
                                children: [
                                  FaIcon(FontAwesomeIcons.pesoSign,
                                      size: 13,
                                      color: const Color(0xFF2196F3)),
                                  Text(
                                    delivery.paymentAmount.toStringAsFixed(2),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2196F3)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dashed divider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    child: SizedBox(
                      height: 1,
                      child: CustomPaint(painter: _DashedLinePainter()),
                    ),
                  ),

                  // QR Code
                  const Text(
                    'Show this QR code to the conductor',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: QrImageView(
                      data: '$_hostingUrl?id=DELIVERY:${delivery.id}',
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shortRef,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Notes ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Important Notes:',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    '• Hand the document directly to the conductor or driver\n'
                    '• Show this QR code to the conductor for scanning\n'
                    '• Ensure the document is properly sealed\n'
                    '• Contact support if your delivery is delayed',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Back to home ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _infoBlock({
    required String title,
    required String name,
    required String contact,
    required CrossAxisAlignment align,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text(contact,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _row(IconData icon, Color iconColor, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text('$label: ',
            style:
                TextStyle(fontSize: 12, color: Colors.grey[600])),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    const dash = 5.0;
    const gap = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
