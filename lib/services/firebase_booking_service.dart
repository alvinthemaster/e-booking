import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_models.dart';

class FirebaseBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');
  CollectionReference get _routesCollection => _firestore.collection('routes');
  CollectionReference get _schedulesCollection =>
      _firestore.collection('schedules');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _vansCollection => _firestore.collection('vans');

  /// Create a new booking
  Future<String> createBooking(Booking booking) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate booking ID
      final docRef = _bookingsCollection.doc();
      final bookingId = docRef.id;

      // Create booking with generated ID and preserve the provided payment status
      final bookingWithId = Booking(
        id: bookingId,
        userId: booking.userId,
        userName: booking.userName,
        userEmail: booking.userEmail,
        routeId: booking.routeId,
        routeName: booking.routeName,
        origin: booking.origin,
        destination: booking.destination,
        departureTime: booking.departureTime,
        bookingDate: DateTime.now(),
        seatIds: booking.seatIds,
        numberOfSeats: booking.numberOfSeats,
        basePrice: booking.basePrice,
        discountAmount: booking.discountAmount,
        totalAmount: booking.totalAmount,
        paymentMethod: booking.paymentMethod,
        paymentStatus: booking.paymentStatus, // Use the provided payment status
        bookingStatus: BookingStatus.pending, // New bookings start as pending
        qrCodeData: _generateQRCode(bookingId),
        eTicketId: 'ET-${bookingId.substring(0, 8).toUpperCase()}',
        passengerDetails: booking.passengerDetails,
        vanPlateNumber: booking.vanPlateNumber,
        vanDriverName: booking.vanDriverName,
        vanDriverContact: booking.vanDriverContact,
      );

      await docRef.set(bookingWithId.toMap());

      // Update van occupancy
      if (booking.vanPlateNumber != null && booking.vanDriverName != null) {
        await _updateVanOccupancy(
          booking.vanPlateNumber!,
          booking.vanDriverName!,
          booking.numberOfSeats,
          true, // isBooking
        );
      }

      // Update seat availability in schedule
      await _updateSeatAvailability(
        booking.routeId,
        booking.seatIds,
        isBooking: true,
      );

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get active bookings stream for a van (only pending and confirmed bookings)
  Stream<List<Booking>> getActiveBookingsForVan(String vanId, String routeId) {
    return _bookingsCollection
        .where('routeId', isEqualTo: routeId)
        .where('bookingStatus', whereIn: ['pending', 'confirmed']) // Only active bookings
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList());
  }

  /// Get user's bookings stream (for real-time cancellation detection)
  Stream<List<Booking>> getUserBookingsStream(String userId) {
    return _bookingsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromDocument(doc))
            .toList());
  }

  /// Cancel booking by admin (sets status to cancelledByAdmin)
  Future<void> cancelBookingByAdmin(String bookingId, {String? reason}) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'bookingStatus': BookingStatus.cancelledByAdmin.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason ?? 'Cancelled by administrator',
        'cancelledBy': 'admin',
      });
    } catch (e) {
      throw Exception('Failed to cancel booking by admin: $e');
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _bookingsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('bookingDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Check if seat is available (helper method for seat selection logic)
  bool isSeatAvailable(int seatNumber, List<Booking> activeBookings) {
    return !activeBookings.any((booking) => 
        booking.seatIds.contains(seatNumber.toString()) && 
        ['pending', 'confirmed'].contains(booking.bookingStatus.name) // Only active bookings
    );
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return null;
      return Booking.fromDocument(doc);
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'bookingStatus': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String bookingId,
    PaymentStatus status,
  ) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'paymentStatus': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // Update booking status to cancelled
      await updateBookingStatus(bookingId, BookingStatus.cancelled);

      // Update van occupancy
      if (booking.vanPlateNumber != null && booking.vanDriverName != null) {
        await _updateVanOccupancy(
          booking.vanPlateNumber!,
          booking.vanDriverName!,
          booking.numberOfSeats,
          false, // isBooking = false (cancellation)
        );
      }

      // Free up the seats
      await _updateSeatAvailability(
        booking.routeId,
        booking.seatIds,
        isBooking: false,
      );
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get available routes
  Future<List<Route>> getAvailableRoutes() async {
    try {
      final querySnapshot = await _routesCollection
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => Route.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get routes: $e');
    }
  }

  /// Get schedules for a route
  Future<List<Schedule>> getRouteSchedules(String routeId) async {
    try {
      final querySnapshot = await _schedulesCollection
          .where('routeId', isEqualTo: routeId)
          .where('isActive', isEqualTo: true)
          .where('departureTime', isGreaterThan: Timestamp.now())
          .orderBy('departureTime')
          .get();

      return querySnapshot.docs
          .map((doc) => Schedule.fromDocument(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get schedules: $e');
    }
  }

  /// Check seat availability for a specific van
  Future<bool> areSeatsAvailable(
    String routeId,
    List<String> seatIds,
    String vanPlateNumber,
    String vanDriverName,
  ) async {
    try {
      // Get current bookings for this specific van that are active (pending or confirmed)
      final bookingsQuery = await _bookingsCollection
          .where('routeId', isEqualTo: routeId)
          .where('vanPlateNumber', isEqualTo: vanPlateNumber)
          .where('vanDriverName', isEqualTo: vanDriverName)
          .where('bookingStatus', whereIn: ['pending', 'confirmed']) // Only active bookings block seats
          .get();

      final bookedSeatIds = <String>[];
      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromDocument(doc);
        bookedSeatIds.addAll(booking.seatIds);
      }

      // Check if any of the requested seats are already booked on this specific van
      return !seatIds.any((seatId) => bookedSeatIds.contains(seatId));
    } catch (e) {
      throw Exception('Failed to check seat availability: $e');
    }
  }

  /// Get available vans for booking (only boarding vans) - integrates with admin van management
  Future<List<Van>> getAvailableVansForBooking(String routeId) async {
    try {
      // Get only vans with 'boarding' status - actively accepting passengers
      final vansQuery = await _vansCollection
          .where('currentRouteId', isEqualTo: routeId)
          .where('isActive', isEqualTo: true)
          .where('status', isEqualTo: 'boarding') // Only boarding status
          .get();

      final availableVans = <Van>[];
      for (final doc in vansQuery.docs) {
        final van = Van.fromDocument(doc);
        // Double-check capacity (admin system should handle this, but safety check)
        if (van.currentOccupancy < van.capacity) {
          availableVans.add(van);
        }
      }

      // Sort by queue position for proper van selection
      availableVans.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
      
      debugPrint('Available boarding vans: ${availableVans.length}');
      return availableVans;
    } catch (e) {
      debugPrint('Error getting available vans for booking: $e');
      return [];
    }
  }

  /// Get the active van for a specific route (integrates with admin van management)
  Future<Van?> getActiveVanForRoute(String routeId) async {
    try {
      debugPrint('Looking for bookable van with routeId: $routeId');
      
      // Get only bookable vans (excludes full ones) using admin van management
      final availableVans = await getAvailableVansForBooking(routeId);
      
      if (availableVans.isNotEmpty) {
        final selectedVan = availableVans.first;
        debugPrint('Found bookable van: ${selectedVan.plateNumber} (Occupancy: ${selectedVan.currentOccupancy}/${selectedVan.capacity})');
        return selectedVan;
      }
      
      debugPrint('No bookable vans found for route $routeId');
      
      // Final debug: Get ALL vans to see what exists
      final allVansQuery = await _vansCollection.get();
      debugPrint('Total vans in database: ${allVansQuery.docs.length}');
      
      for (final doc in allVansQuery.docs) {
        final van = Van.fromDocument(doc);
        debugPrint('Van: ${van.plateNumber}, Route: ${van.currentRouteId}, Active: ${van.isActive}, Status: ${van.status}, Occupancy: ${van.currentOccupancy}/${van.capacity}');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting active van for route: $e');
      return null;
    }
  }

  /// Update van occupancy when booking is created or cancelled
  Future<void> _updateVanOccupancy(
    String plateNumber,
    String driverName,
    int seatCount,
    bool isBooking,
  ) async {
    try {
      // Find the van by plate number and driver name
      final vanQuery = await _vansCollection
          .where('plateNumber', isEqualTo: plateNumber)
          .where('driver.name', isEqualTo: driverName)
          .limit(1)
          .get();

      if (vanQuery.docs.isNotEmpty) {
        final vanDoc = vanQuery.docs.first;
        final van = Van.fromDocument(vanDoc);

        // Calculate new occupancy
        final newOccupancy = isBooking
            ? van.currentOccupancy + seatCount
            : van.currentOccupancy - seatCount;

        // Ensure occupancy doesn't go below 0 or above capacity
        final clampedOccupancy = newOccupancy.clamp(0, van.capacity);

        // Update the van document
        await vanDoc.reference.update({'currentOccupancy': clampedOccupancy});

        debugPrint(
          '✅ Updated van ${plateNumber} occupancy: ${van.currentOccupancy} → ${clampedOccupancy}',
        );
      } else {
        debugPrint(
          '⚠️ Van not found for occupancy update: $plateNumber ($driverName)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating van occupancy: $e');
    }
  }

  /// Get reserved seats for a specific van (identified by plate number and driver name)
  Future<List<String>> getReservedSeats(
    String routeId,
    String vanPlateNumber,
    String vanDriverName,
  ) async {
    try {
      // Get current bookings for this specific van that are active (pending or confirmed) and paid
      final bookingsQuery = await _bookingsCollection
          .where('routeId', isEqualTo: routeId)
          .where('vanPlateNumber', isEqualTo: vanPlateNumber)
          .where('vanDriverName', isEqualTo: vanDriverName)
          .where('bookingStatus', whereIn: ['pending', 'confirmed']) // Only active bookings
          .where(
            'paymentStatus',
            whereIn: [PaymentStatus.paid.name, PaymentStatus.pending.name],
          )
          .get();

      final reservedSeatIds = <String>[];
      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromDocument(doc);
        reservedSeatIds.addAll(booking.seatIds);
      }

      return reservedSeatIds;
    } catch (e) {
      debugPrint('Error getting reserved seats: $e');
      return []; // Return empty list on error to not break the UI
    }
  }

  /// Update seat availability in schedule
  Future<void> _updateSeatAvailability(
    String routeId,
    List<String> seatIds, {
    required bool isBooking,
  }) async {
    try {
      final schedulesQuery = await _schedulesCollection
          .where('routeId', isEqualTo: routeId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in schedulesQuery.docs) {
        final schedule = Schedule.fromDocument(doc);
        final updatedBookedSeats = List<String>.from(schedule.bookedSeats);

        if (isBooking) {
          // Add seats to booked list
          updatedBookedSeats.addAll(seatIds);
        } else {
          // Remove seats from booked list
          for (final seatId in seatIds) {
            updatedBookedSeats.remove(seatId);
          }
        }

        await _schedulesCollection.doc(doc.id).update({
          'bookedSeats': updatedBookedSeats,
          'availableSeats': schedule.totalSeats - updatedBookedSeats.length,
        });
      }
    } catch (e) {
      throw Exception('Failed to update seat availability: $e');
    }
  }

  /// Generate QR Code data
  String _generateQRCode(String bookingId) {
    return 'UVexpress-$bookingId-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Initialize sample data (for testing)
  Future<void> initializeSampleData() async {
    try {
      // Check if routes already exist
      final routesSnapshot = await _routesCollection.limit(1).get();
      if (routesSnapshot.docs.isNotEmpty) {
        print('Sample data already exists');
        return;
      }

      // Create Glan-GenSan route only
      final sampleRoutes = [
        Route(
          id: 'route_glan_gensan',
          name: 'Glan → General Santos',
          origin: 'Glan',
          destination: 'General Santos',
          basePrice: 150.0,
          estimatedDuration: 120,
          waypoints: ['Glan', 'Polomolok', 'General Santos'],
        ),
      ];

      // Add routes to Firestore
      for (final route in sampleRoutes) {
        await _routesCollection.doc(route.id).set(route.toMap());
      }

      // Create sample schedules for each route
      for (final route in sampleRoutes) {
        final now = DateTime.now();
        for (int i = 0; i < 5; i++) {
          final departureTime = now.add(Duration(hours: i + 1));
          final schedule = Schedule(
            id: '${route.id}_schedule_$i',
            routeId: route.id,
            departureTime: departureTime,
            arrivalTime: departureTime.add(
              Duration(minutes: route.estimatedDuration),
            ),
            availableSeats: 12, // Van capacity for Glan-GenSan
            totalSeats: 12,
            bookedSeats: [],
          );
          await _schedulesCollection.doc(schedule.id).set(schedule.toMap());
        }
      }

      print('Sample data initialized successfully');
    } catch (e) {
      throw Exception('Failed to initialize sample data: $e');
    }
  }

  /// Van Management Methods

  /// Get all active vans ordered by queue position
  Future<List<Van>> getActiveVans() async {
    try {
      debugPrint('🔍 Querying vans collection from Firestore...');

      // Temporary: Use simple query without ordering to avoid index requirement
      final querySnapshot = await _vansCollection
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint(
        '📄 Found ${querySnapshot.docs.length} van documents in Firestore',
      );

      final vans = <Van>[];
      for (var doc in querySnapshot.docs) {
        try {
          debugPrint('Processing van document: ${doc.id}');
          final docData = doc.data() as Map<String, dynamic>;
          debugPrint('Raw status from Firestore: ${docData['status']}');
          final van = Van.fromDocument(doc);
          
          // Only include vans that are boarding (actively accepting passengers)
          if (van.status == 'boarding') {
            debugPrint(
              'Successfully parsed boarding van: ${van.plateNumber} - Status: ${van.status} - Display: ${van.statusDisplay}',
            );
            vans.add(van);
          } else {
            debugPrint('Skipping non-boarding van: ${van.plateNumber} (Status: ${van.status})');
          }
        } catch (e) {
          debugPrint('Error parsing van document ${doc.id}: $e');
          debugPrint('Document data: ${doc.data()}');
        }
      }

      // Sort in memory instead of in query (temporary workaround)
      vans.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

      debugPrint('🎯 Returning ${vans.length} parsed vans');
      return vans;
    } catch (e) {
      debugPrint('❌ Error getting active vans: $e');
      throw Exception('Failed to get active vans: $e');
    }
  }

  /// Get vans by status
  Future<List<Van>> getVansByStatus(String status) async {
    try {
      // Temporary: Use simple query without ordering to avoid index requirement
      final querySnapshot = await _vansCollection
          .where('status', isEqualTo: status)
          .where('isActive', isEqualTo: true)
          .get();

      final vans = querySnapshot.docs
          .map((doc) => Van.fromDocument(doc))
          .toList();

      // Sort in memory instead of in query (temporary workaround)
      vans.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));

      return vans;
    } catch (e) {
      print('❌ Error getting vans by status: $e');
      throw Exception('Failed to get vans by status: $e');
    }
  }

  /// Update van occupancy
  Future<void> updateVanOccupancy(String vanId, int occupancy) async {
    try {
      await _vansCollection.doc(vanId).update({'currentOccupancy': occupancy});
    } catch (e) {
      throw Exception('Failed to update van occupancy: $e');
    }
  }

  /// Add sample van data for testing
  Future<void> initializeSampleVans() async {
    try {
      // Check if vans already exist
      final vansSnapshot = await _vansCollection.limit(1).get();
      if (vansSnapshot.docs.isNotEmpty) {
        print('🚐 Sample vans already exist');
        return;
      }

      print('🚐 Creating sample van data...');

      final sampleVans = [
        Van(
          id: 'van_001',
          plateNumber: 'ABC-123',
          capacity: 18,
          driver: Driver(
            id: 'driver_001',
            name: 'Juan Dela Cruz',
            license: 'N01-12-123456',
            contact: '+639123456789',
          ),
          status: 'boarding',
          currentRouteId: 'route_glan_gensan',
          queuePosition: 1,
          currentOccupancy: 15,
          isActive: true,
          createdAt: DateTime.now(),
        ),
        Van(
          id: 'van_002',
          plateNumber: 'DEF-456',
          capacity: 18,
          driver: Driver(
            id: 'driver_002',
            name: 'Maria Santos',
            license: 'N01-12-789012',
            contact: '+639987654321',
          ),
          status: 'in_queue',
          currentRouteId: 'route_glan_gensan',
          queuePosition: 2,
          currentOccupancy: 8,
          isActive: true,
          createdAt: DateTime.now(),
        ),
      ];

      for (final van in sampleVans) {
        await _vansCollection.doc(van.id).set(van.toMap());
        print('🚐 Created van: ${van.plateNumber}');
      }

      print('✅ Sample van data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample van data: $e');
      throw Exception('Failed to initialize sample van data: $e');
    }
  }

  /// Create a new van
  Future<String> createVan(Van van) async {
    try {
      final docRef = _vansCollection.doc();
      final vanWithId = Van(
        id: docRef.id,
        plateNumber: van.plateNumber,
        capacity: van.capacity,
        driver: van.driver,
        status: van.status,
        currentRouteId: van.currentRouteId,
        queuePosition: van.queuePosition,
        currentOccupancy: van.currentOccupancy,
        isActive: van.isActive,
        lastMaintenance: van.lastMaintenance,
        nextMaintenance: van.nextMaintenance,
        createdAt: van.createdAt,
      );

      await docRef.set(vanWithId.toMap());
      debugPrint('✅ Created van: ${van.plateNumber} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating van: $e');
      throw Exception('Failed to create van: $e');
    }
  }

  /// Update van status
  Future<void> updateVanStatus(String vanId, String status) async {
    try {
      await _vansCollection.doc(vanId).update({'status': status});
      debugPrint('✅ Updated van $vanId status to: $status');
    } catch (e) {
      debugPrint('❌ Error updating van status: $e');
      throw Exception('Failed to update van status: $e');
    }
  }

  /// Update van queue position
  Future<void> updateVanQueuePosition(String vanId, int position) async {
    try {
      await _vansCollection.doc(vanId).update({'queuePosition': position});
      debugPrint('✅ Updated van $vanId queue position to: $position');
    } catch (e) {
      debugPrint('❌ Error updating van queue position: $e');
      throw Exception('Failed to update van queue position: $e');
    }
  }

  /// Delete van
  Future<void> deleteVan(String vanId) async {
    try {
      await _vansCollection.doc(vanId).delete();
      debugPrint('✅ Deleted van: $vanId');
    } catch (e) {
      debugPrint('❌ Error deleting van: $e');
      throw Exception('Failed to delete van: $e');
    }
  }
}
