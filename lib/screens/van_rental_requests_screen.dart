import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../models/van_rental_request_model.dart';
import '../models/rental_van_model.dart';
import '../services/van_rental_service.dart';
import '../utils/currency_formatter.dart';
import '../widgets/van_rental_terms_modal.dart';

// ========== IMAGE CAROUSEL WIDGET ==========
class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;

  const _ImageCarousel({
    required this.imageUrls,
    this.height = 180,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: Container(
          height: widget.height,
          color: const Color(0xFF2196F3).withOpacity(0.1),
          child: Center(
            child: Icon(
              FontAwesomeIcons.bus,
              size: 60,
              color: const Color(0xFF2196F3).withOpacity(0.3),
            ),
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) => Image.network(
                widget.imageUrls[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: widget.height,
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      FontAwesomeIcons.bus,
                      size: 60,
                      color: const Color(0xFF2196F3).withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...
          [
            // Page counter badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            // Dot indicators
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
      ],
    );
  }
}

/// Screen to display available rental vans and user's rental requests
class VanRentalRequestsScreen extends StatefulWidget {
  const VanRentalRequestsScreen({super.key});

  @override
  State<VanRentalRequestsScreen> createState() => _VanRentalRequestsScreenState();
}

class _VanRentalRequestsScreenState extends State<VanRentalRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Van Rentals'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Available Vans'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AvailableVansTab(),
          MyRequestsTab(),
        ],
      ),
    );
  }
}

// ========== AVAILABLE VANS TAB ==========
class AvailableVansTab extends StatefulWidget {
  const AvailableVansTab({super.key});

  @override
  State<AvailableVansTab> createState() => _AvailableVansTabState();
}

class _AvailableVansTabState extends State<AvailableVansTab>
    with SingleTickerProviderStateMixin {
  final VanRentalService _vanRentalService = VanRentalService();
  List<RentalVan> _allVans = [];
  Set<String> _bookedVanIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _vehicleTabController;

  @override
  void initState() {
    super.initState();
    _vehicleTabController = TabController(length: 2, vsync: this);
    _loadAvailableVans();
  }

  @override
  void dispose() {
    _vehicleTabController.dispose();
    super.dispose();
  }

  bool _isVanRented(RentalVan van) =>
      !van.isAvailable || _bookedVanIds.contains(van.id);

  Future<void> _loadAvailableVans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _vanRentalService.getAllRentalVans(),
        _vanRentalService.getBookedVanIds(),
      ]);
      final vans = results[0] as List<RentalVan>;
      final booked = results[1] as Set<String>;
      // Sort: available first, then by createdAt descending
      vans.sort((a, b) {
        final aRented = !a.isAvailable || booked.contains(a.id);
        final bRented = !b.isAvailable || booked.contains(b.id);
        if (aRented != bRented) return aRented ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
      debugPrint('AvailableVansTab: Loaded ${vans.length} vans, ${booked.length} booked');
      if (mounted) {
        setState(() {
          _allVans = vans;
          _bookedVanIds = booked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AvailableVansTab: Error loading vans: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading available vehicles...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text(
                'Error Loading Vehicles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAvailableVans,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter vans by vehicle type
    final vans = _allVans.where((v) => 
      v.vehicleType.toLowerCase() == 'van').toList();
    final buses = _allVans.where((v) => 
      v.vehicleType.toLowerCase() == 'bus').toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _vehicleTabController,
            indicatorColor: const Color(0xFF2196F3),
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_shipping, size: 16),
                    const SizedBox(width: 8),
                    Text('Van (${vans.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FontAwesomeIcons.bus, size: 16),
                    const SizedBox(width: 8),
                    Text('Bus (${buses.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _vehicleTabController,
            children: [
              _buildVehicleList(vans, 'Van'),
              _buildVehicleList(buses, 'Bus'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleList(List<RentalVan> vehicles, String vehicleType) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                vehicleType == 'Van' ? Icons.local_shipping : FontAwesomeIcons.bus,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${vehicleType}s Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for available rental ${vehicleType.toLowerCase()}s',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAvailableVans,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableVans,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final van = vehicles[index];
          return _buildVanCard(van, isRented: _isVanRented(van));
        },
      ),
    );
  }

  Widget _buildVanCard(RentalVan van, {required bool isRented}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showVanDetails(van, isRented: isRented),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            _ImageCarousel(
              imageUrls: van.imageUrls,
              height: 180,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),

            // Rented overlay banner
            if (isRented)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border(
                    top: BorderSide(color: Colors.red[200]!),
                    bottom: BorderSide(color: Colors.red[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Text(
                      'Currently rented — not available for booking',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Opacity(
                opacity: isRented ? 0.6 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Van name, plate, and status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                van.brand ?? van.vanName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                van.plateNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isRented
                                ? Colors.red[100]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isRented ? 'RENTED' : 'AVAILABLE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isRented
                                  ? Colors.red[800]
                                  : Colors.green[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    if (van.description.isNotEmpty) ...[
                      Text(
                        van.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Vehicle Type
                    Row(
                      children: [
                        Icon(Icons.directions_bus,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          van.vehicleType,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Price and Book button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price per Day',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatPesoWithDecimals(
                                  van.pricePerDay),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isRented
                                    ? Colors.grey[500]
                                    : const Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed:
                              isRented ? null : () => _showRentalRequestForm(van),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRented
                                ? Colors.grey[300]
                                : const Color(0xFF2196F3),
                            foregroundColor:
                                isRented ? Colors.grey[600] : Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                              isRented ? 'Not Available' : 'Request Rental'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVanDetails(RentalVan van, {required bool isRented}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-width image carousel at the top
                if (van.imageUrls.isNotEmpty)
                  _ImageCarousel(
                    imageUrls: van.imageUrls,
                    height: 220,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      if (van.imageUrls.isEmpty)
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  van.brand ?? van.vanName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  van.plateNumber,
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isRented
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isRented ? 'RENTED' : 'AVAILABLE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isRented
                                    ? Colors.red[800]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                  
                  _buildDetailSection('Description', [
                    Text(van.description.isEmpty ? 'No description available' : van.description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildDetailSection('Details', [
                    _buildDetailRow('Vehicle Type', van.vehicleType),
                    if (van.brand != null)
                      _buildDetailRow('Brand', van.brand!),
                    if (van.color != null)
                      _buildDetailRow('Color', van.color!),
                    _buildDetailRow('Price per Day',
                        CurrencyFormatter.formatPesoWithDecimals(van.pricePerDay)),
                    if (van.pickupLocation != null)
                      _buildDetailRow('Pickup Location', van.pickupLocation!),
                    if (van.minRentalDays != null || van.maxRentalDays != null)
                      _buildDetailRow('Rental Period', van.rentalPeriodDisplay),
                  ]),
                  
                  if (van.amenities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDetailSection('Amenities', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: van.amenities
                            .map((amenity) => Chip(
                                  label: Text(amenity),
                                  backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                                  labelStyle: const TextStyle(color: Color(0xFF2196F3)),
                                ))
                            .toList(),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isRented
                          ? null
                          : () {
                              Navigator.pop(context);
                              _showRentalRequestForm(van);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRented
                            ? Colors.grey[300]
                            : const Color(0xFF2196F3),
                        foregroundColor:
                            isRented ? Colors.grey[600] : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isRented ? 'Not Available for Booking' : 'Request Rental',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }

  void _showRentalRequestForm(RentalVan van) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalRequestFormScreen(van: van),
      ),
    ).then((_) => _loadAvailableVans()); // Refresh after returning
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2196F3),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

// ========== MY REQUESTS TAB ==========
class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  final VanRentalService _vanRentalService = VanRentalService();
  List<VanRentalRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  VanRentalStatus? _selectedStatus; // null = show all

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final requests = await _vanRentalService.getUserVanRentalRequestsOnce();

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load requests: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your requests...', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 24),
              Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRequests,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text('No Requests Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Your rental requests will appear here',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFF2196F3),
      child: Column(
        children: [
          _buildRentalFilterChips(),
          Expanded(
            child: Builder(
              builder: (context) {
                final filtered = _selectedStatus == null
                    ? _requests
                    : _requests.where((r) => r.status == _selectedStatus).toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_selectedStatus == null ? '' : _rentalStatusLabel(_selectedStatus!)} requests',
                          style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildRequestCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalFilterChips() {
    const statuses = VanRentalStatus.values;
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _rentalChip(null, 'All', Icons.list_alt),
            const SizedBox(width: 8),
            ...statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _rentalChip(s, _rentalStatusLabel(s), _rentalStatusIcon(s)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _rentalChip(VanRentalStatus? status, String label, IconData icon) {
    final selected = _selectedStatus == status;
    final color = status == null ? const Color(0xFF2196F3) : _rentalStatusColor(status);
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
            if (status != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_requests.where((r) => r.status == status).length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : color,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.3) : const Color(0xFF2196F3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_requests.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rentalStatusLabel(VanRentalStatus s) {
    switch (s) {
      case VanRentalStatus.pending: return 'Pending';
      case VanRentalStatus.approved: return 'Approved';
      case VanRentalStatus.confirmed: return 'Confirmed';
      case VanRentalStatus.active: return 'Active';
      case VanRentalStatus.completed: return 'Completed';
      case VanRentalStatus.cancelled: return 'Cancelled';
      case VanRentalStatus.rejected: return 'Rejected';
    }
  }

  IconData _rentalStatusIcon(VanRentalStatus s) {
    switch (s) {
      case VanRentalStatus.pending: return Icons.hourglass_empty;
      case VanRentalStatus.approved: return Icons.thumb_up_outlined;
      case VanRentalStatus.confirmed: return Icons.verified_outlined;
      case VanRentalStatus.active: return Icons.directions_car;
      case VanRentalStatus.completed: return Icons.check_circle_outline;
      case VanRentalStatus.cancelled: return Icons.cancel_outlined;
      case VanRentalStatus.rejected: return Icons.block;
    }
  }

  Color _rentalStatusColor(VanRentalStatus s) {
    switch (s) {
      case VanRentalStatus.pending: return Colors.orange;
      case VanRentalStatus.approved: return Colors.teal;
      case VanRentalStatus.confirmed: return const Color(0xFF2196F3);
      case VanRentalStatus.active: return Colors.green;
      case VanRentalStatus.completed: return Colors.green[700]!;
      case VanRentalStatus.cancelled: return Colors.grey;
      case VanRentalStatus.rejected: return Colors.red;
    }
  }

  Widget _buildRequestCard(VanRentalRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(request.brand,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('${request.dateRangeFormatted} (${request.totalDays} days)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text('${request.pickupLocation} → ${request.dropoffLocation}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CurrencyFormatter.formatPesoWithDecimals(request.totalAmount),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.lock_outline, size: 12, color: Colors.amber[800]),
                          const SizedBox(width: 3),
                          Text(
                            '50% deposit: ${CurrencyFormatter.formatPesoWithDecimals(request.depositAmount)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber[800],
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(DateFormat('MMM dd, yyyy').format(request.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VanRentalStatus status) {
    Color backgroundColor;
    Color textColor;
    switch (status) {
      case VanRentalStatus.pending:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
      case VanRentalStatus.approved:
        backgroundColor = Colors.teal[100]!;
        textColor = Colors.teal[800]!;
      case VanRentalStatus.confirmed:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
      case VanRentalStatus.active:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
      case VanRentalStatus.completed:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
      case VanRentalStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
      case VanRentalStatus.rejected:
        backgroundColor = Colors.red[900]!.withOpacity(0.15);
        textColor = Colors.red[900]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Text(status.name.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 0.5)),
    );
  }

  void _showRequestDetails(VanRentalRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Request Details',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      _buildStatusBadge(request.status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Van info section
                  _buildSectionLabel('Van Information'),
                  _buildInfoRow(Icons.directions_car, 'Brand', request.brand),
                  _buildInfoRow(
                      Icons.confirmation_number, 'Plate', request.vanPlateNumber),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Rental Period'),
                  _buildInfoRow(Icons.calendar_today, 'Dates',
                      request.dateRangeFormatted),
                  _buildInfoRow(Icons.timelapse, 'Duration',
                      '${request.totalDays} day${request.totalDays == 1 ? '' : 's'}'),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Location & Passenger'),
                  _buildInfoRow(Icons.location_on, 'Pickup Location',
                      request.pickupLocation.isNotEmpty
                          ? request.pickupLocation
                          : '—'),
                  _buildInfoRow(Icons.person, 'Passenger Name',
                      request.dropoffLocation.isNotEmpty
                          ? request.dropoffLocation
                          : '—'),
                  _buildInfoRow(Icons.phone, 'Contact',
                      request.userPhone.isNotEmpty ? request.userPhone : '—'),

                  const SizedBox(height: 16),
                  _buildSectionLabel('Payment'),
                  _buildInfoRow(
                    Icons.payments_outlined,
                    'Total Amount',
                    CurrencyFormatter.formatPesoWithDecimals(request.totalAmount),
                    valueStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3)),
                  ),
                  _buildInfoRow(
                    Icons.lock_outline,
                    'Required Deposit (50%)',
                    CurrencyFormatter.formatPesoWithDecimals(request.depositAmount),
                    valueStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8F00)),
                  ),
                  _buildInfoRow(Icons.payments_outlined, 'Price per Day',
                      CurrencyFormatter.formatPesoWithDecimals(
                          request.pricePerDay)),
                  _buildInfoRow(
                    Icons.person_pin_circle_outlined,
                    'Driver',
                    request.withDriver ? 'With Driver (+₱1,000.00)' : 'Self-drive',
                  ),

                  if (request.purpose != null &&
                      request.purpose!.isNotEmpty) ...
                    [
                      const SizedBox(height: 16),
                      _buildSectionLabel('Additional Info'),
                      _buildInfoRow(
                          Icons.info_outline, 'Purpose', request.purpose!),
                    ],

                  // Rejected notice
                  if (request.status == VanRentalStatus.rejected) ...
                    [
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    color: Colors.red[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Your request has been rejected',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[800]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Unfortunately, your rental request was not approved. You may submit a new request or contact us for more information.',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.red[900]),
                            ),
                          ],
                        ),
                      ),
                    ],

                  // Approved notice
                  if (request.status == VanRentalStatus.approved) ...
                    [
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.teal[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Your request has been approved!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.teal[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please prepare the following before your rental start date:',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.teal[900]),
                            ),
                            const SizedBox(height: 8),
                            _buildCheckItem("Valid Driver's License (original)"),
                            _buildCheckItem(
                                'Full payment in cash on the day of pickup'),
                            _buildCheckItem(
                                'Arrive on time at the designated pickup location'),
                            _buildCheckItem(
                                'Any additional requirements you noted in your request'),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.amber[300]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.amber[800], size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Failure to present your driver\'s license or complete payment on pickup day may result in cancellation of the rental.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                  const SizedBox(height: 16),
                  Text(
                    'Submitted on ${DateFormat('MMM dd, yyyy hh:mm a').format(request.createdAt)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
              letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: valueStyle ??
                    const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 15, color: Colors.teal[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: Colors.teal[900])),
          ),
        ],
      ),
    );
  }
}

// ========== RENTAL REQUEST FORM SCREEN ==========
class RentalRequestFormScreen extends StatefulWidget {
  final RentalVan van;

  const RentalRequestFormScreen({super.key, required this.van});

  @override
  State<RentalRequestFormScreen> createState() => _RentalRequestFormScreenState();
}

class _RentalRequestFormScreenState extends State<RentalRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VanRentalService _vanRentalService = VanRentalService();

  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Purpose dropdown
  String? _selectedPurpose;
  final TextEditingController _customPurposeController = TextEditingController();
  
  final List<String> _purposeOptions = [
    'Business Trip',
    'Family Outing',
    'School Trip',
    'Airport Transfer',
    'Tour/Sightseeing',
    'Corporate Event',
    'Other',
  ];

  bool _isSubmitting = false;
  bool _withDriver = false;
  bool _termsAccepted = false;
  static const double _driverFee = 1000.0;

  // Driver's license attachment (required for self-drive)
  String? _driverLicenseBase64;
  String? _driverLicenseFileName;
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  // Proof of purpose attachment (required)
  String? _proofOfPurposeBase64;
  String? _proofOfPurposeFileName;

  @override
  void initState() {
    super.initState();
    // Pre-fill pickup location with the admin-set van pickup location
    if (widget.van.pickupLocation != null &&
        widget.van.pickupLocation!.isNotEmpty) {
      _pickupController.text = widget.van.pickupLocation!;
    }
    // Pre-fill user name and phone from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _dropoffController.text = user.displayName!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _purposeController.dispose();
    _requirementsController.dispose();
    _phoneController.dispose();
    _customPurposeController.dispose();
    super.dispose();
  }

  int _calculateDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double _calculateTotal() {
    final baseAmount = widget.van.pricePerDay * _calculateDays();
    return baseAmount + (_withDriver ? _driverFee : 0);
  }

  double _calculateDeposit() => _calculateTotal() * 0.5;

  Future<void> _pickDriverLicense() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    // On Android, bytes can be null when picked from content URIs (Drive, Photos).
    // Fall back to reading from file.path on non-web platforms.
    var bytes = file.bytes;
    if (!kIsWeb && bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {}
    }

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the selected file. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (bytes.length > _maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File too large. Maximum size is 10 MB. Please compress the image or use a smaller file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      _driverLicenseBase64 = base64Encode(bytes!);
      _driverLicenseFileName = file.name;
    });
  }

  Future<void> _pickProofOfPurpose() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    var bytes = file.bytes;
    if (!kIsWeb && bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {}
    }

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the selected file. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (bytes.length > _maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File too large. Maximum size is 10 MB. Please compress the image or use a smaller file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      _proofOfPurposeBase64 = base64Encode(bytes!);
      _proofOfPurposeFileName = file.name;
    });
  }

  Future<void> _showTermsAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (!_withDriver && _driverLicenseBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver\'s License attachment is required for self-drive.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_proofOfPurposeBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof of Purpose attachment is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final days = _calculateDays();
    if (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0 && days > widget.van.maxRentalDays!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rental period exceeds the maximum of ${widget.van.maxRentalDays} days'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VanRentalTermsModal(
        totalAmount: _calculateTotal(),
        depositAmount: _calculateDeposit(),
        onAccept: _submitRequest,
      ),
    );
  }

  Future<void> _submitRequest() async {

    final days = _calculateDays();
    // Fix: only check max if it's set and greater than 0
    if (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0 && days > widget.van.maxRentalDays!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rental period exceeds the maximum of ${widget.van.maxRentalDays} days'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Determine final purpose value
      String? finalPurpose;
      if (_selectedPurpose != null) {
        if (_selectedPurpose == 'Other') {
          finalPurpose = _customPurposeController.text.isNotEmpty 
              ? _customPurposeController.text 
              : null;
        } else {
          finalPurpose = _selectedPurpose;
        }
      }
      
      final request = VanRentalRequest(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        userPhone: _phoneController.text,
        vanId: widget.van.id,
        brand: widget.van.brand ?? widget.van.vanName,
        vanPlateNumber: widget.van.plateNumber,
        rentalStartDate: _startDate!,
        rentalEndDate: _endDate!,
        totalDays: _calculateDays(),
        pricePerDay: widget.van.pricePerDay,
        totalAmount: _calculateTotal(),
        depositAmount: _calculateDeposit(),
        pickupLocation: _pickupController.text,
        dropoffLocation: _dropoffController.text,
        purpose: finalPurpose,
        specialRequirements:
            _requirementsController.text.isEmpty ? null : _requirementsController.text,
        withDriver: _withDriver,
        driverLicenseBase64: _withDriver ? null : _driverLicenseBase64,
        driverLicenseFileName: _withDriver ? null : _driverLicenseFileName,
        proofOfPurposeBase64: _proofOfPurposeBase64,
        proofOfPurposeFileName: _proofOfPurposeFileName,
        status: VanRentalStatus.pending,
        createdAt: DateTime.now(),
      );

      final requestId = await _vanRentalService.createVanRentalRequest(request);

      if (requestId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rental request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to create request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request Van Rental'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Van Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.van.imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          widget.van.imageUrls.first,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.van.brand ?? widget.van.vanName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(widget.van.plateNumber,
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text(
                            '${CurrencyFormatter.formatPesoWithDecimals(widget.van.pricePerDay)} per day',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Rental Period',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (widget.van.minRentalDays != null || (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0))
                    Text(
                      [
                        if (widget.van.minRentalDays != null) 'Min: ${widget.van.minRentalDays}d',
                        if (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0) 'Max: ${widget.van.maxRentalDays}d',
                      ].join('  •  '),
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Date selectors
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            // Reset end date if it no longer fits the new range
                            if (_endDate != null) {
                              final minEnd = widget.van.minRentalDays != null
                                  ? date.add(Duration(days: widget.van.minRentalDays! - 1))
                                  : date;
                              // Fix: treat maxRentalDays == 0 as no limit
                              final maxEnd = (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0)
                                  ? date.add(Duration(days: widget.van.maxRentalDays! - 1))
                                  : date.add(const Duration(days: 365));
                              if (_endDate!.isBefore(minEnd) || _endDate!.isAfter(maxEnd)) {
                                _endDate = null;
                              }
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Select date'
                              : DateFormat('MMM dd, yyyy').format(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        if (_startDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a start date first')),
                          );
                          return;
                        }
                        final minEnd = widget.van.minRentalDays != null
                            ? _startDate!.add(
                                Duration(days: widget.van.minRentalDays! - 1))
                            : _startDate!;
                        // Fix: treat maxRentalDays == 0 as no limit
                        final maxEnd = (widget.van.maxRentalDays != null && widget.van.maxRentalDays! > 0)
                            ? _startDate!.add(
                                Duration(days: widget.van.maxRentalDays! - 1))
                            : _startDate!.add(const Duration(days: 365));
                        final initialEnd =
                            (_endDate != null && !_endDate!.isBefore(minEnd) &&
                                    !_endDate!.isAfter(maxEnd))
                                ? _endDate!
                                : minEnd;
                        final date = await showDatePicker(
                          context: context,
                          initialDate: initialEnd,
                          firstDate: minEnd,
                          lastDate: maxEnd,
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event, size: 18),
                        ),
                        child: Text(
                          _endDate == null
                              ? 'Select date'
                              : DateFormat('MMM dd, yyyy').format(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final days = _calculateDays();
                    // Fix: only check if max is set and > 0
                    final exceedsMax = widget.van.maxRentalDays != null && 
                        widget.van.maxRentalDays! > 0 &&
                        days > widget.van.maxRentalDays!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: exceedsMax
                                ? Colors.red.withOpacity(0.1)
                                : const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$days days',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: exceedsMax ? Colors.red : Colors.black87,
                                  )),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Base: ${CurrencyFormatter.formatPesoWithDecimals(widget.van.pricePerDay * days)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: exceedsMax ? Colors.red : Colors.black54),
                                  ),
                                  if (_withDriver)
                                    Text(
                                      'Driver: ${CurrencyFormatter.formatPesoWithDecimals(_driverFee)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  Text(
                                    'Total: ${CurrencyFormatter.formatPesoWithDecimals(_calculateTotal())}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: exceedsMax
                                            ? Colors.red
                                            : const Color(0xFF2196F3)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (exceedsMax)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Exceeds maximum rental period of ${widget.van.maxRentalDays} days',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),
              const Text('Contact & Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pickup Location — read-only, set by admin
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pickup Location',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 2),
                          Text(
                            widget.van.pickupLocation?.isNotEmpty == true
                                ? widget.van.pickupLocation!
                                : 'Not specified by admin',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _dropoffController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter full name of the renter',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Text('Driver Option',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: _withDriver
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300]!,
                        width: _withDriver ? 1.5 : 1)),
                child: CheckboxListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  value: _withDriver,
                  onChanged: (val) => setState(() => _withDriver = val ?? false),
                  activeColor: const Color(0xFF2196F3),
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  title: const Text('With Driver',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _withDriver
                        ? 'Driver fee: ${CurrencyFormatter.formatPesoWithDecimals(_driverFee)} added to total'
                        : 'Add a professional driver (+₱1,000.00)',
                    style: TextStyle(
                        fontSize: 12,
                        color: _withDriver
                            ? const Color(0xFF2196F3)
                            : Colors.grey[600]),
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: _withDriver
                        ? const Color(0xFF2196F3).withOpacity(0.1)
                        : Colors.grey[100],
                    child: Icon(Icons.person_pin_circle_outlined,
                        color: _withDriver
                            ? const Color(0xFF2196F3)
                            : Colors.grey[500]),
                  ),
                ),
              ),

              // Driver's license upload — shown only for self-drive
              if (!_withDriver) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _driverLicenseBase64 == null
                          ? Colors.orange[300]!
                          : Colors.green[400]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: _driverLicenseBase64 == null
                                ? Colors.orange[700]
                                : Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Driver's License",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _driverLicenseBase64 == null
                                  ? Colors.orange[800]
                                  : Colors.green[800],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(Required for Self-Drive)',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_driverLicenseBase64 != null) ...[
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green[600], size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _driverLicenseFileName ?? 'File attached',
                                style: TextStyle(
                                    color: Colors.green[700], fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _driverLicenseBase64 = null;
                                _driverLicenseFileName = null;
                              }),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Remove',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Attach a clear photo or scan of your driver\'s license.\nAccepted: JPG, PNG, PDF — Max 10 MB',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDriverLicense,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Choose File'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[700],
                              side: BorderSide(color: Colors.orange[400]!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text('Additional Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Purpose dropdown
              DropdownButtonFormField<String>(
                value: _selectedPurpose,
                decoration: const InputDecoration(
                  labelText: 'Purpose *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                items: _purposeOptions.map((purpose) {
                  return DropdownMenuItem(
                    value: purpose,
                    child: Text(purpose),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPurpose = value;
                    // Clear custom text if switching away from Other
                    if (value != 'Other') {
                      _customPurposeController.clear();
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a purpose';
                  }
                  return null;
                },
              ),
              
              // Show custom purpose field when "Other" is selected
              if (_selectedPurpose == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customPurposeController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify purpose',
                    hintText: 'Enter custom purpose',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (_selectedPurpose == 'Other' && (value == null || value.isEmpty)) {
                      return 'Please specify the purpose';
                    }
                    return null;
                  },
                ),
              ],

              // Proof of Purpose attachment
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _proofOfPurposeBase64 == null
                      ? Colors.purple[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _proofOfPurposeBase64 == null
                        ? Colors.purple[300]!
                        : Colors.green[400]!,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_copy_outlined,
                          color: _proofOfPurposeBase64 == null
                              ? Colors.purple[700]
                              : Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Proof of Purpose',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _proofOfPurposeBase64 == null
                                ? Colors.purple[800]
                                : Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(Required)',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_proofOfPurposeBase64 != null) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green[600], size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _proofOfPurposeFileName ?? 'File attached',
                              style: TextStyle(
                                  color: Colors.green[700], fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _proofOfPurposeBase64 = null;
                              _proofOfPurposeFileName = null;
                            }),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Remove',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'Attach a document supporting your trip purpose\n(e.g., itinerary, invitation letter, booking confirmation).\nAccepted: JPG, PNG, PDF — Max 10 MB',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickProofOfPurpose,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Choose File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple[700],
                            side: BorderSide(color: Colors.purple[400]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Deposit Summary Card ──────────────────────────────────
              if (_startDate != null && _endDate != null) ...[  
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Color(0xFF2196F3), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Rental Cost Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCostRow(
                        'Base Rental (${_calculateDays()} day${_calculateDays() == 1 ? '' : 's'})',
                        CurrencyFormatter.formatPesoWithDecimals(
                            widget.van.pricePerDay * _calculateDays()),
                      ),
                      if (_withDriver)
                        _buildCostRow(
                          'Driver Fee',
                          CurrencyFormatter.formatPesoWithDecimals(_driverFee),
                        ),
                      const Divider(height: 20),
                      _buildCostRow(
                        'Total Rental Price',
                        CurrencyFormatter.formatPesoWithDecimals(_calculateTotal()),
                        bold: true,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[400]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 16, color: Colors.amber[800]),
                                const SizedBox(width: 6),
                                Text(
                                  'Required Deposit (50%)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.formatPesoWithDecimals(
                                  _calculateDeposit()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* A 50% deposit is required upon approval of your rental request.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _showTermsAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Submit Request',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? Colors.black87 : Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? const Color(0xFF2196F3) : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> points,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(p,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[800], height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
