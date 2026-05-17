import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/document_delivery_model.dart';

/// Service for managing Document Delivery records in Firestore.
///
/// Uses the [document_deliveries] top-level collection, keeping it fully
/// separate from the existing [bookings] collection so that normal booking
/// logic is never affected.
class DocumentDeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name must exactly match what is in Firebase Firestore
  CollectionReference get _deliveriesCollection =>
      _firestore.collection('document_deliveries');

    CollectionReference get _auditCollection =>
      _firestore.collection('delivery_audit_logs');

  /// Persist a new [DocumentDelivery] to Firestore.
  ///
  /// Returns the Firestore document ID of the created record.
  Future<String> createDelivery(DocumentDelivery delivery) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Auto-generate a document ID
      final docRef = _deliveriesCollection.doc();
      final deliveryWithId = DocumentDelivery(
        id: docRef.id,
        userId: user.uid,
        routeId: delivery.routeId,
        routeName: delivery.routeName,
        origin: delivery.origin,
        destination: delivery.destination,
        senderName: delivery.senderName,
        senderContact: delivery.senderContact,
        receiverName: delivery.receiverName,
        receiverContact: delivery.receiverContact,
        documentType: delivery.documentType,
        documentTypeNote: delivery.documentTypeNote,
        createdAt: DateTime.now(),
        status: DeliveryStatus.pending,
        paymentMethod: delivery.paymentMethod,
        deliveryFee: delivery.deliveryFee,
        bookingFee: delivery.bookingFee,
        paymentAmount: delivery.paymentAmount,
        paymentStatus: delivery.paymentStatus,
        proofOfPaymentBase64: delivery.proofOfPaymentBase64,
        proofOfPaymentFileName: delivery.proofOfPaymentFileName,
        receiverType: delivery.receiverType,
        specifyRelationship: delivery.specifyRelationship,
        claimedByName: delivery.claimedByName,
        proofOfReceiptBase64: delivery.proofOfReceiptBase64,
        proofOfReceiptFileName: delivery.proofOfReceiptFileName,
        completedAt: delivery.completedAt,
        vanPlateNumber: delivery.vanPlateNumber,
        vanDriverName: delivery.vanDriverName,
        tripId: delivery.tripId,
      );

      await docRef.set(deliveryWithId.toMap());

      debugPrint('✅ Document delivery created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating document delivery: $e');
      rethrow;
    }
  }

  /// Fetch all document deliveries for the currently authenticated user,
  /// ordered by creation date (newest first).
  Future<List<DocumentDelivery>> getUserDeliveries() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _deliveriesCollection
          .where('userId', isEqualTo: user.uid)
          .get();

      final list = snapshot.docs
          .map((doc) =>
              DocumentDelivery.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching document deliveries: $e');
      rethrow;
    }
  }

  /// Stream all document deliveries for the current user, newest first.
  /// Uses authStateChanges() so it waits for Firebase Auth to restore on web
  /// (avoids returning empty while currentUser is temporarily null on startup).
  Stream<List<DocumentDelivery>> streamUserDeliveries() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return const Stream.empty();

      return _deliveriesCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => DocumentDelivery.fromMap(
                    doc.data() as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            debugPrint(
                '📦 streamUserDeliveries: ${list.length} deliveries for ${user.uid}');
            return list;
          });
    });
  }

  /// Stream whether there is at least one active (pending/inTransit) delivery
  /// assigned to [routeId]. Used to show the document icon on the seat map.
  Stream<bool> streamHasActiveDeliveryForRoute(String routeId) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(false);

      return _deliveriesCollection
          .where('routeId', isEqualTo: routeId)
          .where('status', whereIn: [
            DeliveryStatus.pending.name,
            DeliveryStatus.inTransit.name,
            DeliveryStatus.arrived.name,
          ])
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);
    });
  }

  /// Update the status of an existing delivery.
  Future<void> updateDeliveryStatus(
      String deliveryId, DeliveryStatus newStatus) async {
    try {
      await _deliveriesCollection.doc(deliveryId).update({
        'status': newStatus.name,
      });
      debugPrint('✅ Delivery $deliveryId status updated to ${newStatus.name}');
    } catch (e) {
      debugPrint('❌ Error updating delivery status: $e');
      rethrow;
    }
  }

  Stream<List<DocumentDelivery>> streamDeliveriesForVan(String plateNumber) {
    return _deliveriesCollection
        .where('vanPlateNumber', isEqualTo: plateNumber)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DocumentDelivery.fromMap(doc.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addAuditLog({
    required String deliveryId,
    required String action,
    required bool success,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    await _auditCollection.add({
      'deliveryId': deliveryId,
      'action': action,
      'success': success,
      'message': message,
      'metadata': metadata ?? {},
      'actorUserId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeDelivery({
    required String deliveryId,
    required String receiverType,
    String? specifyRelationship,
    required String claimedByName,
    required String proofOfReceiptBase64,
    required String proofOfReceiptFileName,
  }) async {
    await _deliveriesCollection.doc(deliveryId).update({
      'status': DeliveryStatus.delivered.name,
      'paymentStatus': 'paid',
      'receiverType': receiverType,
      'specifyRelationship': specifyRelationship,
      'claimedByName': claimedByName,
      'proofOfReceiptBase64': proofOfReceiptBase64,
      'proofOfReceiptFileName': proofOfReceiptFileName,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
