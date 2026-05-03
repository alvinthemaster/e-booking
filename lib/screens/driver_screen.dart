import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;

class DriverScreen extends StatelessWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );
    final uid = authProvider.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/sign-in',
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vans')
            .where('driver.id', isEqualTo: uid)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading vehicle data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        size: 46,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Vehicle Assigned',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your account has no vehicle linked yet.\n\nPlease contact the admin to register your vehicle and make sure your driver ID is correctly set.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/sign-in',
                              (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final vanId = doc.id;

          return _DriverVanView(vanId: vanId, data: data);
        },
      ),
    );
  }
}

class _DriverVanView extends StatefulWidget {
  final String vanId;
  final Map<String, dynamic> data;

  const _DriverVanView({required this.vanId, required this.data});

  @override
  State<_DriverVanView> createState() => _DriverVanViewState();
}

class _DriverVanViewState extends State<_DriverVanView> {
  bool _isUpdating = false;
  bool _isSavingSchedule = false;

  // Local editable copy of the weekly schedule
  late Map<String, bool> _localSchedule;

  static const _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];
  static const _dayLabels = {
    'monday': 'Mon', 'tuesday': 'Tue', 'wednesday': 'Wed',
    'thursday': 'Thu', 'friday': 'Fri', 'saturday': 'Sat', 'sunday': 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _initLocalSchedule();
  }

  @override
  void didUpdateWidget(_DriverVanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-init only if weeklySchedule data actually changed
    if (oldWidget.data['weeklySchedule'] != widget.data['weeklySchedule']) {
      _initLocalSchedule();
    }
  }

  void _initLocalSchedule() {
    final raw = widget.data['weeklySchedule'];
    // Support both List<String> (new) and Map<String,bool> (legacy)
    final Set<String> activeDays;
    if (raw is List) {
      activeDays = raw.map((e) => e.toString().toLowerCase()).toSet();
    } else if (raw is Map) {
      activeDays = raw.entries
          .where((e) => e.value == true)
          .map((e) => e.key.toString().toLowerCase())
          .toSet();
    } else {
      activeDays = {};
    }
    _localSchedule = {
      for (final day in _dayOrder) day: activeDays.contains(day),
    };
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSavingSchedule = true);
    try {
      // Save as a List of active day strings to match Firestore format
      final activeDays = _dayOrder
          .where((day) => _localSchedule[day] == true)
          .toList();
      await FirebaseFirestore.instance
          .collection('vans')
          .doc(widget.vanId)
          .update({'weeklySchedule': activeDays});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSchedule = false);
    }
  }

  String get _status => (widget.data['status'] as String? ?? '').toLowerCase();

  /// Fetches all routes and returns the opposite route id
  /// (swapped origin/destination) for the given route id.
  Future<String?> _findOppositeRouteId(String currentRouteId) async {
    try {
      final currentDoc = await FirebaseFirestore.instance
          .collection('routes')
          .doc(currentRouteId)
          .get();
      if (!currentDoc.exists) return null;

      final currentData = currentDoc.data()!;
      final origin = (currentData['origin'] as String? ?? '').toLowerCase().trim();
      final destination = (currentData['destination'] as String? ?? '').toLowerCase().trim();

      // Look for a route where origin == current destination and destination == current origin
      final query = await FirebaseFirestore.instance
          .collection('routes')
          .where('origin', isEqualTo: destination)
          .where('destination', isEqualTo: origin)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) return query.docs.first.id;

      // Fallback: case-insensitive check across all active routes
      final allRoutes = await FirebaseFirestore.instance
          .collection('routes')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in allRoutes.docs) {
        if (doc.id == currentRouteId) continue;
        final d = doc.data();
        final o = (d['origin'] as String? ?? '').toLowerCase().trim();
        final dest = (d['destination'] as String? ?? '').toLowerCase().trim();
        if (o == destination && dest == origin) return doc.id;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _updateStatus(String newStatus,
      {bool clearOccupancy = false}) async {
    setState(() => _isUpdating = true);
    try {
      final Map<String, dynamic> updates = {'status': newStatus};
      if (clearOccupancy) {
        updates['currentOccupancy'] = 0;
        // Swap route to return direction
        final currentRouteId = widget.data['currentRouteId'] as String?;
        if (currentRouteId != null && currentRouteId.isNotEmpty) {
          final oppositeId = await _findOppositeRouteId(currentRouteId);
          if (oppositeId != null) {
            updates['currentRouteId'] = oppositeId;
          }
        }
      }
      await FirebaseFirestore.instance
          .collection('vans')
          .doc(widget.vanId)
          .update(updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'full':
        return Colors.red;
      case 'in_transit':
        return Colors.blue;
      case 'in_queue':
        return Colors.orange;
      case 'boarding':
        return Colors.green;
      case 'maintenance':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'full':
        return 'Full';
      case 'in_transit':
        return 'In Transit';
      case 'in_queue':
        return 'In Queue';
      case 'boarding':
        return 'Boarding';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildRouteCard(String? currentRouteId) {
    if (currentRouteId == null || currentRouteId.isEmpty) {
      return _buildInfoCard(
        icon: Icons.route,
        label: 'Current Route',
        value: 'No route assigned',
        iconColor: Colors.purple,
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('routes')
          .doc(currentRouteId)
          .get(),
      builder: (context, snapshot) {
        String routeName = 'Loading...';
        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          routeName = (d['name'] as String? ?? '').toUpperCase();
          if (routeName.isEmpty) {
            final origin = d['origin'] as String? ?? '';
            final dest = d['destination'] as String? ?? '';
            routeName = '$origin → $dest'.toUpperCase();
          }
        } else if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.exists)) {
          routeName = 'Unknown route';
        }
        return _buildInfoCard(
          icon: Icons.route,
          label: 'Current Route',
          value: routeName,
          iconColor: Colors.purple,
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF2196F3)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF2196F3),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF2196F3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a day to toggle your availability',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dayOrder.map((day) {
              final isActive = _localSchedule[day] ?? false;
              return GestureDetector(
                onTap: () => setState(() => _localSchedule[day] = !isActive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF2196F3)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _dayLabels[day] ?? day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _isSavingSchedule ? null : _saveSchedule,
              icon: _isSavingSchedule
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(_isSavingSchedule ? 'Saving...' : 'Save Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final status = _status;
    final queuePosition = data['queuePosition']?.toString() ?? 'N/A';
    final vehicleType = (data['vehicleType'] as String? ?? 'van')
        .replaceAll('_', ' ')
        .toUpperCase();
    final plateNumber = data['plateNumber'] as String? ?? 'N/A';
    final capacity = data['capacity']?.toString() ?? 'N/A';
    final currentOccupancy = data['currentOccupancy']?.toString() ?? '0';
    final driverData = data['driver'] is Map
        ? Map<String, dynamic>.from(data['driver'] as Map)
        : null;
    final driverName = driverData?['name'] as String? ?? 'N/A';
    final currentRouteId = data['currentRouteId'] as String?;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    vehicleType.toLowerCase().contains('bus')
                        ? Icons.directions_bus
                        : Icons.airport_shuttle,
                    size: 52,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plateNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driverName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: _statusColor(status) == Colors.grey
                            ? Colors.white70
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info grid
            _buildInfoCard(
              icon: Icons.directions_car,
              label: 'Vehicle Type',
              value: vehicleType,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.format_list_numbered,
              label: 'Queue Position',
              value: queuePosition,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.people,
              label: 'Occupancy',
              value: '$currentOccupancy / $capacity',
              iconColor: Colors.green,
            ),
            const SizedBox(height: 10),
            _buildInfoCard(
              icon: Icons.info_outline,
              label: 'Current Status',
              value: _statusLabel(status),
              iconColor: _statusColor(status),
            ),            const SizedBox(height: 10),
            _buildRouteCard(currentRouteId),            const SizedBox(height: 10),

            // Weekly schedule (always editable)
            _buildEditableScheduleCard(),
            const SizedBox(height: 10),

            const SizedBox(height: 6),

            // Action buttons
            if (status == 'full')
              _ActionButton(
                label: 'GO',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFF1565C0),
                isLoading: _isUpdating,
                onPressed: () => _updateStatus('in_transit'),
              ),

            if (status == 'in_transit')
              _ActionButton(
                label: 'Complete Trip',
                icon: Icons.check_circle_outline,
                color: Colors.green.shade700,
                isLoading: _isUpdating,
                onPressed: () =>
                    _updateStatus('in_queue', clearOccupancy: true),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
