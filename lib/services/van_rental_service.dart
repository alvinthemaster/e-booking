import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/van_rental_request_model.dart';
import '../models/rental_van_model.dart';

/// Service for managing Van Rental Requests in Firestore
class VanRentalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for van rental requests
  CollectionReference get _rentalRequestsCollection =>
      _firestore.collection('van_rental_requests');
  
  /// Collection reference for available rental vans
  CollectionReference get _rentalVansCollection =>
      _firestore.collection('rental_vans');

  /// Fetch van rental requests for the current user
  /// Returns a Stream for real-time updates
  Stream<List<VanRentalRequest>> getUserVanRentalRequests() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('VanRentalService: No authenticated user');
        return Stream.value([]);
      }

      debugPrint('VanRentalService: Fetching rental requests for user: ${user.uid}');

      return _rentalRequestsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        debugPrint('VanRentalService: Received ${snapshot.docs.length} rental requests');
        
        return snapshot.docs.map((doc) {
          try {
            return VanRentalRequest.fromDocument(doc);
          } catch (e) {
            debugPrint('VanRentalService: Error parsing document ${doc.id}: $e');
            // Return a minimal valid object to prevent crashes
            return VanRentalRequest(
              id: doc.id,
              userId: user.uid,
              userName: 'Unknown',
              userEmail: user.email ?? '',
              userPhone: '',
              vanId: '',
              brand: 'Unknown Van',
              vanPlateNumber: '',
              rentalStartDate: DateTime.now(),
              rentalEndDate: DateTime.now(),
              totalDays: 0,
              pricePerDay: 0.0,
              totalAmount: 0.0,
              pickupLocation: '',
              dropoffLocation: '',
              status: VanRentalStatus.pending,
              createdAt: DateTime.now(),
            );
          }
        }).toList();
      }).handleError((error) {
        debugPrint('VanRentalService: Stream error: $error');
        return <VanRentalRequest>[];
      });
    } catch (e) {
      debugPrint('VanRentalService: Error setting up stream: $e');
      return Stream.value([]);
    }
  }

  /// Fetch a single van rental request by ID
  Future<VanRentalRequest?> getVanRentalRequestById(String requestId) async {
    try {
      final doc = await _rentalRequestsCollection.doc(requestId).get();
      
      if (!doc.exists) {
        debugPrint('VanRentalService: Request $requestId not found');
        return null;
      }

      return VanRentalRequest.fromDocument(doc);
    } catch (e) {
      debugPrint('VanRentalService: Error fetching request $requestId: $e');
      return null;
    }
  }

  /// Fetch all van rental requests for the current user (one-time fetch)
  Future<List<VanRentalRequest>> getUserVanRentalRequestsOnce() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('VanRentalService: No authenticated user');
        return [];
      }

      debugPrint('VanRentalService: Fetching rental requests once for user: ${user.uid}');

      // Simple query without orderBy to avoid requiring a composite index
      final snapshot = await _rentalRequestsCollection
          .where('userId', isEqualTo: user.uid)
          .get();

      debugPrint('VanRentalService: Found ${snapshot.docs.length} rental requests');

      final requests = snapshot.docs.map((doc) {
        try {
          return VanRentalRequest.fromDocument(doc);
        } catch (e) {
          debugPrint('VanRentalService: Error parsing document ${doc.id}: $e');
          // Return a minimal valid object to prevent crashes
          return VanRentalRequest(
            id: doc.id,
            userId: user.uid,
            userName: 'Unknown',
            userEmail: user.email ?? '',
            userPhone: '',
            vanId: '',
            brand: 'Unknown Van',
            vanPlateNumber: '',
            rentalStartDate: DateTime.now(),
            rentalEndDate: DateTime.now(),
            totalDays: 0,
            pricePerDay: 0.0,
            totalAmount: 0.0,
            pickupLocation: '',
            dropoffLocation: '',
            status: VanRentalStatus.pending,
            createdAt: DateTime.now(),
          );
        }
      }).toList();

      // Sort in memory (newest first) to avoid needing a composite index
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      debugPrint('VanRentalService: Error fetching rental requests: $e');
      
      // Check if it's a permission error
      if (e.toString().contains('permission') || 
          e.toString().contains('PERMISSION_DENIED')) {
        debugPrint('VanRentalService: Permission denied - check Firestore rules');
      }
      
      return [];
    }
  }

  /// Create a new van rental request (for future use)
  Future<String?> createVanRentalRequest(VanRentalRequest request) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _rentalRequestsCollection.doc();
      final requestId = docRef.id;

      final requestWithId = VanRentalRequest(
        id: requestId,
        userId: request.userId,
        userName: request.userName,
        userEmail: request.userEmail,
        userPhone: request.userPhone,
        vanId: request.vanId,
        brand: request.brand,
        vanPlateNumber: request.vanPlateNumber,
        rentalStartDate: request.rentalStartDate,
        rentalEndDate: request.rentalEndDate,
        totalDays: request.totalDays,
        pricePerDay: request.pricePerDay,
        totalAmount: request.totalAmount,
        pickupLocation: request.pickupLocation,
        dropoffLocation: request.dropoffLocation,
        purpose: request.purpose,
        specialRequirements: request.specialRequirements,
        status: request.status,
        createdAt: DateTime.now(),
      );

      await docRef.set(requestWithId.toMap());
      debugPrint('VanRentalService: Created rental request: $requestId');

      return requestId;
    } catch (e) {
      debugPrint('VanRentalService: Error creating rental request: $e');
      return null;
    }
  }

  /// Update van rental request status
  Future<bool> updateVanRentalRequestStatus(
    String requestId,
    VanRentalStatus newStatus,
  ) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
      };

      // Add timestamp fields based on status
      switch (newStatus) {
        case VanRentalStatus.approved:
          updates['approvedAt'] = FieldValue.serverTimestamp();
          break;
        case VanRentalStatus.confirmed:
          updates['confirmedAt'] = FieldValue.serverTimestamp();
          break;
        case VanRentalStatus.completed:
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case VanRentalStatus.cancelled:
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        case VanRentalStatus.rejected:
          updates['rejectedAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _rentalRequestsCollection.doc(requestId).update(updates);
      debugPrint('VanRentalService: Updated request $requestId status to ${newStatus.name}');

      return true;
    } catch (e) {
      debugPrint('VanRentalService: Error updating request status: $e');
      return false;
    }
  }

  /// Cancel a van rental request
  Future<bool> cancelVanRentalRequest(
    String requestId,
    String cancellationReason,
  ) async {
    try {
      await _rentalRequestsCollection.doc(requestId).update({
        'status': VanRentalStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': cancellationReason,
      });

      debugPrint('VanRentalService: Cancelled request $requestId');
      return true;
    } catch (e) {
      debugPrint('VanRentalService: Error cancelling request: $e');
      return false;
    }
  }

  /// Check if the collection exists and has data
  Future<bool> checkCollectionExists() async {
    try {
      final snapshot = await _rentalRequestsCollection.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('VanRentalService: Error checking collection: $e');
      return false;
    }
  }

  // ============ RENTAL VANS (AVAILABLE FOR RENT) ============

  /// Fetch all available rental vans
  Future<List<RentalVan>> getAvailableRentalVans() async {
    try {
      debugPrint('VanRentalService: Fetching available rental vans from collection: rental_vans');

      // Fetch all vans without compound query to avoid index requirements
      // Filter isAvailable in memory (also treats missing field as available)
      final snapshot = await _rentalVansCollection.get();

      debugPrint('VanRentalService: Total docs in rental_vans: ${snapshot.docs.length}');

      final vans = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          debugPrint('VanRentalService: Parsing van doc ${doc.id}: isAvailable=${data["isAvailable"]}');
          return RentalVan.fromDocument(doc);
        } catch (e) {
          debugPrint('VanRentalService: Error parsing van ${doc.id}: $e');
          return RentalVan(
            id: doc.id,
            vanName: 'Unknown Van',
            plateNumber: '',
            description: '',
            pricePerDay: 0.0,
            capacity: 0,
            vehicleType: 'Van',
            amenities: [],
            imageUrls: [],
            isAvailable: true,
            blockedDates: [],
            createdAt: DateTime.now(),
          );
        }
      }).toList();

      // Filter: show vans where isAvailable is true OR not set (null)
      final availableVans = vans.where((van) => van.isAvailable).toList();

      // Additionally exclude vans that have an active/approved/confirmed rental request
      // by fetching all approved/confirmed/active requests and collecting their vanIds
      try {
        final activeStatuses = [
          VanRentalStatus.approved.name,
          VanRentalStatus.confirmed.name,
          VanRentalStatus.active.name,
        ];
        final requestSnapshot = await _rentalRequestsCollection
            .where('status', whereIn: activeStatuses)
            .get();
        final bookedVanIds = requestSnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['vanId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        debugPrint('VanRentalService: Booked van IDs (active requests): $bookedVanIds');

        // Remove vans that are already rented
        availableVans.removeWhere((van) => bookedVanIds.contains(van.id));
      } catch (e) {
        // If request fetch fails, still show vans filtered by isAvailable
        debugPrint('VanRentalService: Could not fetch active requests for exclusion: $e');
      }

      // Sort by createdAt descending
      availableVans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('VanRentalService: Found ${availableVans.length} available vans out of ${vans.length} total');
      return availableVans;
    } catch (e) {
      debugPrint('VanRentalService: Error fetching rental vans: $e');
      return [];
    }
  }

  /// Fetch all rental vans (including unavailable)
  Future<List<RentalVan>> getAllRentalVans() async {
    try {
      debugPrint('VanRentalService: Fetching all rental vans');

      final snapshot = await _rentalVansCollection.get();

      debugPrint('VanRentalService: Found ${snapshot.docs.length} rental vans');

      return snapshot.docs.map((doc) {
        try {
          return RentalVan.fromDocument(doc);
        } catch (e) {
          debugPrint('VanRentalService: Error parsing van ${doc.id}: $e');
          return RentalVan(
            id: doc.id,
            vanName: 'Unknown Van',
            plateNumber: '',
            description: '',
            pricePerDay: 0.0,
            capacity: 0,
            vehicleType: 'Van',
            amenities: [],
            imageUrls: [],
            isAvailable: true,
            blockedDates: [],
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      debugPrint('VanRentalService: Error fetching all rental vans: $e');
      return [];
    }
  }

  /// Fetch the set of van IDs that currently have an active/approved/confirmed request
  Future<Set<String>> getBookedVanIds() async {
    try {
      final activeStatuses = [
        VanRentalStatus.approved.name,
        VanRentalStatus.confirmed.name,
        VanRentalStatus.active.name,
      ];
      final snapshot = await _rentalRequestsCollection
          .where('status', whereIn: activeStatuses)
          .get();
      return snapshot.docs
          .map((doc) =>
              (doc.data() as Map<String, dynamic>)['vanId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('VanRentalService: Error fetching booked van IDs: $e');
      return {};
    }
  }

  /// Get rental vans stream for real-time updates
  Stream<List<RentalVan>> getRentalVansStream() {
    try {
      return _rentalVansCollection
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return RentalVan.fromDocument(doc);
          } catch (e) {
            debugPrint('VanRentalService: Error parsing van ${doc.id}: $e');
            return RentalVan(
              id: doc.id,
              vanName: 'Unknown Van',
              plateNumber: '',
              description: '',
              pricePerDay: 0.0,
              capacity: 0,
              vehicleType: 'Van',
              amenities: [],
              imageUrls: [],
              isAvailable: true,
              blockedDates: [],
              createdAt: DateTime.now(),
            );
          }
        }).toList();
      });
    } catch (e) {
      debugPrint('VanRentalService: Error setting up vans stream: $e');
      return Stream.value([]);
    }
  }

  /// Get a single rental van by ID
  Future<RentalVan?> getRentalVanById(String vanId) async {
    try {
      final doc = await _rentalVansCollection.doc(vanId).get();
      
      if (!doc.exists) {
        debugPrint('VanRentalService: Van $vanId not found');
        return null;
      }

      return RentalVan.fromDocument(doc);
    } catch (e) {
      debugPrint('VanRentalService: Error fetching van $vanId: $e');
      return null;
    }
  }
}
