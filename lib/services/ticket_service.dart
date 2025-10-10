import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Hosting URL for QR confirmation
  static const String _hostingUrl = 'https://e-ticket-2e8d0.web.app';

  /// Generate a ticket document in Firestore and return QR URL
  Future<String> generateTicket({
    required String bookingId,
    required String passengerName,
    required List<String> seatNumbers,
    required String origin,
    required String destination,
    required String vanPlateNumber,
    required String driverName,
    required DateTime bookingDate,
    required double totalAmount,
  }) async {
    try {
      // Generate unique ticket ID
      final ticketRef = _firestore.collection('tickets').doc();
      final ticketId = ticketRef.id;

      // Create ticket document
      final ticketData = {
        'ticketId': ticketId,
        'bookingId': bookingId,
        'passengerName': passengerName,
        'seatNumbers': seatNumbers,
        'origin': origin,
        'destination': destination,
        'vanPlateNumber': vanPlateNumber,
        'driverName': driverName,
        'bookingDate': Timestamp.fromDate(bookingDate),
        'totalAmount': totalAmount,
        'status': 'pending', // pending, confirmed, expired
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid,
        'qrUrl': '$_hostingUrl?id=$ticketId',
      };

      // Save to Firestore
      await ticketRef.set(ticketData);

      // Return QR URL
      return '$_hostingUrl?id=$ticketId';
    } catch (e) {
      throw Exception('Failed to generate ticket: $e');
    }
  }

  /// Update ticket status
  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  /// Get ticket by ID
  Future<Map<String, dynamic>?> getTicket(String ticketId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ticket: $e');
    }
  }

  /// Get tickets for a user
  Stream<QuerySnapshot> getUserTickets(String userId) {
    return _firestore
        .collection('tickets')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Check if ticket is valid and not expired
  bool isTicketValid(Map<String, dynamic> ticketData) {
    final status = ticketData['status'] as String?;
    final bookingDate = (ticketData['bookingDate'] as Timestamp?)?.toDate();
    
    if (status == 'expired' || status == 'confirmed') {
      return false;
    }

    // Check if booking date is in the future or today
    if (bookingDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final bookingDay = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
      
      return bookingDay.isAtSameMomentAs(today) || bookingDay.isAfter(today);
    }

    return true;
  }

  /// Generate QR URL for existing booking
  Future<String> generateQrForBooking(String bookingId) async {
    try {
      // Check if ticket already exists for this booking
      final existingTickets = await _firestore
          .collection('tickets')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existingTickets.docs.isNotEmpty) {
        final ticketData = existingTickets.docs.first.data();
        return ticketData['qrUrl'] as String;
      }

      // Get booking data
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;
      
      // Generate new ticket
      return await generateTicket(
        bookingId: bookingId,
        passengerName: bookingData['passengerName'] ?? 'Unknown',
        seatNumbers: List<String>.from(bookingData['seatNumbers'] ?? []),
        origin: bookingData['origin'] ?? 'Unknown',
        destination: bookingData['destination'] ?? 'Unknown',
        vanPlateNumber: bookingData['vanPlateNumber'] ?? 'Unknown',
        driverName: bookingData['driverName'] ?? 'Unknown',
        bookingDate: (bookingData['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        totalAmount: (bookingData['totalAmount'] ?? 0).toDouble(),
      );
    } catch (e) {
      throw Exception('Failed to generate QR for booking: $e');
    }
  }
}