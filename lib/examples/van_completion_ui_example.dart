// Example usage of the trip completion functionality in a UI context
// This shows how to integrate the completion logic with your existing van management screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/van_provider.dart';
import '../models/booking_models.dart';

/// Example of how to integrate trip completion in your van management UI
class VanManagementIntegrationExample {
  
  /// Complete van trip method (from your provided code, modified for the codebase)
  static Future<void> completeVanTrip(BuildContext context, Van van) async {
    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Completing trip for ${van.plateNumber}...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      final vanProvider = Provider.of<VanProvider>(context, listen: false);
      await vanProvider.completeVanTrip(van.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Trip completed for van ${van.plateNumber}\n• Bookings marked as completed\n• Occupancy reset to 0'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error completing trip: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Example of how to add the trip completion menu item to your PopupMenuButton
  static Widget buildVanPopupMenu(BuildContext context, Van van) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'trip_complete':
            await completeVanTrip(context, van);
            break;
          // Add other menu items here...
        }
      },
      itemBuilder: (BuildContext context) => [
        // Show trip complete option only for vans with passengers
        if (van.currentOccupancy > 0)
          const PopupMenuItem(
            value: 'trip_complete',
            child: Row(
              children: [
                Icon(Icons.flag, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text('Trip Complete'),
              ],
            ),
          ),
        // Add other menu items...
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Van'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Van'),
            ],
          ),
        ),
      ],
      child: Icon(Icons.more_vert),
    );
  }

  /// Check if trip completion is available for a van
  static Future<bool> canCompleteTrip(BuildContext context, String vanId) async {
    try {
      final vanProvider = Provider.of<VanProvider>(context, listen: false);
      return await vanProvider.canCompleteTrip(vanId);
    } catch (e) {
      debugPrint('Error checking trip completion availability: $e');
      return false;
    }
  }

  /// Show confirmation dialog before completing trip
  static Future<bool> showTripCompletionConfirmation(
    BuildContext context,
    Van van,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.flag, color: Colors.green),
              SizedBox(width: 8),
              Text('Complete Trip'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to complete the trip for van ${van.plateNumber}?'),
              SizedBox(height: 16),
              Text(
                'This will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Mark all active bookings as completed'),
              Text('• Reset van occupancy to 0'),
              Text('• Preserve trip history'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current passengers: ${van.currentOccupancy}',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Complete Trip'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Enhanced trip completion with confirmation
  static Future<void> completeVanTripWithConfirmation(
    BuildContext context,
    Van van,
  ) async {
    // Check if trip can be completed
    final canComplete = await canCompleteTrip(context, van.id);
    
    if (!canComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Cannot complete trip: Van has no passengers'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showTripCompletionConfirmation(context, van);
    
    if (confirmed) {
      await completeVanTrip(context, van);
    }
  }
}

/// Example of how to use this in your existing van list widget
class VanListTileExample extends StatelessWidget {
  final Van van;

  const VanListTileExample({super.key, required this.van});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: van.statusColor,
        child: Text(
          van.plateNumber.substring(0, 2),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(van.plateNumber),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver: ${van.driver.name}'),
          Text('Occupancy: ${van.currentOccupancy}/${van.capacity}'),
          Text('Status: ${van.statusDisplay}'),
        ],
      ),
      trailing: VanManagementIntegrationExample.buildVanPopupMenu(context, van),
      onTap: () {
        // Navigate to van details or handle tap
      },
    );
  }
}