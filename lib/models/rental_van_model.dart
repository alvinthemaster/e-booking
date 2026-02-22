import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Available Rental Vans
class RentalVan {
  final String id;
  final String? vanId; // Additional ID field from Firestore
  final String vanName;
  final String plateNumber;
  final String description;
  final double pricePerDay;
  final int capacity;
  final String vehicleType; // e.g., 'Van', 'Bus', 'Coaster'
  final String? brand; // Van brand/manufacturer
  final String? color; // Van color
  final List<String> amenities; // e.g., ['Air Conditioned', 'WiFi', 'GPS']
  final List<String> imageUrls;
  final bool isAvailable;
  final String? pickupLocation; // Where to pickup the van
  final DateTime? availableFrom; // Start date of availability
  final DateTime? availableTo; // End date of availability
  final List<DateTime> blockedDates; // Dates when van is not available
  final int? minRentalDays; // Minimum rental period
  final int? maxRentalDays; // Maximum rental period
  final String? adminNotes; // Admin-only notes
  final DateTime createdAt;
  final DateTime? lastUpdated;

  RentalVan({
    required this.id,
    this.vanId,
    required this.vanName,
    required this.plateNumber,
    required this.description,
    required this.pricePerDay,
    required this.capacity,
    required this.vehicleType,
    this.brand,
    this.color,
    required this.amenities,
    required this.imageUrls,
    required this.isAvailable,
    this.pickupLocation,
    this.availableFrom,
    this.availableTo,
    required this.blockedDates,
    this.minRentalDays,
    this.maxRentalDays,
    this.adminNotes,
    required this.createdAt,
    this.lastUpdated,
  });

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vanId': vanId,
      'vanName': vanName,
      'plateNumber': plateNumber,
      'description': description,
      'pricePerDay': pricePerDay,
      'capacity': capacity,
      'vehicleType': vehicleType,
      'brand': brand,
      'color': color,
      'amenities': amenities,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'pickupLocation': pickupLocation,
      'availableFrom': availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableTo': availableTo != null ? Timestamp.fromDate(availableTo!) : null,
      'blockedDates': blockedDates.map((date) => Timestamp.fromDate(date)).toList(),
      'minRentalDays': minRentalDays,
      'maxRentalDays': maxRentalDays,
      'adminNotes': adminNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  /// Create from Map with null-safe parsing
  factory RentalVan.fromMap(Map<String, dynamic> map) {
    try {
      return RentalVan(
        id: map['id'] as String? ?? '',
        vanId: map['vanId'] as String?,
        vanName: map['vanName'] as String? ?? 'Unknown Van',
        plateNumber: map['plateNumber'] as String? ?? '',
        description: map['description'] as String? ?? '',
        pricePerDay: (map['pricePerDay'] as num? ?? 0.0).toDouble(),
        capacity: (map['capacity'] as num? ?? 0).toInt(),
        vehicleType: map['vehicleType'] as String? ?? 'Van',
        brand: map['brand'] as String?,
        color: map['color'] as String?,
        amenities: List<String>.from(map['amenities'] as List? ?? []),
        imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
        isAvailable: map['isAvailable'] as bool? ?? true,
        pickupLocation: map['pickupLocation'] as String?,
        availableFrom: map['availableFrom'] != null ? _parseTimestamp(map['availableFrom']) : null,
        availableTo: map['availableTo'] != null ? _parseTimestamp(map['availableTo']) : null,
        blockedDates: _parseBlockedDates(map['blockedDates']),
        minRentalDays: map['minRentalDays'] as int?,
        maxRentalDays: map['maxRentalDays'] as int?,
        adminNotes: map['adminNotes'] as String?,
        createdAt: _parseTimestamp(map['createdAt']),
        lastUpdated: map['lastUpdated'] != null ? _parseTimestamp(map['lastUpdated']) : null,
      );
    } catch (e) {
      // Return default object if parsing fails
      return RentalVan(
        id: map['id'] as String? ?? '',
        vanId: map['vanId'] as String?,
        vanName: map['vanName'] as String? ?? 'Unknown Van',
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
  }

  /// Create from Firestore DocumentSnapshot
  factory RentalVan.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RentalVan.fromMap({...data, 'id': doc.id});
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

  /// Parse blocked dates from various formats
  static List<DateTime> _parseBlockedDates(dynamic blockedDates) {
    if (blockedDates == null) return [];
    
    try {
      if (blockedDates is List) {
        return blockedDates.map((date) {
          if (date is Timestamp) {
            return date.toDate();
          } else if (date is DateTime) {
            return date;
          } else if (date is String) {
            return DateTime.tryParse(date) ?? DateTime.now();
          } else {
            return DateTime.now();
          }
        }).toList();
      }
    } catch (e) {
      return [];
    }
    
    return [];
  }

  /// Get capacity display string
  String get capacityDisplay => '$capacity ${capacity == 1 ? 'passenger' : 'passengers'}';

  /// Get amenities as comma-separated string
  String get amenitiesDisplay => amenities.isEmpty ? 'Standard' : amenities.join(', ');

  /// Check if a date is blocked
  bool isDateBlocked(DateTime date) {
    return blockedDates.any((blocked) => 
      blocked.year == date.year &&
      blocked.month == date.month &&
      blocked.day == date.day
    );
  }

  /// Check if rental period is within allowed range
  bool isRentalPeriodValid(int days) {
    if (minRentalDays != null && days < minRentalDays!) return false;
    if (maxRentalDays != null && days > maxRentalDays!) return false;
    return true;
  }

  /// Get rental period display string
  String get rentalPeriodDisplay {
    if (minRentalDays != null && maxRentalDays != null) {
      return '$minRentalDays-$maxRentalDays days';
    } else if (minRentalDays != null) {
      return 'Min $minRentalDays days';
    } else if (maxRentalDays != null) {
      return 'Max $maxRentalDays days';
    } else {
      return 'Flexible';
    }
  }
}
