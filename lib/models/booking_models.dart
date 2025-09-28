import 'package:cloud_firestore/cloud_firestore.dart';

class Seat {
  final String id;
  final int row;
  final String position; // 'left-window', 'left-aisle', 'right-aisle', 'right-window'
  bool isReserved;
  bool isSelected;
  bool hasDiscount;
  
  Seat({
    required this.id,
    required this.row,
    required this.position,
    this.isReserved = false,
    this.isSelected = false,
    this.hasDiscount = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'position': position,
      'isReserved': isReserved,
      'isSelected': isSelected,
      'hasDiscount': hasDiscount,
    };
  }

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'],
      row: json['row'],
      position: json['position'],
      isReserved: json['isReserved'] ?? false,
      isSelected: json['isSelected'] ?? false,
      hasDiscount: json['hasDiscount'] ?? false,
    );
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum BookingStatus {
  active,
  completed,
  cancelled,
}

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime bookingDate;
  final List<String> seatIds;
  final int numberOfSeats;
  final double basePrice;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final String? qrCodeData;
  final String? eTicketId;
  final Map<String, dynamic>? passengerDetails;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.bookingDate,
    required this.seatIds,
    required this.numberOfSeats,
    required this.basePrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    this.qrCodeData,
    this.eTicketId,
    this.passengerDetails,
  });

  // Convert Booking to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'routeId': routeId,
      'routeName': routeName,
      'origin': origin,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'bookingDate': Timestamp.fromDate(bookingDate),
      'seatIds': seatIds,
      'numberOfSeats': numberOfSeats,
      'basePrice': basePrice,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.name,
      'bookingStatus': bookingStatus.name,
      'qrCodeData': qrCodeData,
      'eTicketId': eTicketId,
      'passengerDetails': passengerDetails,
    };
  }

  // Create Booking from Firestore Document
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      seatIds: List<String>.from(map['seatIds'] ?? []),
      numberOfSeats: map['numberOfSeats'] ?? 0,
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      bookingStatus: BookingStatus.values.firstWhere(
        (e) => e.name == map['bookingStatus'],
        orElse: () => BookingStatus.active,
      ),
      qrCodeData: map['qrCodeData'],
      eTicketId: map['eTicketId'],
      passengerDetails: map['passengerDetails'],
    );
  }

  // Create Booking from Firestore DocumentSnapshot
  factory Booking.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromMap({...data, 'id': doc.id});
  }
}

class Route {
  final String id;
  final String name;
  final String origin;
  final String destination;
  final double basePrice;
  final int estimatedDuration; // in minutes
  final List<String> waypoints;
  final bool isActive;

  Route({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.basePrice,
    required this.estimatedDuration,
    required this.waypoints,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'origin': origin,
      'destination': destination,
      'basePrice': basePrice,
      'estimatedDuration': estimatedDuration,
      'waypoints': waypoints,
      'isActive': isActive,
    };
  }

  factory Route.fromMap(Map<String, dynamic> map) {
    return Route(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      basePrice: (map['basePrice'] ?? 0).toDouble(),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      waypoints: List<String>.from(map['waypoints'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  factory Route.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Route.fromMap({...data, 'id': doc.id});
  }
}

class Schedule {
  final String id;
  final String routeId;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int availableSeats;
  final int totalSeats;
  final List<String> bookedSeats;
  final bool isActive;

  Schedule({
    required this.id,
    required this.routeId,
    required this.departureTime,
    required this.arrivalTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.bookedSeats,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'isActive': isActive,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] ?? '',
      routeId: map['routeId'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      arrivalTime: (map['arrivalTime'] as Timestamp).toDate(),
      availableSeats: map['availableSeats'] ?? 0,
      totalSeats: map['totalSeats'] ?? 0,
      bookedSeats: List<String>.from(map['bookedSeats'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  factory Schedule.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule.fromMap({...data, 'id': doc.id});
  }
}