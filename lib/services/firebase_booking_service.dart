import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_models.dart';

class FirebaseBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _routesCollection => _firestore.collection('routes');
  CollectionReference get _schedulesCollection => _firestore.collection('schedules');
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

      // Create booking with generated ID
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
        paymentStatus: PaymentStatus.pending,
        bookingStatus: BookingStatus.active,
        qrCodeData: _generateQRCode(bookingId),
        eTicketId: 'ET-${bookingId.substring(0, 8).toUpperCase()}',
        passengerDetails: booking.passengerDetails,
      );

      await docRef.set(bookingWithId.toMap());

      // Update seat availability in schedule
      await _updateSeatAvailability(booking.routeId, booking.seatIds, isBooking: true);

      return bookingId;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
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
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'bookingStatus': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String bookingId, PaymentStatus status) async {
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

      // Free up the seats
      await _updateSeatAvailability(booking.routeId, booking.seatIds, isBooking: false);
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

      return querySnapshot.docs
          .map((doc) => Route.fromDocument(doc))
          .toList();
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

  /// Check seat availability
  Future<bool> areSeatsAvailable(String routeId, List<String> seatIds) async {
    try {
      // Get current bookings for this route that are active
      final bookingsQuery = await _bookingsCollection
          .where('routeId', isEqualTo: routeId)
          .where('bookingStatus', isEqualTo: BookingStatus.active.name)
          .get();

      final bookedSeatIds = <String>[];
      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromDocument(doc);
        bookedSeatIds.addAll(booking.seatIds);
      }

      // Check if any of the requested seats are already booked
      return !seatIds.any((seatId) => bookedSeatIds.contains(seatId));
    } catch (e) {
      throw Exception('Failed to check seat availability: $e');
    }
  }

  /// Update seat availability in schedule
  Future<void> _updateSeatAvailability(String routeId, List<String> seatIds, {required bool isBooking}) async {
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
          basePrice: 180.0,
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
            arrivalTime: departureTime.add(Duration(minutes: route.estimatedDuration)),
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
      final querySnapshot = await _vansCollection
          .where('isActive', isEqualTo: true)
          .orderBy('queuePosition')
          .get();

      return querySnapshot.docs
          .map((doc) => Van.fromDocument(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting active vans: $e');
      throw Exception('Failed to get active vans: $e');
    }
  }

  /// Get vans by status
  Future<List<Van>> getVansByStatus(String status) async {
    try {
      final querySnapshot = await _vansCollection
          .where('status', isEqualTo: status)
          .where('isActive', isEqualTo: true)
          .orderBy('queuePosition')
          .get();

      return querySnapshot.docs
          .map((doc) => Van.fromDocument(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting vans by status: $e');
      throw Exception('Failed to get vans by status: $e');
    }
  }

  /// Update van occupancy
  Future<void> updateVanOccupancy(String vanId, int occupancy) async {
    try {
      await _vansCollection.doc(vanId).update({
        'currentOccupancy': occupancy,
      });
    } catch (e) {
      throw Exception('Failed to update van occupancy: $e');
    }
  }

  /// Update van status
  Future<void> updateVanStatus(String vanId, String status) async {
    try {
      await _vansCollection.doc(vanId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update van status: $e');
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
      print('❌ Failed to initialize sample vans: $e');
      throw Exception('Failed to initialize sample vans: $e');
    }
  }
}