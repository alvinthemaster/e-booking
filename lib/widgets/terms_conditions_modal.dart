import 'package:flutter/material.dart';

class TermsConditionsModal extends StatefulWidget {
  final VoidCallback onAccept;

  const TermsConditionsModal({
    super.key,
    required this.onAccept,
  });

  @override
  State<TermsConditionsModal> createState() => _TermsConditionsModalState();
}

class _TermsConditionsModalState extends State<TermsConditionsModal> {
  bool _isAccepted = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // Maximum 85% of screen height

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Booking Agreement',
                      'By proceeding with this booking, you acknowledge and agree to the following terms and conditions:',
                    ),
                    const SizedBox(height: 20),
                    
                    _buildSection(
                      '1. No Refund Policy',
                      'All bookings are final and non-refundable. Once a booking is confirmed and payment is made, no refunds will be issued under any circumstances, including but not limited to:',
                    ),
                    _buildBulletPoint('Cancellation by the passenger'),
                    _buildBulletPoint('Missed departure'),
                    _buildBulletPoint('Changes in travel plans'),
                    _buildBulletPoint('Medical emergencies'),
                    _buildBulletPoint('Weather conditions or other force majeure events'),
                    const SizedBox(height: 20),

                    _buildSection(
                      '2. Booking Confirmation',
                      'Your booking will be confirmed upon successful payment. An e-ticket will be sent to your registered email address within 2 minutes of confirmation.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '3. Seat Reservation',
                      'Seats are reserved on a first-come, first-served basis. Once you select and confirm your seats, they cannot be changed or transferred to another passenger.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '4. Passenger Information',
                      'You must provide accurate and complete information during booking. The passenger name on the e-ticket must match a valid government-issued ID for verification purposes.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '5. Departure Time',
                      'Please arrive at least 15 minutes before the scheduled departure time. Late arrivals may result in forfeiture of your seat without refund.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '6. E-Ticket Validity',
                      'The e-ticket is valid only for the specific date, time, and route indicated. It is non-transferable and cannot be used for any other trip.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '7. Payment',
                      'A ₱15.00 booking fee is added to your fare. All payments must be completed before the booking is confirmed. We accept GCash and cash payments.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '8. Cancellation by Operator',
                      'In the rare event that the operator cancels a trip, passengers will be notified immediately and a full refund will be issued.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '9. Luggage Policy',
                      'Passengers are responsible for their own luggage. The operator is not liable for lost, damaged, or stolen items.',
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      '10. Code of Conduct',
                      'Passengers must behave respectfully and follow the driver\'s instructions. The operator reserves the right to refuse service to passengers who violate safety regulations or exhibit disruptive behavior.',
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'IMPORTANT: All bookings are strictly non-refundable. Please review your booking details carefully before proceeding.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Agreement Checkbox & Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isAccepted = !_isAccepted;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _isAccepted = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms & Conditions, including the No Refund Policy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF2196F3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAccepted
                              ? () {
                                  Navigator.of(context).pop();
                                  widget.onAccept();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF2196F3),
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept & Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
