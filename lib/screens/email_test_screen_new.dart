import 'package:flutter/material.dart';
import '../services/email_service.dart';
import '../models/booking_models.dart';

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({super.key});

  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _lastResult;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Service Test'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.email,
                    size: 48,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'GODTRASCO Email Service Test',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test the email functionality with sample e-ticket data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Email input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Test Email Address',
                hintText: 'Enter email to receive test e-ticket',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2196F3),
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // Test buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testEmailConfiguration,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Test Email Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestTicketEmail,
              icon: const Icon(Icons.airplane_ticket),
              label: const Text('Send Test E-Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestConfirmationEmail,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Send Test Confirmation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Result display
            if (_lastResult != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _lastResult!.contains('✅') 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastResult!.contains('✅') 
                        ? Colors.green 
                        : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  _lastResult!,
                  style: TextStyle(
                    fontSize: 14,
                    color: _lastResult!.contains('✅') 
                        ? Colors.green[800] 
                        : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. First test email configuration\n'
                    '2. Enter your email address above\n'
                    '3. Send test e-ticket to verify template\n'
                    '4. Check inbox and spam folder\n'
                    '5. Verify QR code and styling',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testEmailConfiguration() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final result = await EmailService.testEmailConfiguration();
      setState(() {
        _lastResult = result 
            ? '✅ Email configuration is working correctly!'
            : '❌ Email configuration failed. Check SMTP settings.';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Configuration test failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestTicketEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _lastResult = '❌ Please enter an email address first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // Create sample booking data
      final sampleBooking = Booking(
        id: 'TEST${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test-user-123',
        userName: 'Test User',
        userEmail: _emailController.text.trim(),
        routeId: 'test-route-123',
        routeName: 'Glan to General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        bookingDate: DateTime.now(),
        seatIds: ['A1', 'A2'],
        numberOfSeats: 2,
        basePrice: 130.0,
        discountAmount: 20.0,
        totalAmount: 150.0,
        paymentMethod: 'GCash',
        paymentStatus: PaymentStatus.paid,
        bookingStatus: BookingStatus.confirmed,
        qrCodeData: 'https://e-ticket-2e8d0.web.app/?id=TEST${DateTime.now().millisecondsSinceEpoch}',
        passengerDetails: {
          'name': 'Test Passenger',
          'email': _emailController.text.trim(),
          'phone': '+63 912 345 6789',
        },
      );

      final result = await EmailService.sendETicketEmail(
        booking: sampleBooking,
        qrCodeData: sampleBooking.qrCodeData!,
      );

      setState(() {
        _lastResult = result 
            ? '✅ Test e-ticket sent successfully! Check your inbox.'
            : '❌ Failed to send test e-ticket. Check email configuration.';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Email sending failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestConfirmationEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _lastResult = '❌ Please enter an email address first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      // Create sample booking data
      final sampleBooking = Booking(
        id: 'CONF${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test-user-123',
        userName: 'Test User',
        userEmail: _emailController.text.trim(),
        routeId: 'test-route-123',
        routeName: 'Glan to General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        bookingDate: DateTime.now(),
        seatIds: ['B3'],
        numberOfSeats: 1,
        basePrice: 150.0,
        discountAmount: 0.0,
        totalAmount: 150.0,
        paymentMethod: 'Physical Payment',
        paymentStatus: PaymentStatus.pending,
        bookingStatus: BookingStatus.pending,
        passengerDetails: {
          'name': 'Test Passenger',
          'email': _emailController.text.trim(),
          'phone': '+63 912 345 6789',
        },
      );

      final result = await EmailService.sendBookingConfirmationEmail(
        booking: sampleBooking,
      );

      setState(() {
        _lastResult = result 
            ? '✅ Test confirmation email sent successfully! Check your inbox.'
            : '❌ Failed to send test confirmation. Check email configuration.';
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ Confirmation email failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}