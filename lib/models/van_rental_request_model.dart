import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for van rental request status
enum VanRentalStatus {
  pending,
  approved,
  confirmed,
  active,
  completed,
  cancelled,
  rejected,
}

/// Model for Van Rental Request
class VanRentalRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  
  // Van details
  final String vanId;
  final String brand;
  final String vanPlateNumber;
  
  // Rental details
  final DateTime rentalStartDate;
  final DateTime rentalEndDate;
  final int totalDays;
  final double pricePerDay;
  final double totalAmount;
  
  // Location details
  final String pickupLocation;
  final String dropoffLocation;
  
  // Additional details
  final String? purpose;
  final String? specialRequirements;
  
  // Status and timestamps
  final VanRentalStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  VanRentalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.vanId,
    required this.brand,
    required this.vanPlateNumber,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.totalDays,
    required this.pricePerDay,
    required this.totalAmount,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.purpose,
    this.specialRequirements,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Convert Van Rental Request to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'vanId': vanId,
      'brand': brand,
      'vanPlateNumber': vanPlateNumber,
      'rentalStartDate': Timestamp.fromDate(rentalStartDate),
      'rentalEndDate': Timestamp.fromDate(rentalEndDate),
      'totalDays': totalDays,
      'pricePerDay': pricePerDay,
      'totalAmount': totalAmount,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'purpose': purpose,
      'specialRequirements': specialRequirements,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  /// Create Van Rental Request from Firestore Map with null-safe parsing
  factory VanRentalRequest.fromMap(Map<String, dynamic> map) {
    try {
      return VanRentalRequest(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? '',
        userEmail: map['userEmail'] as String? ?? '',
        userPhone: map['userPhone'] as String? ?? '',
        vanId: map['vanId'] as String? ?? '',
        brand: map['brand'] as String? ?? '',
        vanPlateNumber: map['vanPlateNumber'] as String? ?? '',
        rentalStartDate: _parseTimestamp(map['rentalStartDate']),
        rentalEndDate: _parseTimestamp(map['rentalEndDate']),
        totalDays: (map['totalDays'] as num? ?? 0).toInt(),
        pricePerDay: (map['pricePerDay'] as num? ?? 0.0).toDouble(),
        totalAmount: (map['totalAmount'] as num? ?? 0.0).toDouble(),
        pickupLocation: map['pickupLocation'] as String? ?? '',
        dropoffLocation: map['dropoffLocation'] as String? ?? '',
        purpose: map['purpose'] as String?,
        specialRequirements: map['specialRequirements'] as String?,
        status: _parseStatus(map['status']),
        createdAt: _parseTimestamp(map['createdAt']),
        confirmedAt: map['confirmedAt'] != null ? _parseTimestamp(map['confirmedAt']) : null,
        completedAt: map['completedAt'] != null ? _parseTimestamp(map['completedAt']) : null,
        cancelledAt: map['cancelledAt'] != null ? _parseTimestamp(map['cancelledAt']) : null,
        cancellationReason: map['cancellationReason'] as String?,
      );
    } catch (e) {
      // If parsing fails, return a default object to prevent crashes
      return VanRentalRequest(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? 'Unknown',
        userEmail: map['userEmail'] as String? ?? '',
        userPhone: map['userPhone'] as String? ?? '',
        vanId: map['vanId'] as String? ?? '',
        brand: map['brand'] as String? ?? 'Unknown Van',
        vanPlateNumber: map['vanPlateNumber'] as String? ?? '',
        rentalStartDate: DateTime.now(),
        rentalEndDate: DateTime.now(),
        totalDays: 0,
        pricePerDay: 0.0,
        totalAmount: 0.0,
        pickupLocation: map['pickupLocation'] as String? ?? '',
        dropoffLocation: map['dropoffLocation'] as String? ?? '',
        status: VanRentalStatus.pending,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Create Van Rental Request from Firestore DocumentSnapshot
  factory VanRentalRequest.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VanRentalRequest.fromMap({...data, 'id': doc.id});
  }

  /// Safely parse Timestamp to DateTime
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  /// Safely parse status string to enum
  static VanRentalStatus _parseStatus(dynamic status) {
    if (status == null) return VanRentalStatus.pending;
    
    final statusStr = status.toString().toLowerCase();
    return VanRentalStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusStr,
      orElse: () => VanRentalStatus.pending,
    );
  }

  /// Get formatted date range string
  String get dateRangeFormatted {
    final startFormatted = '${rentalStartDate.day}/${rentalStartDate.month}/${rentalStartDate.year}';
    final endFormatted = '${rentalEndDate.day}/${rentalEndDate.month}/${rentalEndDate.year}';
    return '$startFormatted - $endFormatted';
  }

  /// Get status display text
  String get statusDisplay {
    switch (status) {
      case VanRentalStatus.pending:
        return 'Pending';
      case VanRentalStatus.approved:
        return 'Approved';
      case VanRentalStatus.confirmed:
        return 'Confirmed';
      case VanRentalStatus.active:
        return 'Active';
      case VanRentalStatus.completed:
        return 'Completed';
      case VanRentalStatus.cancelled:
        return 'Cancelled';
      case VanRentalStatus.rejected:
        return 'Rejected';
    }
  }
}
