import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/ticket_service.dart';

class ETicketWidget extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ETicketWidget({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<ETicketWidget> createState() => _ETicketWidgetState();
}

class _ETicketWidgetState extends State<ETicketWidget> {
  final TicketService _ticketService = TicketService();
  String? qrUrl;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _generateQR();
  }

  Future<void> _generateQR() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final url = await _ticketService.generateQrForBooking(widget.bookingId);
      
      setState(() {
        qrUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/godtrasco_logo.png',
                  height: 40,
                  width: 40,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GODTRASCO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'E-Ticket',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.bookingData['bookingStatus']?.toString().toUpperCase() ?? 'CONFIRMED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ticket Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Route Information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookingData['origin'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            'FROM',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.bookingData['destination'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            'TO',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),

                const SizedBox(height: 20),

                // Booking Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Passenger',
                        widget.bookingData['passengerName'] ?? 'Unknown',
                        Icons.person,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Seats',
                        (widget.bookingData['seatNumbers'] as List?)?.join(', ') ?? 'N/A',
                        Icons.event_seat,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Van',
                        widget.bookingData['vanPlateNumber'] ?? 'Unknown',
                        Icons.directions_bus,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Date',
                        widget.bookingData['bookingDate'] != null
                            ? '${widget.bookingData['bookingDate'].toDate().day}/${widget.bookingData['bookingDate'].toDate().month}/${widget.bookingData['bookingDate'].toDate().year}'
                            : 'N/A',
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // QR Code Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Show this QR code to the conductor',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (isLoading)
                        const CircularProgressIndicator()
                      else if (error != null)
                        Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to generate QR code',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _generateQR,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else if (qrUrl != null)
                        QrImageView(
                          data: qrUrl!,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Booking ID
                Text(
                  'Booking ID: ${widget.bookingId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}