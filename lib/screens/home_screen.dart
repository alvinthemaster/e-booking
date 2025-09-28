import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'seat_selection_screen.dart';
import 'booking_history_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/booking_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const BookingHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Bookings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseData();
  }

  Future<void> _initializeFirebaseData() async {
    if (_isInitialized) return;
    
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      // Initialize sample data (routes and schedules)
      await bookingProvider.initializeSampleData();
      
      // Load routes
      await bookingProvider.loadRoutes();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing Firebase data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Godtrasco',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'E-Ticket Reservation',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Profile Button
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        icon: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Profile',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Book your van seat with ease',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Quick Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Base Fare',
                                '150',
                                FontAwesomeIcons.pesoSign,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Discount (Student, PWD, Senior)',
                                '13.33%',
                                Icons.local_offer,
                                const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Available Routes
                        Consumer<BookingProvider>(
                          builder: (context, bookingProvider, child) {
                            if (bookingProvider.isLoading) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }

                            if (bookingProvider.routes.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.info, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No routes available',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final routes = bookingProvider.routes;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      color: const Color(0xFF2196F3),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Available Routes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...routes.map((route) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'From',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              route.origin,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFF2196F3),
                                        size: 20,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'To',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              route.destination,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₱${route.basePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Van Queue System
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
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
                                children: [
                                  Icon(
                                    Icons.directions_bus,
                                    color: const Color(0xFF2196F3),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Van Queue Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Van 1 - Currently Boarding
                              _buildVanQueueCard(
                                vanNumber: '1',
                                plateNumber: 'ABC-123',
                                status: 'Currently Boarding',
                                statusColor: const Color(0xFF4CAF50),
                                occupancy: 15,
                                maxSeats: 18,
                                isActive: true,
                                onBook: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SeatSelectionScreen(),
                                    ),
                                  );
                                },
                              ),
                              
                              // Van 2 - In Queue
                              _buildVanQueueCard(
                                vanNumber: '2',
                                plateNumber: 'DEF-456',
                                status: 'In Queue',
                                statusColor: const Color(0xFFFF9800),
                                occupancy: 8,
                                maxSeats: 18,
                                isActive: false,
                                onBook: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SeatSelectionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVanQueueCard({
    required String vanNumber,
    required String plateNumber,
    required String status,
    required Color statusColor,
    required int occupancy,
    required int maxSeats,
    required bool isActive,
    required VoidCallback onBook,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? statusColor.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? statusColor : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Top Row: Van Icon + Details + Status
          Row(
            children: [
              // Van Icon and Number
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isActive ? statusColor : Colors.grey[400],
                  borderRadius: BorderRadius.circular(22.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 18,
                      ),
                      Text(
                        vanNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Van Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Van $vanNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      plateNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Occupancy: $occupancy/$maxSeats',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: occupancy / maxSeats,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive ? statusColor : Colors.grey[500],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${((occupancy / maxSeats) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? statusColor : Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isActive ? 3 : 1,
                      shadowColor: isActive ? statusColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? Icons.event_seat : Icons.schedule,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Book Now' : 'Pre-Book',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}