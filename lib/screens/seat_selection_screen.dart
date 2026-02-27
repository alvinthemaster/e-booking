import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seat_provider.dart';
import '../providers/booking_provider.dart';
import '../models/booking_models.dart' as models;
import '../widgets/terms_conditions_modal.dart';
import '../widgets/van_seat_layout.dart';
import '../widgets/bus_seat_layout.dart';
import '../services/document_delivery_service.dart';
import 'booking_form_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String vehicleType; // 'van' or 'bus'
  final String routeId; // The route ID for this booking
  
  const SeatSelectionScreen({
    super.key,
    this.vehicleType = 'van', // Default to 'van' for backward compatibility
    required this.routeId, // Route ID is now required
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _showBottomPanel = false;
  bool _isInitialized = false;
  final DocumentDeliveryService _deliveryService = DocumentDeliveryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSeatsData());
  }

  void _initializeSeatsData() async {
    try {
      // Use the route ID passed from home screen
      debugPrint('🎫 Initializing seats for route: ${widget.routeId}');
      await Provider.of<SeatProvider>(
        context,
        listen: false,
      ).initializeSeats(
        routeId: widget.routeId,
        vehicleType: widget.vehicleType,
      );
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Start periodic refresh of seat availability
        _startPeriodicRefresh();
      }
    } catch (e) {
      // Handle initialization error gracefully
      if (mounted) {
        setState(() {
          _isInitialized = true; // Set to true anyway to show the UI
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading seats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPeriodicRefresh() {
    // Refresh seat availability every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        Provider.of<SeatProvider>(
          context,
          listen: false,
        ).refreshSeatAvailability(routeId: widget.routeId);
        _startPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SeatProvider>(
      builder: (context, seatProvider, child) {
        // Safety check: ensure seats are initialized
        if (!_isInitialized || seatProvider.seats.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text('Select Your Seat'),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2196F3)),
                  SizedBox(height: 16),
                  Text(
                    'Loading seat layout...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Select Your Seat'),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2196F3)),
              onPressed: () {
                // Clear any pending selections before navigating back
                final seatProvider = Provider.of<SeatProvider>(
                  context,
                  listen: false,
                );
                seatProvider.clearSelection();

                // Safe navigation back with debug logging
                if (Navigator.of(context).canPop()) {
                  debugPrint('SeatSelection: Navigating back normally');
                  Navigator.pop(context);
                } else {
                  // Fallback: navigate to home if navigation stack is corrupted
                  debugPrint(
                    'SeatSelection: Navigation stack corrupted, going to home',
                  );
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF2196F3)),
                onPressed: () async {
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing seat availability...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  // Refresh seat availability
                  await seatProvider.refreshSeatAvailability(
                    routeId: widget.routeId,
                  );
                },
              ),
              if (seatProvider.selectedSeats.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Color(0xFF2196F3)),
                  onPressed: () {
                    seatProvider.clearSelection();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Seat Availability Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                color: Colors.blue[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildInfoChip(
                        'Available',
                        seatProvider.seats
                            .where((s) => !s.isReserved && !s.isSelected)
                            .length,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _buildInfoChip(
                        'Selected',
                        seatProvider.selectedSeats.length,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _buildInfoChip(
                        'Reserved',
                        seatProvider.seats.where((s) => s.isReserved).length,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Legend
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: _buildLegendItem(
                        'Available',
                        Colors.white,
                        Colors.grey[300]!,
                      ),
                    ),
                    Flexible(
                      child: _buildLegendItem(
                        'Selected',
                        const Color(0xFF2196F3),
                        Colors.white,
                      ),
                    ),
                    Flexible(
                      child: _buildLegendItem(
                        'Reserved',
                        Colors.red[300]!,
                        Colors.red[800]!,
                      ),
                    ),
                    Flexible(
                      child: _buildLegendItem(
                        'Discount',
                        const Color(0xFF4CAF50),
                        Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Seat Layout (Van or Bus)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: StreamBuilder<bool>(
                    stream: _deliveryService
                        .streamHasActiveDeliveryForRoute(widget.routeId),
                    initialData: false,
                    builder: (context, deliverySnap) {
                      final hasDocDelivery = deliverySnap.data ?? false;
                      return Consumer<SeatProvider>(
                        builder: (context, seatProvider, child) {
                          // Determine which layout to use based on vehicle type
                          if (seatProvider.vehicleType == 'bus') {
                            return BusSeatLayout(
                              seatProvider: seatProvider,
                              onSeatTap: _handleSeatTap,
                              onSeatLongPress: _handleSeatLongPress,
                              showDocumentIcon: hasDocDelivery,
                            );
                          } else {
                            return VanSeatLayout(
                              seatProvider: seatProvider,
                              onSeatTap: _handleSeatTap,
                              onSeatLongPress: _handleSeatLongPress,
                              showDocumentIcon: hasDocDelivery,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              // Selection Info
              if (seatProvider.selectedSeats.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Selection Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showBottomPanel = !_showBottomPanel;
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              _showBottomPanel ? 'Hide' : 'Details',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      if (_showBottomPanel) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Selected Seats:',
                          '${seatProvider.selectedSeats.length}',
                        ),
                        _buildSummaryRowWithPeso(
                          'Regular Seats:',
                          '${seatProvider.regularFareSeats} × ',
                          seatProvider.baseFare.toStringAsFixed(0),
                        ),
                        if (seatProvider.discountedSeats > 0)
                          _buildSummaryRowWithPeso(
                            'Discounted Seats:',
                            '${seatProvider.discountedSeats} × ',
                            (seatProvider.baseFare *
                                    (1 - seatProvider.discountRate))
                                .toStringAsFixed(0),
                          ),
                        const Divider(),
                        _buildSummaryRowWithPeso(
                          'Subtotal:',
                          '',
                          seatProvider.calculateTotalAmount().toStringAsFixed(2),
                        ),
                        _buildSummaryRowWithPeso(
                          'Booking Fee:',
                          '',
                          seatProvider.bookingFee.toStringAsFixed(2),
                        ),
                        const Divider(),
                        _buildSummaryRowWithPeso(
                          'Total Amount:',
                          '',
                          seatProvider.calculateTotalAmountWithFee().toStringAsFixed(2),
                          isTotal: true,
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            // Show Terms & Conditions modal first
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => TermsConditionsModal(
                                onAccept: () async {
                                  // Get route details from booking provider
                                  final bookingProvider = Provider.of<BookingProvider>(
                                    context,
                                    listen: false,
                                  );
                                  
                                  // Find the route that matches widget.routeId
                                  final route = bookingProvider.routes.firstWhere(
                                    (r) => r.id == widget.routeId,
                                    orElse: () => models.Route(
                                      id: widget.routeId,
                                      name: 'Unknown Route',
                                      origin: 'Unknown',
                                      destination: 'Unknown',
                                      basePrice: 0,
                                      estimatedDuration: 0,
                                      waypoints: [],
                                    ),
                                  );
                                  
                                  // After accepting terms, proceed to booking
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookingFormScreen(
                                          selectedSeats: seatProvider.selectedSeats,
                                          totalAmount: seatProvider
                                              .calculateTotalAmountWithFee(),
                                          discountAmount: seatProvider
                                              .calculateDiscountAmount(),
                                          routeId: widget.routeId, // Pass route ID
                                          routeName: route.name, // Pass route name
                                          origin: route.origin, // Pass origin
                                          destination: route.destination, // Pass destination
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                          child: const Text(
                            'Continue to Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, Color borderColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Handle seat tap
  void _handleSeatTap(models.Seat seat, SeatProvider seatProvider) {
    if (!seat.isReserved) {
      seatProvider.toggleSeatSelection(seat.id);
    } else {
      // Show a message when trying to select a reserved seat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${seat.id} is already reserved'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle seat long press for discount
  void _handleSeatLongPress(models.Seat seat, SeatProvider seatProvider) {
    if (seat.isSelected && !seat.isReserved) {
      _showDiscountDialog(seat, seatProvider);
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? const Color(0xFF2196F3) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowWithPeso(
    String label,
    String prefix,
    String amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefix.isNotEmpty)
                  Flexible(
                    child: Text(
                      prefix,
                      style: TextStyle(
                        fontSize: isTotal ? 16 : 14,
                        fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                        color: isTotal ? const Color(0xFF2196F3) : null,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                Text(
                  '₱',
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                    color: isTotal ? const Color(0xFF2196F3) : Colors.grey[700],
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                      color: isTotal ? const Color(0xFF2196F3) : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(models.Seat seat, SeatProvider seatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seat ${seat.id}'),
        content: Text(
          seat.hasDiscount
              ? 'Remove discount for this seat?'
              : 'Apply 13.33% discount for this seat?\n(For students, PWD, senior citizens)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              seatProvider.toggleSeatDiscount(seat.id);
              Navigator.pop(context);
            },
            child: Text(seat.hasDiscount ? 'Remove' : 'Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
