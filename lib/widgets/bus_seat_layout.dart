import 'package:flutter/material.dart';
import '../models/booking_models.dart';
import '../providers/seat_provider.dart';

class BusSeatLayout extends StatelessWidget {
  final SeatProvider seatProvider;
  final Function(Seat, SeatProvider) onSeatTap;
  final Function(Seat, SeatProvider) onSeatLongPress;

  const BusSeatLayout({
    super.key,
    required this.seatProvider,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Driver Section at the top
        Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              // Driver Section
              Expanded(
                flex: 2,
                child: Container(
                  height: 70,
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
                          'DRIVER',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Driver-adjacent seat (1 seat on the right)
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // Empty space on left
                    const Expanded(flex: 2, child: SizedBox()),
                    const SizedBox(width: 20),
                    // Driver-adjacent seat on the right
                    Expanded(
                      child: _buildSeat(
                        seatProvider.seats.firstWhere(
                          (s) => s.id == 'D1A',
                          orElse: () => Seat(
                            id: 'D1A',
                            row: 0,
                            position: 'driver-right',
                          ),
                        ),
                        seatProvider,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Empty space on right to align with R1B
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bus Seats Layout - 4 rows with 2-2 configuration + 1 row with 3-2 configuration
        Expanded(
          child: Column(
            children: [
              // First 4 rows: Standard 2-2 configuration
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
              
              // Last row (Row 5): 3-2 configuration (3 seats on left, 2 on right)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Left side - 3 seats
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSeat(
                                seatProvider.seats.firstWhere(
                                  (s) => s.id == 'L5A',
                                  orElse: () => Seat(
                                    id: 'L5A',
                                    row: 5,
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
                                  (s) => s.id == 'L5B',
                                  orElse: () => Seat(
                                    id: 'L5B',
                                    row: 5,
                                    position: 'left-middle',
                                  ),
                                ),
                                seatProvider,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSeat(
                                seatProvider.seats.firstWhere(
                                  (s) => s.id == 'L5C',
                                  orElse: () => Seat(
                                    id: 'L5C',
                                    row: 5,
                                    position: 'left-aisle',
                                  ),
                                ),
                                seatProvider,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Aisle space
                      const SizedBox(width: 20),

                      // Right side - 2 seats
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSeat(
                                seatProvider.seats.firstWhere(
                                  (s) => s.id == 'R5A',
                                  orElse: () => Seat(
                                    id: 'R5A',
                                    row: 5,
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
                                  (s) => s.id == 'R5B',
                                  orElse: () => Seat(
                                    id: 'R5B',
                                    row: 5,
                                    position: 'right-window',
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
              ),
            ],
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
      seatColor = Colors.red[300]!;
      textColor = Colors.white;
      borderColor = Colors.red[500]!;
      overlayIcon = const Icon(Icons.lock, color: Colors.white, size: 16);
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
      onTap: () => onSeatTap(seat, seatProvider),
      onLongPress: () => onSeatLongPress(seat, seatProvider),
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
}
