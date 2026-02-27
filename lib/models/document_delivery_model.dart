import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported document types for delivery
enum DocumentType {
  envelope,
  legalDocument,
  id,
  parcel,
  other;

  /// Human-readable label used in UI dropdowns
  String get label {
    switch (this) {
      case DocumentType.envelope:
        return 'Envelope';
      case DocumentType.legalDocument:
        return 'Legal Document';
      case DocumentType.id:
        return 'ID / Government Document';
      case DocumentType.parcel:
        return 'Parcel / Package';
      case DocumentType.other:
        return 'Other';
    }
  }

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.other,
    );
  }
}

/// Delivery status lifecycle
enum DeliveryStatus {
  pending,
  inTransit,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  static DeliveryStatus fromString(String value) {
    return DeliveryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeliveryStatus.pending,
    );
  }
}

/// Model representing a document delivery request
class DocumentDelivery {
  final String id;
  final String userId;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;

  // Sender details
  final String senderName;
  final String senderContact;

  // Receiver details
  final String receiverName;
  final String receiverContact;

  // Document details
  final DocumentType documentType;
  final String? documentTypeNote; // extra description when 'other'

  // Metadata
  final DateTime createdAt;
  final DeliveryStatus status;

  // Payment info
  final String paymentMethod;  // 'GCash' | 'Physical Payment'
  final double paymentAmount;  // delivery fee
  final String paymentStatus; // 'pending' | 'paid'

  // Linked trip info (optional – filled when a specific van/trip is chosen)
  final String? vanPlateNumber;
  final String? vanDriverName;
  final String? tripId;

  const DocumentDelivery({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.senderName,
    required this.senderContact,
    required this.receiverName,
    required this.receiverContact,
    required this.documentType,
    required this.createdAt,
    this.documentTypeNote,
    this.status = DeliveryStatus.pending,
    this.paymentMethod = 'Physical Payment',
    this.paymentAmount = 115.0,
    this.paymentStatus = 'pending',
    this.vanPlateNumber,
    this.vanDriverName,
    this.tripId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'routeId': routeId,
      'routeName': routeName,
      'origin': origin,
      'destination': destination,
      'senderName': senderName,
      'senderContact': senderContact,
      'receiverName': receiverName,
      'receiverContact': receiverContact,
      'documentType': documentType.name,
      'documentTypeNote': documentTypeNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'paymentMethod': paymentMethod,
      'paymentAmount': paymentAmount,
      'paymentStatus': paymentStatus,
      'vanPlateNumber': vanPlateNumber,
      'vanDriverName': vanDriverName,
      'tripId': tripId,
    };
  }

  factory DocumentDelivery.fromMap(Map<String, dynamic> map) {
    return DocumentDelivery(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      routeId: map['routeId'] ?? '',
      routeName: map['routeName'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      senderName: map['senderName'] ?? '',
      senderContact: map['senderContact'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverContact: map['receiverContact'] ?? '',
      documentType: DocumentType.fromString(map['documentType'] ?? ''),
      documentTypeNote: map['documentTypeNote'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: DeliveryStatus.fromString(map['status'] ?? ''),
      paymentMethod: map['paymentMethod'] ?? 'Physical Payment',
      paymentAmount: (map['paymentAmount'] as num?)?.toDouble() ?? 115.0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      vanPlateNumber: map['vanPlateNumber'],
      vanDriverName: map['vanDriverName'],
      tripId: map['tripId'],
    );
  }
}
