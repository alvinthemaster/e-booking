import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/booking_models.dart';
import '../providers/payment_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/seat_provider.dart';
import 'eticket_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Seat> selectedSeats;
  final double totalAmount;
  final double discountAmount;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;

  const PaymentScreen({
    super.key,
    required this.selectedSeats,
    required this.totalAmount,
    required this.discountAmount,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
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
              onPressed: paymentProvider.isProcessing ? null : () => Navigator.pop(context),
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

                            _buildSummaryRow('Passenger:', widget.passengerName),
                            _buildSummaryRow('Seats:', widget.selectedSeats.map((s) => s.id).join(', ')),
                            _buildSummaryRow('Email:', widget.passengerEmail),
                            const Divider(height: 20),
                            _buildSummaryRowWithPeso(
                              'Total Amount:',
                              widget.totalAmount.toStringAsFixed(2),
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

                            ...paymentProvider.availablePaymentMethods.map((method) {
                              return _buildPaymentMethodTile(method, paymentProvider);
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment Status
                      if (paymentProvider.currentStatus != PaymentStatus.pending ||
                          paymentProvider.errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: paymentProvider.getPaymentStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: paymentProvider.getPaymentStatusColor().withOpacity(0.3),
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
                                  color: paymentProvider.getPaymentStatusColor(),
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
                        onPressed: paymentProvider.isProcessing ||
                                paymentProvider.currentStatus == PaymentStatus.paid
                            ? null
                            : () => _processPayment(paymentProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: paymentProvider.currentStatus == PaymentStatus.paid
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: paymentProvider.isProcessing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                            : paymentProvider.currentStatus == PaymentStatus.paid
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
                                        _getPaymentMethodIcon(paymentProvider.selectedMethod),
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

  Widget _buildSummaryRowWithPeso(String label, String amount, {bool isTotal = false}) {
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

  Widget _buildPaymentMethodTile(String method, PaymentProvider paymentProvider) {
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

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'GCash':
        return Icons.account_balance_wallet;
      case 'Maya':
        return Icons.credit_card;
      case 'PayPal':
        return Icons.paypal;
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
    final success = await paymentProvider.processPayment(
      bookingId: 'UVE${DateTime.now().millisecondsSinceEpoch}',
      amount: widget.totalAmount,
      method: paymentProvider.selectedMethod,
    );

    if (success && mounted) {
      // Create booking
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final seatProvider = Provider.of<SeatProvider>(context, listen: false);

      final bookingId = await bookingProvider.createBooking(
        routeId: 'route-001', // TODO: Pass route information through navigation
        routeName: 'Glan to General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        seatIds: widget.selectedSeats.map((seat) => seat.id).toList(),
        basePrice: widget.totalAmount - widget.discountAmount,
        discountAmount: widget.discountAmount,
        totalAmount: widget.totalAmount,
        paymentMethod: paymentProvider.selectedMethod,
        passengerDetails: {
          'name': widget.passengerName,
          'email': widget.passengerEmail,
          'phone': widget.passengerPhone,
        },
      );

      // Update payment status
      await bookingProvider.updatePaymentStatus(bookingId, paymentProvider.currentStatus);

      // Reserve seats
      await seatProvider.reserveSelectedSeats();

      // Navigate to e-ticket
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ETicketScreen(bookingId: bookingId),
          ),
        );
      }
    }
  }
}