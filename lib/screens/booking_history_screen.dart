import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/booking_provider.dart';
import '../models/booking_models.dart';
import '../models/document_delivery_model.dart';
import '../services/document_delivery_service.dart';
import 'eticket_screen.dart';
import 'delivery_eticket_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final DocumentDeliveryService _deliveryService = DocumentDeliveryService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt, size: 18), text: 'All'),
            Tab(icon: Icon(Icons.event_seat, size: 18), text: 'Normal'),
            Tab(icon: Icon(Icons.description, size: 18), text: 'Documents'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bookings or deliveries...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          Provider.of<BookingProvider>(context, listen: false)
                              .searchBookings('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
                Provider.of<BookingProvider>(context, listen: false)
                    .searchBookings(value);
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllTab(
                    searchQuery: _searchQuery,
                    deliveryService: _deliveryService,
                    onBuildBookingCard: _buildBookingCard,
                    onBuildDeliveryCard: _buildDeliveryCard),
                _NormalTab(onBuildBookingCard: _buildBookingCard),
                _DocumentsTab(
                    deliveryService: _deliveryService,
                    onBuildDeliveryCard: _buildDeliveryCard),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ETicketScreen(bookingId: booking.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_seat,
                                color: Color(0xFF2196F3), size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Normal Booking',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.id,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(booking.bookingDate),
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statusBadge(
                        _getPaymentStatusText(booking.paymentStatus),
                        _getPaymentStatusColor(booking.paymentStatus),
                        _getPaymentStatusIcon(booking.paymentStatus),
                      ),
                      const SizedBox(height: 6),
                      _statusBadge(
                        _getBookingStatusText(booking.bookingStatus),
                        _getBookingStatusColor(booking.bookingStatus),
                        _getBookingStatusIcon(booking.bookingStatus),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _infoColumn(
                      'Passenger',
                      booking.passengerDetails?['name'] ?? booking.userName,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _infoColumn(
                      'Seats',
                      booking.seatIds.join(', '),
                      valueColor: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _routeBox(booking.origin, booking.destination),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Method',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_getPaymentMethodIcon(booking.paymentMethod),
                              size: 16, color: const Color(0xFF2196F3)),
                          const SizedBox(width: 4),
                          Text(booking.paymentMethod,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total Amount',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FaIcon(FontAwesomeIcons.pesoSign,
                              size: 14, color: const Color(0xFF2196F3)),
                          Text(
                            booking.totalAmount.toStringAsFixed(2),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (booking.discountAmount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.local_offer,
                        size: 14, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 4),
                    Text('Saved ',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500)),
                    FaIcon(FontAwesomeIcons.pesoSign,
                        size: 10, color: const Color(0xFF4CAF50)),
                    Text(
                      booking.discountAmount.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (booking.bookingStatus == BookingStatus.failed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final provider = Provider.of<BookingProvider>(
                              context,
                              listen: false);
                          try {
                            final vans =
                                await provider.getBoardingVans(booking.routeId);
                            if (vans.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No boarding vans available for rebooking')));
                              return;
                            }
                            final Van? selected =
                                await showModalBottomSheet<Van?>(
                              context: context,
                              builder: (ctx) => ListView.builder(
                                itemCount: vans.length,
                                itemBuilder: (c, i) {
                                  final v = vans[i];
                                  return ListTile(
                                    title: Text(
                                        '${v.plateNumber} · ${v.driver.name}'),
                                    subtitle: Text(
                                        'Occupancy: ${v.currentOccupancy}/${v.capacity}'),
                                    onTap: () => Navigator.of(c).pop(v),
                                  );
                                },
                              ),
                            );
                            if (selected != null) {
                              final newId = await provider
                                  .rebookFailedBooking(booking, selected);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Rebooked: $newId')));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Rebooking failed: $e')));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rebook'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (booking.paymentStatus == PaymentStatus.paid) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ETicketScreen(bookingId: booking.id)),
                        ),
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('View E-Ticket'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          side: const BorderSide(color: Color(0xFF2196F3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                            _getPaymentStatusText(booking.paymentStatus)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(DocumentDelivery delivery) {
    final statusColor = _deliveryStatusColor(delivery.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description,
                      color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Document Delivery',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        delivery.status.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Payment status badge
                    _statusBadge(
                      delivery.paymentStatus == 'paid' ? 'Paid' : 'Unpaid',
                      delivery.paymentStatus == 'paid'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                      delivery.paymentStatus == 'paid'
                          ? Icons.check_circle
                          : Icons.schedule,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _routeBox(delivery.origin, delivery.destination),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sender',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      Text(delivery.senderName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(delivery.senderContact,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Receiver',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                      Text(delivery.receiverName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(delivery.receiverContact,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.folder_open, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Text(delivery.documentType.label,
                    style: const TextStyle(fontSize: 13)),
                if (delivery.documentTypeNote != null &&
                    delivery.documentTypeNote!.isNotEmpty) ...[
                  const Text(' – ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(
                      delivery.documentTypeNote!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(delivery.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Payment method + fee row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      delivery.paymentMethod == 'GCash'
                          ? Icons.account_balance_wallet
                          : Icons.payments,
                      size: 13,
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 4),
                    Text(delivery.paymentMethod,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.pesoSign,
                        size: 10, color: const Color(0xFF2196F3)),
                    Text(
                      delivery.paymentAmount.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3)),
                    ),
                  ],
                ),
              ],
            ),
            if (delivery.vanPlateNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.directions_car,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${delivery.vanPlateNumber}'
                    '${delivery.vanDriverName != null ? ' · ${delivery.vanDriverName}' : ''}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ref: ${delivery.id.isNotEmpty ? delivery.id.substring(0, delivery.id.length.clamp(0, 8)).toUpperCase() : "N/A"}',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            // View E-Ticket button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryETicketScreen(delivery: delivery),
                  ),
                ),
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('View E-Ticket'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  Widget _routeBox(String origin, String destination) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FROM',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(origin,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.grey[600], size: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('TO',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(destination,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _deliveryStatusColor(DeliveryStatus s) {
    switch (s) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return const Color(0xFF2196F3);
      case DeliveryStatus.delivered:
        return const Color(0xFF4CAF50);
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getPaymentStatusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return const Color(0xFF4CAF50);
      case PaymentStatus.pending:
        return const Color(0xFFFF9800);
      case PaymentStatus.failed:
        return const Color(0xFFF44336);
      case PaymentStatus.refunded:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.undo;
    }
  }

  String _getPaymentStatusText(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending Payment';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Color _getBookingStatusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return const Color(0xFFFF9800);
      case BookingStatus.confirmed:
        return const Color(0xFF2196F3);
      case BookingStatus.onboard:
        return const Color(0xFF00BCD4);
      case BookingStatus.completed:
        return const Color(0xFF4CAF50);
      case BookingStatus.cancelled:
        return const Color(0xFF757575);
      case BookingStatus.cancelledByAdmin:
        return const Color(0xFFF44336);
      case BookingStatus.failed:
        return const Color(0xFFE91E63);
    }
  }

  IconData _getBookingStatusIcon(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.confirmed:
        return Icons.verified;
      case BookingStatus.onboard:
        return Icons.directions_bus;
      case BookingStatus.completed:
        return Icons.check_circle_outline;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.cancelledByAdmin:
        return Icons.block;
      case BookingStatus.failed:
        return Icons.error_outline;
    }
  }

  String _getBookingStatusText(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.onboard:
        return 'On Board';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.cancelledByAdmin:
        return 'Cancelled by Admin';
      case BookingStatus.failed:
        return 'Failed';
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'GCash':
        return Icons.account_balance_wallet;
      case 'Physical Payment':
        return Icons.payments;
      case 'Maya':
        return Icons.credit_card;
      case 'PayPal':
        return Icons.paypal;
      default:
        return Icons.payment;
    }
  }
}

// ── ALL TAB ──────────────────────────────────────────────────────────────────

class _AllTab extends StatelessWidget {
  final String searchQuery;
  final DocumentDeliveryService deliveryService;
  final Widget Function(Booking) onBuildBookingCard;
  final Widget Function(DocumentDelivery) onBuildDeliveryCard;

  const _AllTab({
    required this.searchQuery,
    required this.deliveryService,
    required this.onBuildBookingCard,
    required this.onBuildDeliveryCard,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<DocumentDelivery>>(
          stream: deliveryService.streamUserDeliveries(),
          builder: (context, deliverySnap) {
            if (provider.isLoading ||
                deliverySnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2196F3)));
            }

            final bookings = _filterBookings(provider.bookings, searchQuery);
            final deliveries =
                _filterDeliveries(deliverySnap.data ?? [], searchQuery);

            if (bookings.isEmpty && deliveries.isEmpty) {
              return _EmptyState(
                icon: Icons.history,
                message: searchQuery.isNotEmpty
                    ? 'No results for "$searchQuery"'
                    : 'No bookings or deliveries yet',
                actionLabel: 'Make a Booking',
                onAction: () => Navigator.pop(context),
              );
            }

            final items = <({bool isDelivery, Booking? booking, DocumentDelivery? delivery, DateTime date})>[
              for (final b in bookings)
                (isDelivery: false, booking: b, delivery: null as DocumentDelivery?, date: b.bookingDate),
              for (final d in deliveries)
                (isDelivery: true, booking: null as Booking?, delivery: d, date: d.createdAt),
            ]..sort((a, b) => b.date.compareTo(a.date));

            return RefreshIndicator(
              onRefresh: () async => provider.loadBookings(),
              color: const Color(0xFF2196F3),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                itemCount: items.length,
                itemBuilder: (ctx, i) => items[i].isDelivery
                    ? onBuildDeliveryCard(items[i].delivery!)
                    : onBuildBookingCard(items[i].booking!),
              ),
            );
          },
        );
      },
    );
  }
}

// ── NORMAL BOOKINGS TAB ──────────────────────────────────────────────────────

class _NormalTab extends StatelessWidget {
  final Widget Function(Booking) onBuildBookingCard;

  const _NormalTab({required this.onBuildBookingCard});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF2196F3)));
        }

        if (provider.bookings.isEmpty) {
          return _EmptyState(
            icon: Icons.event_seat,
            message: 'No normal bookings yet',
            actionLabel: 'Make Your First Booking',
            onAction: () => Navigator.pop(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.loadBookings(),
          color: const Color(0xFF2196F3),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            itemCount: provider.bookings.length,
            itemBuilder: (ctx, i) =>
                onBuildBookingCard(provider.bookings[i]),
          ),
        );
      },
    );
  }
}

// ── DOCUMENTS TAB ─────────────────────────────────────────────────────────────

class _DocumentsTab extends StatefulWidget {
  final DocumentDeliveryService deliveryService;
  final Widget Function(DocumentDelivery) onBuildDeliveryCard;

  const _DocumentsTab({
    required this.deliveryService,
    required this.onBuildDeliveryCard,
  });

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  // Cache the stream so it isn't recreated on every rebuild
  late final Stream<List<DocumentDelivery>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = widget.deliveryService.streamUserDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DocumentDelivery>>(
      stream: _stream,
      builder: (context, snapshot) {
        // Show loading while waiting for auth or first Firestore response
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading deliveries:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final deliveries = snapshot.data ?? [];

        if (deliveries.isEmpty) {
          return const _EmptyState(
            icon: Icons.description,
            message: 'No document deliveries yet',
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: deliveries.length,
          itemBuilder: (ctx, i) => widget.onBuildDeliveryCard(deliveries[i]),
        );
      },
    );
  }
}

// ── FILTER HELPERS ────────────────────────────────────────────────────────────

List<Booking> _filterBookings(List<Booking> list, String query) {
  if (query.isEmpty) return list;
  return list.where((b) {
    return b.routeName.toLowerCase().contains(query) ||
        b.origin.toLowerCase().contains(query) ||
        b.destination.toLowerCase().contains(query) ||
        b.bookingStatus.name.toLowerCase().contains(query) ||
        b.id.toLowerCase().contains(query) ||
        (b.vanPlateNumber?.toLowerCase().contains(query) ?? false) ||
        (b.passengerDetails?['name']
                ?.toString()
                .toLowerCase()
                .contains(query) ??
            false);
  }).toList();
}

List<DocumentDelivery> _filterDeliveries(
    List<DocumentDelivery> list, String query) {
  if (query.isEmpty) return list;
  return list.where((d) {
    return d.routeName.toLowerCase().contains(query) ||
        d.origin.toLowerCase().contains(query) ||
        d.destination.toLowerCase().contains(query) ||
        d.senderName.toLowerCase().contains(query) ||
        d.receiverName.toLowerCase().contains(query) ||
        d.status.name.toLowerCase().contains(query) ||
        (d.vanPlateNumber?.toLowerCase().contains(query) ?? false);
  }).toList();
}

// ── EMPTY STATE ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, size: 50, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
