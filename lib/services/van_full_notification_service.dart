import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_models.dart';
import 'notification_service.dart';

/// Service to handle notifications when a van becomes full
class VanFullNotificationService {
  static final VanFullNotificationService _instance =
      VanFullNotificationService._internal();
  factory VanFullNotificationService() => _instance;
  VanFullNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Track vans that have already triggered notifications
  final Set<String> _notifiedVans = {};

  /// Manually trigger notification for a van (for testing/admin use)
  Future<void> manuallyTriggerNotification(String vanId) async {
    // Clear the notification flag first to allow re-triggering
    _notifiedVans.remove(vanId);
    await checkAndNotifyIfVanFull(vanId);
  }

  /// Check if van is full and schedule departure notification
  Future<void> checkAndNotifyIfVanFull(String vanId) async {
    try {
      // Prevent duplicate notifications for the same van
      if (_notifiedVans.contains(vanId)) {
        debugPrint(
          'VanFullNotification: Van $vanId already notified, skipping',
        );
        return;
      }

      // Get van details
      final vanDoc = await _firestore.collection('vans').doc(vanId).get();
      if (!vanDoc.exists) {
        debugPrint('VanFullNotification: Van $vanId not found');
        return;
      }

      final van = Van.fromDocument(vanDoc);

      // Check if van is full (either by capacity OR by status)
      final isFullByCapacity = van.currentOccupancy >= van.capacity;
      final isFullByStatus = van.status.toLowerCase().trim() == 'full' || 
                             van.status.toLowerCase().trim() == 'boarding';
      
      if (isFullByCapacity || isFullByStatus) {
        debugPrint(
          'VanFullNotification: Van ${van.plateNumber} is FULL - '
          'Occupancy: ${van.currentOccupancy}/${van.capacity}, Status: "${van.status}"',
        );

        // Mark van as notified
        _notifiedVans.add(vanId);

        // Schedule notification for 15 minutes from now
        final departureTime = DateTime.now().add(const Duration(minutes: 15));

        // Get all confirmed bookings for this van
        final bookingsSnapshot = await _firestore
            .collection('bookings')
            .where('vanPlateNumber', isEqualTo: van.plateNumber)
            .where('bookingStatus', isEqualTo: 'confirmed')
            .get();

        final bookings = bookingsSnapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList();

        debugPrint(
          'VanFullNotification: Found ${bookings.length} confirmed bookings for van ${van.plateNumber}',
        );

        // Schedule departure notifications for all passengers
        for (var booking in bookings) {
          await _scheduleDepartureNotification(
            booking: booking,
            van: van,
            departureTime: departureTime,
          );
        }


        // Update van with departure time in Firestore and mark departure timer active
        await _firestore.collection('vans').doc(vanId).update({
          'scheduledDepartureTime': Timestamp.fromDate(departureTime),
          'notificationSent': true,
          'departureTimerActive': true,
        });

        // Show immediate notification to all users (message tailored for bus/van)
        final isBus = van.vehicleType.toLowerCase() == 'bus';
        final immediateTitle = isBus ? '🚌 Bus is Full!' : '🚐 Van is Full!';
        final immediateBody = isBus
            ? 'Bus ${van.plateNumber} is full and will depart in 15 minutes. Please proceed to the boarding area.'
            : 'Van ${van.plateNumber} is full and will depart in 15 minutes. Please proceed to the boarding area.';

        await _notificationService.showNotification(
          title: immediateTitle,
          body: immediateBody,
        );

        debugPrint(
          'VanFullNotification: Departure notifications scheduled for ${bookings.length} passengers',
        );
      } else {
        debugPrint(
          'VanFullNotification: Van ${van.plateNumber} is not full yet - '
          'Occupancy: ${van.currentOccupancy}/${van.capacity}, Status: "${van.status}"',
        );
      }
    } catch (e) {
      debugPrint('VanFullNotification: Error checking van: $e');
    }
  }

  /// Schedule a departure notification for a specific booking
  Future<void> _scheduleDepartureNotification({
    required Booking booking,
    required Van van,
    required DateTime departureTime,
  }) async {
    try {
      // Use booking ID as notification ID to ensure uniqueness
      final notificationId = booking.id.hashCode;

      final title = '🚐 Van Departing Soon!';
      final body =
          'Your van ${van.plateNumber} (${booking.origin} → ${booking.destination}) will depart in 15 minutes. Please proceed to the boarding area now.';

      // Schedule notification for 15 minutes from now
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledTime: departureTime,
        payload: booking.id,
      );

      debugPrint(
        'VanFullNotification: Scheduled notification for booking ${booking.id} at $departureTime',
      );
    } catch (e) {
      debugPrint(
        'VanFullNotification: Error scheduling notification for booking ${booking.id}: $e',
      );
    }
  }

  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    await _notificationService.showNotification(
      title: '🚐 Test Notification',
      body: 'This is a test notification from UVexpress E-Ticket System.',
    );
  }

  /// Clear notification history for a van
  void clearVanNotification(String vanId) {
    _notifiedVans.remove(vanId);
    debugPrint('VanFullNotification: Cleared notification flag for van $vanId');
  }

  /// Reset all notifications (for testing)
  void resetAllNotifications() {
    _notifiedVans.clear();
    debugPrint('VanFullNotification: Reset all notification flags');
  }

  /// Cancel departure notification for a booking
  Future<void> cancelDepartureNotification(String bookingId) async {
    try {
      final notificationId = bookingId.hashCode;
      await _notificationService.cancelNotification(notificationId);
      debugPrint(
        'VanFullNotification: Cancelled notification for booking $bookingId',
      );
    } catch (e) {
      debugPrint(
        'VanFullNotification: Error cancelling notification: $e',
      );
    }
  }

  /// Listen to van occupancy changes in real-time
  Stream<void> listenToVanOccupancy(String routeId) async* {
    await for (var snapshot in _firestore
        .collection('vans')
        .where('currentRouteId', isEqualTo: routeId)
        .where('isActive', isEqualTo: true)
        .snapshots()) {
      for (var doc in snapshot.docs) {
        final van = Van.fromDocument(doc);
        if (van.currentOccupancy >= van.capacity) {
          // Van became full, check and notify
          await checkAndNotifyIfVanFull(doc.id);
        }
      }
    }
  }
}
