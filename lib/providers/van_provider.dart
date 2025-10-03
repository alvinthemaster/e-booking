import 'package:flutter/material.dart';
import '../services/firebase_booking_service.dart';
import '../models/booking_models.dart';

class VanProvider with ChangeNotifier {
  final FirebaseBookingService _bookingService = FirebaseBookingService();

  List<Van> _vans = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Van> get vans => _vans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all vans from Firestore
  Future<void> loadVans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vans = await _bookingService.getActiveVans();
      debugPrint('VanProvider: Loaded ${_vans.length} vans');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error loading vans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new van
  Future<void> addVan(Van van) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create a new van with the proper queue position
      final updatedVan = Van(
        id: van.id,
        plateNumber: van.plateNumber,
        capacity: van.capacity,
        driver: van.driver,
        status: van.status,
        currentRouteId: van.currentRouteId,
        queuePosition: _vans.length + 1, // Set queue position
        currentOccupancy: van.currentOccupancy,
        isActive: van.isActive,
        lastMaintenance: van.lastMaintenance,
        nextMaintenance: van.nextMaintenance,
        createdAt: van.createdAt,
      );

      await _bookingService.createVan(updatedVan);
      await loadVans(); // Reload vans to get updated data

      debugPrint('VanProvider: Van ${van.plateNumber} added successfully');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error adding van: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update van status
  Future<void> updateVanStatus(String vanId, String status) async {
    try {
      await _bookingService.updateVanStatus(vanId, status);
      await loadVans(); // Reload vans to get updated data

      debugPrint('VanProvider: Van $vanId status updated to $status');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error updating van status: $e');
      rethrow;
    }
  }

  /// Move van to next position in queue
  Future<void> moveVanToNext(String vanId) async {
    try {
      final van = _vans.firstWhere((v) => v.id == vanId);
      if (van.queuePosition > 1) {
        await _bookingService.updateVanQueuePosition(
          vanId,
          van.queuePosition - 1,
        );
        await loadVans();
        debugPrint('VanProvider: Van $vanId moved up in queue');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error moving van in queue: $e');
      rethrow;
    }
  }

  /// Move van to end of queue
  Future<void> moveVanToEnd(String vanId) async {
    try {
      final maxPosition = _vans.isNotEmpty
          ? _vans.map((v) => v.queuePosition).reduce((a, b) => a > b ? a : b)
          : 1;
      await _bookingService.updateVanQueuePosition(vanId, maxPosition + 1);
      await loadVans();
      debugPrint('VanProvider: Van $vanId moved to end of queue');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error moving van to end: $e');
      rethrow;
    }
  }

  /// Delete van
  Future<void> deleteVan(String vanId) async {
    try {
      await _bookingService.deleteVan(vanId);
      await loadVans();
      debugPrint('VanProvider: Van $vanId deleted successfully');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error deleting van: $e');
      rethrow;
    }
  }

  /// Complete van trip - marks all bookings as completed and resets occupancy
  Future<void> completeVanTrip(String vanId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Complete all bookings for this van
      await _bookingService.completeAllBookingsForVan(vanId);
      
      // Reset van occupancy to 0
      await _bookingService.updateVanOccupancy(vanId, 0);
      
      // Reload vans to reflect changes
      await loadVans();
      
      debugPrint('VanProvider: Trip completed for van $vanId');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('VanProvider: Error completing van trip: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if van trip can be completed
  Future<bool> canCompleteTrip(String vanId) async {
    try {
      return await _bookingService.canCompleteTrip(vanId);
    } catch (e) {
      debugPrint('VanProvider: Error checking if trip can be completed: $e');
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
