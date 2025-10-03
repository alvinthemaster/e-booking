import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_models.dart';
import '../services/firebase_booking_service.dart';

class UserBookingListener extends StatefulWidget {
  final Widget child;
  
  const UserBookingListener({
    super.key,
    required this.child,
  });

  @override
  State<UserBookingListener> createState() => _UserBookingListenerState();
}

class _UserBookingListenerState extends State<UserBookingListener> {
  final FirebaseBookingService _bookingService = FirebaseBookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _processedCancellations = <String>{};

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    if (user == null) {
      return widget.child;
    }

    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getUserBookingsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final bookings = snapshot.data!;
          
          // Check for recently cancelled bookings by admin
          final recentlyCancelledBookings = bookings.where((booking) => 
              booking.bookingStatus == BookingStatus.cancelledByAdmin &&
              booking.cancelledAt != null &&
              booking.cancelledAt!.isAfter(DateTime.now().subtract(const Duration(minutes: 5))) &&
              !_processedCancellations.contains(booking.id)
          ).toList();
          
          if (recentlyCancelledBookings.isNotEmpty) {
            // Show notification to user
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCancellationNotification(recentlyCancelledBookings);
            });
          }
        }
        return widget.child;
      },
    );
  }
  
  void _showCancellationNotification(List<Booking> cancelledBookings) {
    for (final booking in cancelledBookings) {
      if (_processedCancellations.contains(booking.id)) continue;
      
      _processedCancellations.add(booking.id);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Booking Cancelled'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your booking has been cancelled by the administrator.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Route: ${booking.routeName}'),
                    Text('Seats: ${booking.seatIds.join(', ')}'),
                    Text('Amount: ₱${booking.totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (booking.cancellationReason != null)
                Text(
                  'Reason: ${booking.cancellationReason}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'You can book again with available seats. Any payment made will be refunded within 3-5 business days.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to booking screen
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Book Again'),
            ),
          ],
        ),
      );
    }
  }
}