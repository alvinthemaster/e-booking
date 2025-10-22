import 'package:flutter/foundation.dart';
import '../models/booking_models.dart';
import '../services/firebase_booking_service.dart';

class SeatProvider with ChangeNotifier {
  final FirebaseBookingService _bookingService = FirebaseBookingService();
  List<Seat> _seats = [];
  List<Seat> _selectedSeats = [];
  final double _baseFare = 150.0;
  final double _discountRate = 0.1333; // 13.33%
  String _vehicleType = 'van'; // Default to 'van'

  List<Seat> get seats => _seats;
  List<Seat> get selectedSeats => _selectedSeats;
  double get baseFare => _baseFare;
  double get discountRate => _discountRate;
  String get vehicleType => _vehicleType;

  int get maxSeatsPerBooking => 5;

  Future<void> initializeSeats({String? routeId, String vehicleType = 'van'}) async {
    _vehicleType = vehicleType;
    _seats = [];

    if (vehicleType == 'bus') {
      // Initialize bus seats (22 seats total)
      // 1 seat beside driver + 4 rows: 2-2 configuration (16 seats) + 1 row: 3-2 configuration (5 seats)
      
      // Driver-adjacent seat (1 seat on the right)
      _seats.add(Seat(id: 'D1A', row: 0, position: 'driver-right'));

      // First 4 rows: 2-2 configuration (16 seats)
      for (int row = 1; row <= 4; row++) {
        // Left side seats (2 seats)
        _seats.add(Seat(id: 'L${row}A', row: row, position: 'left-window'));
        _seats.add(Seat(id: 'L${row}B', row: row, position: 'left-aisle'));

        // Right side seats (2 seats)
        _seats.add(Seat(id: 'R${row}A', row: row, position: 'right-aisle'));
        _seats.add(Seat(id: 'R${row}B', row: row, position: 'right-window'));
      }
      
      // Last row (Row 5): 3-2 configuration (5 seats)
      _seats.add(Seat(id: 'L5A', row: 5, position: 'left-window'));
      _seats.add(Seat(id: 'L5B', row: 5, position: 'left-middle'));
      _seats.add(Seat(id: 'L5C', row: 5, position: 'left-aisle'));
      _seats.add(Seat(id: 'R5A', row: 5, position: 'right-aisle'));
      _seats.add(Seat(id: 'R5B', row: 5, position: 'right-window'));
    } else {
      // Initialize van seats with new layout (18 seats total)
      // 2 seats beside driver + 4 rows of 4 seats each = 18 seats

      // First row - beside driver (2 seats)
      _seats.add(Seat(id: 'D1A', row: 0, position: 'driver-right-window'));
      _seats.add(Seat(id: 'D1B', row: 0, position: 'driver-right-aisle'));

      // Regular rows (4 rows with 4 seats each)
      for (int row = 1; row <= 4; row++) {
        // Left side seats (2 seats)
        _seats.add(Seat(id: 'L${row}A', row: row, position: 'left-window'));
        _seats.add(Seat(id: 'L${row}B', row: row, position: 'left-aisle'));

        // Right side seats (2 seats)
        _seats.add(Seat(id: 'R${row}A', row: row, position: 'right-aisle'));
        _seats.add(Seat(id: 'R${row}B', row: row, position: 'right-window'));
      }
    }

    // Load reserved seats from Firebase if routeId is provided
    if (routeId != null) {
      try {
        // Get the active van for this route
        final activeVan = await _bookingService.getActiveVanForRoute(routeId);
        if (activeVan != null) {
          final reservedSeatIds = await _bookingService.getReservedSeats(
            routeId,
            activeVan.plateNumber,
            activeVan.driver.name,
          );

          // Mark reserved seats
          for (final seat in _seats) {
            if (reservedSeatIds.contains(seat.id)) {
              seat.isReserved = true;
              seat.isSelected = false; // Ensure reserved seats are not selected
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading reserved seats: $e');
        // Continue without reserved seats if there's an error
      }
    }

    _selectedSeats = _seats.where((seat) => seat.isSelected).toList();
    notifyListeners();
  }

  /// Refresh seat availability from Firebase
  Future<void> refreshSeatAvailability({String? routeId}) async {
    if (routeId == null) return;

    try {
      // Get the active van for this route
      final activeVan = await _bookingService.getActiveVanForRoute(routeId);
      if (activeVan != null) {
        final reservedSeatIds = await _bookingService.getReservedSeats(
          routeId,
          activeVan.plateNumber,
          activeVan.driver.name,
        );

        // Update seat reservation status
        for (final seat in _seats) {
          final wasReserved = seat.isReserved;
          seat.isReserved = reservedSeatIds.contains(seat.id);

          // If a seat was just reserved and was selected, deselect it
          if (!wasReserved && seat.isReserved && seat.isSelected) {
            seat.isSelected = false;
            seat.hasDiscount = false;
          }
        }

        // Update selected seats list
        _selectedSeats = _seats.where((seat) => seat.isSelected).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing seat availability: $e');
    }
  }

  bool canSelectSeat(Seat seat) {
    if (seat.isReserved) return false;
    if (seat.isSelected) return true; // Can deselect
    return _selectedSeats.length < maxSeatsPerBooking;
  }

  void toggleSeatSelection(String seatId) {
    final seatIndex = _seats.indexWhere((seat) => seat.id == seatId);
    if (seatIndex == -1) return;

    final seat = _seats[seatIndex];

    if (!canSelectSeat(seat) && !seat.isSelected) {
      // Cannot select more seats
      return;
    }

    seat.isSelected = !seat.isSelected;

    if (seat.isSelected) {
      _selectedSeats.add(seat);
    } else {
      _selectedSeats.removeWhere((s) => s.id == seatId);
      seat.hasDiscount = false; // Remove discount when deselected
    }

    notifyListeners();
  }

  void toggleSeatDiscount(String seatId) {
    final seat = _selectedSeats.firstWhere((s) => s.id == seatId);
    seat.hasDiscount = !seat.hasDiscount;
    notifyListeners();
  }

  double calculateTotalAmount() {
    double total = 0;
    for (final seat in _selectedSeats) {
      if (seat.hasDiscount) {
        total += _baseFare * (1 - _discountRate);
      } else {
        total += _baseFare;
      }
    }
    return total;
  }

  // Booking fee is a flat ₱15.00 per booking (not per seat)
  double get bookingFee => _selectedSeats.isNotEmpty ? 15.0 : 0.0;

  // Total amount including booking fee
  double calculateTotalAmountWithFee() {
    return calculateTotalAmount() + bookingFee;
  }

  double calculateDiscountAmount() {
    double discount = 0;
    for (final seat in _selectedSeats) {
      if (seat.hasDiscount) {
        discount += _baseFare * _discountRate;
      }
    }
    return discount;
  }

  int get regularFareSeats =>
      _selectedSeats.where((s) => !s.hasDiscount).length;
  int get discountedSeats => _selectedSeats.where((s) => s.hasDiscount).length;

  Future<void> clearSelection() async {
    for (final seat in _selectedSeats) {
      seat.isSelected = false;
      seat.hasDiscount = false;
    }
    _selectedSeats.clear();
    notifyListeners();
  }

  Future<void> reserveSelectedSeats() async {
    // Update local state
    for (final seat in _selectedSeats) {
      final seatIndex = _seats.indexWhere((s) => s.id == seat.id);
      if (seatIndex != -1) {
        _seats[seatIndex].isReserved = true;
        _seats[seatIndex].isSelected = false;
      }
    }

    _selectedSeats.clear();
    notifyListeners();
  }
}
