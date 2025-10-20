import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_models.dart';
import '../services/notification_service.dart';
import 'dart:async';

/// Widget that displays countdown timer when user's booked van is full
class VanDepartureCountdownWidget extends StatefulWidget {
  const VanDepartureCountdownWidget({super.key});

  @override
  State<VanDepartureCountdownWidget> createState() =>
      _VanDepartureCountdownWidgetState();
}

class _VanDepartureCountdownWidgetState
    extends State<VanDepartureCountdownWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _bookingSubscription;
  StreamSubscription? _vanSubscription;
  Timer? _countdownTimer;

  Booking? _fullVanBooking;
  Van? _fullVan;
  Duration? _timeUntilDeparture;
  bool _hasNotifiedStart = false;
  bool _hasNotifiedEnd = false;

  @override
  void initState() {
    super.initState();
    _listenToBookings();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    _vanSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _listenToBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ VanWidget: No user logged in');
      return;
    }

    debugPrint('🔍 VanWidget: Starting to listen for user bookings (userId: ${user.uid})');

    // Listen to user's bookings (confirmed or pending)
    _bookingSubscription = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      debugPrint('📋 VanWidget: Received booking snapshot with ${snapshot.docs.length} bookings');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ VanWidget: No bookings found for user');
        setState(() {
          _fullVanBooking = null;
          _fullVan = null;
          _timeUntilDeparture = null;
          _hasNotifiedStart = false;
          _hasNotifiedEnd = false;
        });
        _countdownTimer?.cancel();
        _vanSubscription?.cancel();
        return;
      }

      // Get the most recent active booking (exclude cancelled)
      final bookings = snapshot.docs
          .map((doc) => Booking.fromDocument(doc))
          .where((booking) => booking.bookingStatus != BookingStatus.cancelled)
          .toList()
        ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      if (bookings.isEmpty) {
        debugPrint('⚠️ VanWidget: No active bookings found (all cancelled)');
        setState(() {
          _fullVanBooking = null;
          _fullVan = null;
          _timeUntilDeparture = null;
          _hasNotifiedStart = false;
          _hasNotifiedEnd = false;
        });
        _countdownTimer?.cancel();
        _vanSubscription?.cancel();
        return;
      }

      final booking = bookings.first;
      
      debugPrint('✅ VanWidget: Found booking - ID: ${booking.id}, Van: ${booking.vanPlateNumber}, Status: ${booking.bookingStatus}');

      // Listen to the van status for this booking
      _listenToVan(booking);
    });
  }

  void _listenToVan(Booking booking) {
    if (booking.vanPlateNumber == null) {
      debugPrint('❌ VanWidget: Booking has no vanPlateNumber!');
      return;
    }

    debugPrint('🔍 VanWidget: Listening to van with plate: ${booking.vanPlateNumber}');

    _vanSubscription?.cancel();
    _vanSubscription = _firestore
        .collection('vans')
        .where('plateNumber', isEqualTo: booking.vanPlateNumber)
        .snapshots()
        .listen((snapshot) {
      debugPrint('🚐 VanWidget: Received van snapshot with ${snapshot.docs.length} vans');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('❌ VanWidget: No van found with plate ${booking.vanPlateNumber}');
        return;
      }

      final van = Van.fromDocument(snapshot.docs.first);
      debugPrint('📊 VanWidget: Van data - Plate: ${van.plateNumber}, Status: "${van.status}", Occupancy: ${van.currentOccupancy}/${van.capacity}');

      // Check if van is full (by capacity OR status == "full" ONLY)
      final isFullByCapacity = van.currentOccupancy >= van.capacity;
      final isFullByStatus = van.status.toLowerCase().trim() == 'full';
      
      if (isFullByCapacity || isFullByStatus) {
        debugPrint(
          '🚐 Van ${van.plateNumber} detected as FULL - '
          'Occupancy: ${van.currentOccupancy}/${van.capacity}, Status: "${van.status}"',
        );
        
        setState(() {
          _fullVanBooking = booking;
          _fullVan = van;
        });

        // Start countdown timer
        _startCountdownTimer(van);
      } else {
        debugPrint(
          '⏳ Van ${van.plateNumber} not full yet - '
          'Occupancy: ${van.currentOccupancy}/${van.capacity}, Status: "${van.status}"',
        );
        
        setState(() {
          _fullVanBooking = null;
          _fullVan = null;
          _timeUntilDeparture = null;
          _hasNotifiedStart = false;
          _hasNotifiedEnd = false;
        });
        _countdownTimer?.cancel();
      }
    });
  }

  void _startCountdownTimer(Van van) {
    _countdownTimer?.cancel();

    // Check if van has scheduled departure time
    final vanDoc = _firestore.collection('vans').doc(van.id);
    vanDoc.get().then((doc) {
      if (doc.exists) {
        final data = doc.data();
        final scheduledDeparture = data?['scheduledDepartureTime'] as Timestamp?;

        DateTime departureTime;
        if (scheduledDeparture != null) {
          departureTime = scheduledDeparture.toDate();
        } else {
          // Default to 15 minutes from now if not set
          departureTime = DateTime.now().add(const Duration(minutes: 15));
        }

        // Send notification when timer starts (only once per van)
        if (!_hasNotifiedStart) {
          _hasNotifiedStart = true;
          final timeDiff = departureTime.difference(DateTime.now());
          final minutes = timeDiff.inMinutes;
          final seconds = timeDiff.inSeconds % 60;
          NotificationService().showNotification(
            title: '🚐 Your Van is Full!',
            body: 'Van ${van.plateNumber} will depart in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} minutes. Get ready!',
            payload: 'van_departure_${van.id}',
          );
          debugPrint('🔔 VanWidget: Sent countdown start notification for van ${van.plateNumber} - Time: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
        }

        // Update countdown every second
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final difference = departureTime.difference(now);

          if (difference.isNegative) {
            // Time's up - send departure notification
            timer.cancel();
            
            if (!_hasNotifiedEnd) {
              _hasNotifiedEnd = true;
              NotificationService().showNotification(
                title: '🚀 Van Departing Now!',
                body: 'Van ${van.plateNumber} is leaving. Please board immediately!',
                payload: 'van_departed_${van.id}',
              );
              debugPrint('🔔 VanWidget: Sent countdown end notification for van ${van.plateNumber}');
            }
            
            setState(() {
              _timeUntilDeparture = Duration.zero;
            });
          } else {
            setState(() {
              _timeUntilDeparture = difference;
            });
          }
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show widget if no full van booking
    if (_fullVanBooking == null || _fullVan == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to booking details
            Navigator.pushNamed(context, '/booking-history');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🚐 Your Van is Full!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Van ${_fullVan!.plateNumber}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Full capacity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_fullVan!.currentOccupancy}/${_fullVan!.capacity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                ),

                const SizedBox(height: 16),

                // Route information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fullVanBooking!.origin} → ${_fullVanBooking!.destination}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Seats',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullVanBooking!.seatIds.join(', '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Countdown timer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '⏱️ Departing In',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_timeUntilDeparture != null)
                        Text(
                          _timeUntilDeparture!.isNegative ||
                                  _timeUntilDeparture == Duration.zero
                              ? 'DEPARTING NOW!'
                              : _formatDuration(_timeUntilDeparture!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        )
                      else
                        const SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Please proceed to the boarding area',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action message
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap for booking details',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
