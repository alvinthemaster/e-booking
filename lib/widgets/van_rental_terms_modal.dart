import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class VanRentalTermsModal extends StatefulWidget {
  final double totalAmount;
  final double depositAmount;
  final VoidCallback onAccept;

  const VanRentalTermsModal({
    super.key,
    required this.totalAmount,
    required this.depositAmount,
    required this.onAccept,
  });

  @override
  State<VanRentalTermsModal> createState() => _VanRentalTermsModalState();
}

class _VanRentalTermsModalState extends State<VanRentalTermsModal> {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.88,
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
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Van Rental Agreement',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
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

            // Deposit summary banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border(
                  bottom: BorderSide(color: Colors.amber[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.amber[800]),
                      const SizedBox(width: 6),
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.amber[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Rental Amount',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[700])),
                      Text(
                        CurrencyFormatter.formatPesoWithDecimals(
                            widget.totalAmount),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[600]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 16, color: Colors.amber[900]),
                            const SizedBox(width: 6),
                            Text(
                              'Required Deposit (50%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.formatPesoWithDecimals(
                              widget.depositAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '* Due upon approval of your rental request.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicySection(
                      icon: Icons.shield_outlined,
                      iconColor: Colors.indigo,
                      title: '1. Deposit & Damage Policy',
                      points: [
                        'A deposit equal to 50% of the total rental cost is required prior to or upon approval.',
                        'The deposit will be used to cover any vehicle damages found during the post-rental inspection.',
                        'If damage cost ≤ deposit: the difference will be refunded within 5–7 business days.',
                        'If damage cost > deposit: the renter must pay the remaining balance before the vehicle is released.',
                        'No damage deductions will be made without a documented inspection report.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPolicySection(
                      icon: Icons.local_gas_station_outlined,
                      iconColor: Colors.orange,
                      title: '2. Fuel Policy',
                      points: [
                        'If the vehicle is provided with a full tank, it must be returned with a full tank.',
                        'If the tank is not full upon return, the cost of the fuel shortage will be deducted from the deposit.',
                        'An additional ₱200 service fee may apply for refueling by the company.',
                        'Fuel type must match the vehicle specification; incorrect fueling costs are fully charged to the renter.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPolicySection(
                      icon: Icons.access_time_outlined,
                      iconColor: Colors.teal,
                      title: '3. Rental Period & Extensions',
                      points: [
                        'The rental period is fixed on the dates stated in this request.',
                        'Extensions must be requested at least 6 hours before the scheduled return time.',
                        'Unauthorized late returns will be charged at 1.5× the daily rate per additional day.',
                        'No refund will be given for early returns unless agreed upon in writing.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPolicySection(
                      icon: Icons.car_crash_outlined,
                      iconColor: Colors.red,
                      title: '4. Vehicle Use & Restrictions',
                      points: [
                        'The vehicle may only be operated by the registered renter or a declared driver.',
                        'Sub-renting or lending the vehicle to third parties is strictly prohibited.',
                        'The vehicle must not be used for illegal activities, overloading, or off-road driving.',
                        'Smoking, eating, and bringing pets inside the vehicle require prior written approval.',
                        'Any traffic violations or fines incurred during the rental period are the renter\'s full responsibility.',
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildPolicySection(
                      icon: Icons.cancel_outlined,
                      iconColor: Colors.deepOrange,
                      title: '5. Cancellation Policy',
                      points: [
                        'Cancellations made 48+ hours before the start date: full deposit refund.',
                        'Cancellations made 24–48 hours before: 50% of the deposit is non-refundable.',
                        'Cancellations made less than 24 hours before: the full deposit is forfeited.',
                        'No-shows without prior notice will result in full deposit forfeiture.',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer: checkbox + buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _isAccepted = !_isAccepted),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAccepted,
                              onChanged: (val) => setState(
                                  () => _isAccepted = val ?? false),
                              activeColor: const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms and Conditions, including the deposit and cancellation policies.',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                              fontSize: 15,
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
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Accept & Submit',
                            style: TextStyle(
                              fontSize: 15,
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

  Widget _buildPolicySection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
