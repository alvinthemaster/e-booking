import 'package:flutter/material.dart';
import '../models/booking_models.dart';

class PaymentProvider with ChangeNotifier {
  PaymentStatus _currentStatus = PaymentStatus.pending;
  bool _isProcessing = false;
  String _selectedMethod = 'GCash';
  String? _errorMessage;

  PaymentStatus get currentStatus => _currentStatus;
  bool get isProcessing => _isProcessing;
  String get selectedMethod => _selectedMethod;
  String? get errorMessage => _errorMessage;

  List<String> get availablePaymentMethods => [
    'GCash',
    'Physical Payment',
    'Maya',
    'PayPal',
  ];

  void setPaymentMethod(String method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<bool> processPayment({
    required String bookingId,
    required double amount,
    required String method,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (method == 'GCash') {
        // Simulate GCash payment
        final success = await _processGCashPayment(amount);
        if (success) {
          _currentStatus = PaymentStatus.paid;
          return true;
        } else {
          _currentStatus = PaymentStatus.failed;
          _errorMessage = 'GCash payment failed. Please try again.';
          return false;
        }
      } else if (method == 'Physical Payment') {
        // Physical payment is always pending until confirmed
        _currentStatus = PaymentStatus.pending;
        return true;
      } else {
        // Other digital payment methods
        final success = await _processDigitalPayment(method, amount);
        if (success) {
          _currentStatus = PaymentStatus.paid;
          return true;
        } else {
          _currentStatus = PaymentStatus.failed;
          _errorMessage = '$method payment failed. Please try again.';
          return false;
        }
      }
    } catch (e) {
      _currentStatus = PaymentStatus.failed;
      _errorMessage = 'Payment processing error: ${e.toString()}';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> _processGCashPayment(double amount) async {
    // In a real app, this would integrate with GCash API
    await Future.delayed(const Duration(seconds: 1));
    // Simulate 90% success rate
    return DateTime.now().millisecond % 10 != 0;
  }

  Future<bool> _processDigitalPayment(String method, double amount) async {
    // In a real app, this would integrate with respective payment APIs
    await Future.delayed(const Duration(seconds: 1));
    // Simulate 85% success rate
    return DateTime.now().millisecond % 10 < 8;
  }

  void resetPaymentStatus() {
    _currentStatus = PaymentStatus.pending;
    _isProcessing = false;
    _errorMessage = null;
    notifyListeners();
  }

  String getPaymentStatusMessage() {
    switch (_currentStatus) {
      case PaymentStatus.pending:
        return _selectedMethod == 'Physical Payment' 
            ? 'Please pay at the terminal before boarding'
            : 'Payment processing...';
      case PaymentStatus.paid:
        return 'Payment successful! E-ticket generated.';
      case PaymentStatus.failed:
        return _errorMessage ?? 'Payment failed. Please try again.';
      case PaymentStatus.refunded:
        return 'Payment has been refunded.';
    }
  }

  Color getPaymentStatusColor() {
    switch (_currentStatus) {
      case PaymentStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case PaymentStatus.paid:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.failed:
        return const Color(0xFFF44336); // Red
      case PaymentStatus.refunded:
        return const Color(0xFF2196F3); // Blue
    }
  }
}