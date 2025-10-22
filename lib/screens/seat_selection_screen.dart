import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/seat_provider.dart';
import '../models/booking_models.dart';
import '../widgets/terms_conditions_modal.dart';
import '../widgets/van_seat_layout.dart';
import '../widgets/bus_seat_layout.dart';
import 'booking_form_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String vehicleType; // 'van' or 'bus'
  
  const SeatSelectionScreen({
    super.key,
    this.vehicleType = 'van', // Default to 'van' for backward compatibility
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _showBottomPanel = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSeatsData());
  }

  void _initializeSeatsData() async {
    try {
      // Using Firestore-generated route ID from admin route management
      await Provider.of<SeatProvider>(
        context,
        listen: false,
      ).initializeSeats(
        routeId: 'FTz5KprpMPeF930xOEId',
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
        ).refreshSeatAvailability(routeId: 'FTz5KprpMPeF930xOEId');
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
                    routeId: 'FTz5KprpMPeF930xOEId',
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
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.blue[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      'Available',
                      seatProvider.seats
                          .where((s) => !s.isReserved && !s.isSelected)
                          .length,
                      Colors.green,
                    ),
                    _buildInfoChip(
                      'Selected',
                      seatProvider.selectedSeats.length,
                      Colors.blue,
                    ),
                    _buildInfoChip(
                      'Reserved',
                      seatProvider.seats.where((s) => s.isReserved).length,
                      Colors.red,
                    ),
                  ],
                ),
              ),

              // Legend
              Container(
                margin: const EdgeInsets.all(16),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      'Available',
                      Colors.white,
                      Colors.grey[300]!,
                    ),
                    _buildLegendItem(
                      'Selected',
                      const Color(0xFF2196F3),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'Reserved',
                      Colors.red[300]!,
                      Colors.red[800]!,
                    ),
                    _buildLegendItem(
                      'Discount',
                      const Color(0xFF4CAF50),
                      Colors.white,
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
                  child: Consumer<SeatProvider>(
                    builder: (context, seatProvider, child) {
                      // Determine which layout to use based on vehicle type
                      if (seatProvider.vehicleType == 'bus') {
                        return BusSeatLayout(
                          seatProvider: seatProvider,
                          onSeatTap: _handleSeatTap,
                          onSeatLongPress: _handleSeatLongPress,
                        );
                      } else {
                        return VanSeatLayout(
                          seatProvider: seatProvider,
                          onSeatTap: _handleSeatTap,
                          onSeatLongPress: _handleSeatLongPress,
                        );
                      }
                    },
                  ),
                ),
              ),

              // Selection Info
              if (seatProvider.selectedSeats.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.all(16),
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
                          const Text(
                            'Selection Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showBottomPanel = !_showBottomPanel;
                              });
                            },
                            child: Text(
                              _showBottomPanel
                                  ? 'Hide Details'
                                  : 'Show Details',
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
                                onAccept: () {
                                  // After accepting terms, proceed to booking
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingFormScreen(
                                        selectedSeats: seatProvider.selectedSeats,
                                        totalAmount: seatProvider
                                            .calculateTotalAmountWithFee(),
                                        discountAmount: seatProvider
                                            .calculateDiscountAmount(),
                                      ),
                                    ),
                                  );
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
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Handle seat tap
  void _handleSeatTap(Seat seat, SeatProvider seatProvider) {
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
  void _handleSeatLongPress(Seat seat, SeatProvider seatProvider) {
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
          Row(
            children: [
              if (prefix.isNotEmpty)
                Text(
                  prefix,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                    color: isTotal ? const Color(0xFF2196F3) : null,
                  ),
                ),
              FaIcon(
                FontAwesomeIcons.pesoSign,
                size: isTotal ? 14 : 12,
                color: isTotal ? const Color(0xFF2196F3) : null,
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                  color: isTotal ? const Color(0xFF2196F3) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog(Seat seat, SeatProvider seatProvider) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
