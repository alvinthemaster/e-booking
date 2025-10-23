import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'seat_selection_screen.dart';
import 'booking_history_screen.dart';
import '../providers/booking_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/firestore_debugger.dart';
import '../widgets/van_departure_countdown_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const HomeTab(), const BookingHistoryScreen()];

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
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
    // Use post frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebaseData();
    });
  }

  Future<void> _initializeFirebaseData() async {
    if (_isInitialized) return;

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      debugPrint('🚀 Starting Firebase data initialization...');

      // Initialize sample data (routes and schedules) only if needed - but don't notify during build
      await bookingProvider.initializeSampleDataSilent();

      // Check for existing vans first - DON'T create sample vans if real ones exist
      debugPrint('🔍 Checking for existing vans in Firestore...');
      await bookingProvider.initializeSampleVansSilent();

      // Sync vans to ensure they have correct route IDs
      debugPrint('🔄 Syncing vans to available routes...');
      await bookingProvider.syncVansToRoutes();

      // Debug Firestore data for troubleshooting
      if (kDebugMode) {
        debugPrint('🔍 Running Firestore debug checks...');
        await FirestoreDebugger.debugVansCollection();
      }

      // Force load fresh data from Firestore after initialization
      debugPrint('🔄 Force loading fresh van data from Firestore...');
      await bookingProvider.loadVans();

      // Only set initialized state after everything is complete
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      debugPrint('✅ Firebase data initialization completed');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase data: $e');
      if (mounted) {
        setState(() {
          _isInitialized =
              true; // Set to true even on error to prevent retry loops
        });
      }
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
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/godtrasco_logo.png'),
                                    fit: BoxFit.contain,
                                  ),
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
                      Row(
                        children: [
                          // Debug refresh button to manually sync with Firestore
                          IconButton(
                            onPressed: () async {
                              final provider = Provider.of<BookingProvider>(
                                context,
                                listen: false,
                              );
                              debugPrint('🔄 Manual refresh triggered');
                              await provider.loadVans();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Refresh Vans',
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Book your seat with ease',
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
                        // Van Departure Countdown Widget
                        VanDepartureCountdownWidget(),
                        
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
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                const SizedBox(height: 8),
                                Text(
                                  'Select a route to view available vans',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...routes.map(
                                  (route) => GestureDetector(
                                    onTap: () async {
                                      // Select this route and load its vans
                                      await bookingProvider.selectRoute(route);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: bookingProvider.selectedRoute?.id == route.id
                                            ? const Color(0xFF2196F3).withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: bookingProvider.selectedRoute?.id == route.id
                                              ? const Color(0xFF2196F3)
                                              : Colors.grey[200]!,
                                          width: bookingProvider.selectedRoute?.id == route.id ? 2 : 1,
                                        ),
                                      ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
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
                                          CurrencyFormatter.formatPeso(route.basePrice),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                    ), // Close GestureDetector
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Van Queue System
                        Consumer<BookingProvider>(
                          builder: (context, bookingProvider, child) {
                            return Container(
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Available Vans',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (bookingProvider.selectedRoute != null)
                                              Text(
                                                'For: ${bookingProvider.selectedRoute!.name}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Debug info section (remove in production)
   //                               Consumer<BookingProvider>(
     //                               builder: (context, provider, child) {
       //                               return Container(
         //                               padding: const EdgeInsets.all(12),
           //                             decoration: BoxDecoration(
             //                             color: Colors.blue[50],
               //                           borderRadius: BorderRadius.circular(
                 //                           8,
                   //                       ),
                     //                     border: Border.all(
                       //                     color: Colors.blue[200]!,
                         //                 ),
                           //             ),
                             //           child: Row(
                               //           children: [
                                 //           Icon(
                                   //           Icons.info,
                                     //         color: Colors.blue[600],
                                       //       size: 16,
                                         //   ),
                                           // const SizedBox(width: 8),
                  //                          Text(
                    //                          'Debug: ${provider.vans.length} van(s) loaded from Firestore',
                      //                        style: TextStyle(
                        //                        fontSize: 12,
                          //                      color: Colors.blue[700],
                            //                  ),
                              //              ),
                                //          ],
                                  //      ),
                                    //  );
                               //     },
                                //  ),
                                  const SizedBox(height: 16),

                                  if (bookingProvider.isLoading)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else if (bookingProvider.vans.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            bookingProvider.selectedRoute == null 
                                                ? Icons.touch_app 
                                                : Icons.info,
                                            color: Colors.grey[400],
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            bookingProvider.selectedRoute == null
                                                ? 'Please select a route above to view available vans'
                                                : 'No boarding vans available for this route',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (bookingProvider.selectedRoute == null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Icon(
                                                Icons.arrow_upward,
                                                color: const Color(0xFF2196F3),
                                                size: 24,
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  else
                                    Column(
                                      children: bookingProvider.vans.map((van) {
                                        // Safety check: ensure vehicleType is never null
                                        final String safeVehicleType = van.vehicleType.isNotEmpty ? van.vehicleType : 'van';
                                        
                                        return _buildVanQueueCard(
                                          vanNumber: van.queuePosition
                                              .toString(),
                                          plateNumber: van.plateNumber,
                                          driverName: van.driver.name,
                                          status: van.statusDisplay,
                                          statusColor: van.statusColor,
                                          occupancy: van.currentOccupancy,
                                          maxSeats: van.capacity,
                                          isActive: van.canBook,
                                          vehicleType: safeVehicleType, // Pass vehicle type with safety check
                                          onBook: () async {
                                            // Check if a route is selected
                                            if (bookingProvider.selectedRoute == null) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Please select a route first'),
                                                    backgroundColor: Colors.red,
                                                    duration: Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                            
                                            final selectedRouteId = bookingProvider.selectedRoute!.id;
                                            debugPrint('🎫 Booking initiated for route: $selectedRouteId');
                                            
                                            // Navigate to seat selection with the route ID
                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SeatSelectionScreen(
                                                        vehicleType: safeVehicleType,
                                                        routeId: selectedRouteId, // Pass the selected route ID
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          FaIcon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildVanQueueCard({
    required String vanNumber,
    required String plateNumber,
    required String driverName,
    required String status,
    required Color statusColor,
    required int occupancy,
    required int maxSeats,
    required bool isActive,
    required VoidCallback onBook,
    String vehicleType = 'van', // NEW: Add vehicle type parameter
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
              // Van/Bus Icon and Number
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
                        vehicleType == 'bus' ? Icons.airport_shuttle : Icons.directions_bus,
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

              // Vehicle Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicleType == 'bus' ? 'Bus' : 'Van'} $vanNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plateNumber,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          driverName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${maxSeats - occupancy} seats available',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Occupancy: $occupancy/$maxSeats',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                shadowColor: isActive
                    ? statusColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isActive ? Icons.event_seat : Icons.schedule, size: 20),
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
