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

                const SizedBox(height: 16),

                // Payment Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: const Color(0xFF2196F3),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Passenger
                      _buildPaymentInfoRow(
                        'Passenger:',
                        widget.bookingData['passengerDetails'] != null 
                            ? (widget.bookingData['passengerDetails'] as Map<String, dynamic>)['name'] ?? ''
                            : widget.bookingData['userName'] ?? '',
                      ),
                      
                      // Seats
                      _buildPaymentInfoRow(
                        'Seats:',
                        widget.bookingData['seatIds'] != null
                            ? (widget.bookingData['seatIds'] as List).join(', ')
                            : '',
                      ),
                      
                      // Email
                      _buildPaymentInfoRow(
                        'Email:',
                        widget.bookingData['passengerDetails'] != null 
                            ? (widget.bookingData['passengerDetails'] as Map<String, dynamic>)['email'] ?? ''
                            : widget.bookingData['userEmail'] ?? '',
                      ),
                      
                      const Divider(height: 20),
                      
                      // Get seat breakdown
                      ..._buildSeatBreakdown(),
                      
                      // Booking Fee
                      _buildPaymentAmountRow(
                        'Booking Fee:',
                        15.0,
                        isPeso: true,
                      ),
                      
                      const Divider(height: 20),
                      
                      // Total Amount
                      _buildPaymentAmountRow(
                        'Total Amount:',
                        widget.bookingData['totalAmount'] != null
                            ? (widget.bookingData['totalAmount'] as num).toDouble()
                            : 0.0,
                        isPeso: true,
                        isTotal: true,
                        color: const Color(0xFF2196F3),
                      ),
                    ],
                  ),
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

  Widget _buildPaymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAmountRow(
    String label,
    double amount, {
    bool isPeso = false,
    bool isTotal = false,
    Color? color,
  }) {
    final displayColor = color ?? Colors.black87;
    final fontSize = isTotal ? 16.0 : 14.0;
    final fontWeight = isTotal ? FontWeight.bold : FontWeight.normal;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: isTotal ? displayColor : Colors.black87,
              fontWeight: fontWeight,
            ),
          ),
          Text(
            isPeso 
                ? '₱${amount.abs().toStringAsFixed(2)}'
                : amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: fontSize,
              color: displayColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeatBreakdown() {
    final List<Widget> widgets = [];
    final passengerDetails = widget.bookingData['passengerDetails'] as Map<String, dynamic>?;
    
    if (passengerDetails == null) {
      // Fallback: show basic fare subtotal
      widgets.add(_buildPaymentAmountRow(
        'Fare Subtotal:',
        widget.bookingData['basePrice'] != null
            ? (widget.bookingData['basePrice'] as num).toDouble()
            : 0.0,
        isPeso: true,
      ));
      
      if ((widget.bookingData['discountAmount'] ?? 0) > 0) {
        widgets.add(_buildPaymentAmountRow(
          'Discount Applied:',
          -(widget.bookingData['discountAmount'] as num).toDouble(),
          isPeso: true,
          color: Colors.green,
        ));
      }
      
      return widgets;
    }

    final regularSeats = passengerDetails['regularSeats'] as List?;
    final discountedSeats = passengerDetails['discountedSeats'] as List?;
    
    // Regular seats
    if (regularSeats != null && regularSeats.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regular Fare:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${regularSeats.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${(regularSeats.length * 150).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Discounted seats
    if (discountedSeats != null && discountedSeats.isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discounted Fare:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${discountedSeats.join(', ')} (PWD/Senior/Student)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${(discountedSeats.length * 130).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
      
      // Show discount savings
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discount Applied:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '-₱${(discountedSeats.length * 20).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return widgets;
  }
}
