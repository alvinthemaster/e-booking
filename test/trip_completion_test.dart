import 'package:flutter_test/flutter_test.dart';
import 'package:uvexpress_eticket/models/booking_models.dart';

void main() {
  group('Trip Completion Integration Tests', () {
    test('Booking model should support completion fields', () {
      final completedAt = DateTime.now();
      
      final booking = Booking(
        id: 'test_booking',
        userId: 'user_123',
        userName: 'John Doe',
        userEmail: 'john@example.com',
        routeId: 'route_1',
        routeName: 'Glan → General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(Duration(hours: 2)),
        bookingDate: DateTime.now(),
        seatIds: ['1', '2'],
        numberOfSeats: 2,
        basePrice: 300.0,
        discountAmount: 0.0,
        totalAmount: 300.0,
        paymentMethod: 'GCash',
        paymentStatus: PaymentStatus.paid,
        bookingStatus: BookingStatus.completed,
        completedAt: completedAt,
        completionReason: 'Trip completed by administrator',
        adminCompletion: true,
      );

      // Test completion fields
      expect(booking.completedAt, equals(completedAt));
      expect(booking.completionReason, equals('Trip completed by administrator'));
      expect(booking.adminCompletion, isTrue);
      expect(booking.bookingStatus, equals(BookingStatus.completed));
    });

    test('Booking serialization should include completion fields', () {
      final completedAt = DateTime.now();
      
      final booking = Booking(
        id: 'test_booking',
        userId: 'user_123',
        userName: 'John Doe',
        userEmail: 'john@example.com',
        routeId: 'route_1',
        routeName: 'Glan → General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(Duration(hours: 2)),
        bookingDate: DateTime.now(),
        seatIds: ['1'],
        numberOfSeats: 1,
        basePrice: 150.0,
        discountAmount: 0.0,
        totalAmount: 150.0,
        paymentMethod: 'Cash',
        paymentStatus: PaymentStatus.paid,
        bookingStatus: BookingStatus.completed,
        completedAt: completedAt,
        completionReason: 'Trip completed by administrator',
        adminCompletion: true,
      );

      // Serialize to map
      final map = booking.toMap();
      
      // Verify completion fields are included
      expect(map['bookingStatus'], equals('completed'));
      expect(map['completionReason'], equals('Trip completed by administrator'));
      expect(map['adminCompletion'], isTrue);
      expect(map['completedAt'], isNotNull);

      // Deserialize from map
      final deserializedBooking = Booking.fromMap({...map, 'id': 'test_booking'});
      
      // Verify all fields match
      expect(deserializedBooking.completionReason, equals(booking.completionReason));
      expect(deserializedBooking.adminCompletion, equals(booking.adminCompletion));
      expect(deserializedBooking.bookingStatus, equals(BookingStatus.completed));
    });

    test('Booking status enum should include all required values', () {
      final values = BookingStatus.values;
      
      expect(values.contains(BookingStatus.pending), isTrue);
      expect(values.contains(BookingStatus.confirmed), isTrue);
      expect(values.contains(BookingStatus.completed), isTrue);
      expect(values.contains(BookingStatus.cancelled), isTrue);
      expect(values.contains(BookingStatus.cancelledByAdmin), isTrue);
    });

    test('Booking with null completion fields should handle gracefully', () {
      final booking = Booking(
        id: 'test_booking',
        userId: 'user_123',
        userName: 'Jane Doe',
        userEmail: 'jane@example.com',
        routeId: 'route_1',
        routeName: 'Glan → General Santos',
        origin: 'Glan',
        destination: 'General Santos',
        departureTime: DateTime.now().add(Duration(hours: 2)),
        bookingDate: DateTime.now(),
        seatIds: ['3'],
        numberOfSeats: 1,
        basePrice: 150.0,
        discountAmount: 0.0,
        totalAmount: 150.0,
        paymentMethod: 'GCash',
        paymentStatus: PaymentStatus.pending,
        bookingStatus: BookingStatus.pending,
        // completion fields are null
      );

      // Test null completion fields
      expect(booking.completedAt, isNull);
      expect(booking.completionReason, isNull);
      expect(booking.adminCompletion, isNull);
      expect(booking.bookingStatus, equals(BookingStatus.pending));

      // Serialization should handle null values
      final map = booking.toMap();
      expect(map['completedAt'], isNull);
      expect(map['completionReason'], isNull);
      expect(map['adminCompletion'], isNull);
    });
  });
}