import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/seat_provider.dart';
import '../models/booking_models.dart';
import 'booking_form_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

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
      ).initializeSeats(routeId: 'SCLRIO5R1ckXKwz2ykxd');
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
        ).refreshSeatAvailability(routeId: 'SCLRIO5R1ckXKwz2ykxd');
        _startPeriodicRefresh(); // Continue the cycle
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
                    routeId: 'SCLRIO5R1ckXKwz2ykxd',
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
                      Colors.grey,
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
                      Colors.grey[400]!,
                      Colors.grey[600]!,
                    ),
                    _buildLegendItem(
                      'Discount',
                      const Color(0xFF4CAF50),
                      Colors.white,
                    ),
                  ],
                ),
              ),

              // Van Layout
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
                  child: Column(
                    children: [
                      // Driver Section and adjacent seats
                      Container(
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            // Driver Section
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.drive_eta,
                                        color: Colors.grey,
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Driver',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Driver-adjacent seats (2 seats)
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSeat(
                                      seatProvider.seats.firstWhere(
                                        (s) => s.id == 'D1A',
                                        orElse: () => Seat(
                                          id: 'D1A',
                                          row: 0,
                                          position: 'driver-right-window',
                                        ),
                                      ),
                                      seatProvider,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildSeat(
                                      seatProvider.seats.firstWhere(
                                        (s) => s.id == 'D1B',
                                        orElse: () => Seat(
                                          id: 'D1B',
                                          row: 0,
                                          position: 'driver-right-aisle',
                                        ),
                                      ),
                                      seatProvider,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Seats Layout
                      Expanded(child: _buildVanSeatsLayout(seatProvider)),
                    ],
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
                          'Total Amount:',
                          '',
                          seatProvider.calculateTotalAmount().toStringAsFixed(
                            2,
                          ),
                          isTotal: true,
                        ),
                      ],

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingFormScreen(
                                  selectedSeats: seatProvider.selectedSeats,
                                  totalAmount: seatProvider
                                      .calculateTotalAmount(),
                                  discountAmount: seatProvider
                                      .calculateDiscountAmount(),
                                ),
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

  Widget _buildVanSeatsLayout(SeatProvider seatProvider) {
    return Column(
      children: [
        // Regular passenger rows (4 rows)
        for (int row = 1; row <= 4; row++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  // Left side - 2 seats
                  Expanded(
                    child: _buildSeat(
                      seatProvider.seats.firstWhere(
                        (s) => s.id == 'L${row}A',
                        orElse: () => Seat(
                          id: 'L${row}A',
                          row: row,
                          position: 'left-window',
                        ),
                      ),
                      seatProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSeat(
                      seatProvider.seats.firstWhere(
                        (s) => s.id == 'L${row}B',
                        orElse: () => Seat(
                          id: 'L${row}B',
                          row: row,
                          position: 'left-aisle',
                        ),
                      ),
                      seatProvider,
                    ),
                  ),

                  // Aisle space
                  const SizedBox(width: 20),

                  // Right side - 2 seats
                  Expanded(
                    child: _buildSeat(
                      seatProvider.seats.firstWhere(
                        (s) => s.id == 'R${row}A',
                        orElse: () => Seat(
                          id: 'R${row}A',
                          row: row,
                          position: 'right-aisle',
                        ),
                      ),
                      seatProvider,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSeat(
                      seatProvider.seats.firstWhere(
                        (s) => s.id == 'R${row}B',
                        orElse: () => Seat(
                          id: 'R${row}B',
                          row: row,
                          position: 'right-window',
                        ),
                      ),
                      seatProvider,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSeat(Seat seat, SeatProvider seatProvider) {
    Color seatColor;
    Color textColor;
    Color borderColor;
    Widget? overlayIcon;

    if (seat.isReserved) {
      seatColor = Colors.grey[300]!;
      textColor = Colors.grey[600]!;
      borderColor = Colors.grey[500]!;
      overlayIcon = Icon(Icons.lock, color: Colors.grey[600], size: 16);
    } else if (seat.isSelected) {
      if (seat.hasDiscount) {
        seatColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        borderColor = const Color(0xFF388E3C);
      } else {
        seatColor = const Color(0xFF2196F3);
        textColor = Colors.white;
        borderColor = const Color(0xFF1976D2);
      }
    } else {
      seatColor = Colors.white;
      textColor = Colors.grey[700]!;
      borderColor = Colors.grey[300]!;
    }

    return GestureDetector(
      onTap: () {
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
      },
      onLongPress: () {
        if (seat.isSelected && !seat.isReserved) {
          _showDiscountDialog(seat, seatProvider);
        }
      },
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: seatColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (overlayIcon != null) overlayIcon,
              Text(
                seat.id,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: overlayIcon != null ? 10 : 14,
                ),
              ),
              if (seat.hasDiscount && !seat.isReserved)
                Icon(Icons.local_offer, color: textColor, size: 12),
            ],
          ),
        ),
      ),
    );
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
