import 'package:flutter/foundation.dart';
import '../models/booking_models.dart';

class SeatProvider with ChangeNotifier {
  List<Seat> _seats = [];
  List<Seat> _selectedSeats = [];
  final double _baseFare = 150.0;
  final double _discountRate = 0.1333; // 13.33%

  List<Seat> get seats => _seats;
  List<Seat> get selectedSeats => _selectedSeats;
  double get baseFare => _baseFare;
  double get discountRate => _discountRate;

  int get maxSeatsPerBooking => 5;

  Future<void> initializeSeats() async {
    // Initialize van seats with new layout (18 seats total)
    // 2 seats beside driver + 4 rows of 4 seats each = 18 seats
    _seats = [];
    
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
    _selectedSeats = _seats.where((seat) => seat.isSelected).toList();
    notifyListeners();
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

  double calculateDiscountAmount() {
    double discount = 0;
    for (final seat in _selectedSeats) {
      if (seat.hasDiscount) {
        discount += _baseFare * _discountRate;
      }
    }
    return discount;
  }

  int get regularFareSeats => _selectedSeats.where((s) => !s.hasDiscount).length;
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