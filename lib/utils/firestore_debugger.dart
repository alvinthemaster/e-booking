import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Debug utility to check Firestore van documents and identify indexing issues
class FirestoreDebugger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check all vans in Firestore and their fields
  static Future<void> debugVansCollection() async {
    try {
      debugPrint('\n' + '=' * 80);
      debugPrint('🔍 FIRESTORE VANS COLLECTION DEBUG');
      debugPrint('=' * 80);

      final vansSnapshot = await _firestore.collection('vans').get();
      
      debugPrint('📊 Total vans in database: ${vansSnapshot.docs.length}');
      
      if (vansSnapshot.docs.isEmpty) {
        debugPrint('⚠️  WARNING: No vans found in Firestore!');
        debugPrint('💡 Run: BookingProvider.initializeSampleVans() to create test data');
        return;
      }

      debugPrint('\n📋 Van Documents:');
      debugPrint('-' * 80);

      for (var doc in vansSnapshot.docs) {
        final data = doc.data();
        debugPrint('\n🚐 Van ID: ${doc.id}');
        debugPrint('   Plate: ${data['plateNumber'] ?? 'N/A'}');
        debugPrint('   Status: ${data['status'] ?? 'N/A'}');
        debugPrint('   Active: ${data['isActive'] ?? 'N/A'}');
        debugPrint('   Current Route ID: ${data['currentRouteId'] ?? 'N/A'}');
        debugPrint('   Occupancy: ${data['currentOccupancy'] ?? 0}/${data['capacity'] ?? 0}');
        debugPrint('   Queue Position: ${data['queuePosition'] ?? 'N/A'}');
        
        // Check for field name mismatches
        if (data.containsKey('routeId') && !data.containsKey('currentRouteId')) {
          debugPrint('   ⚠️  WARNING: Has "routeId" but missing "currentRouteId"');
        }
      }

      debugPrint('\n' + '=' * 80);
      debugPrint('🔍 ROUTES COLLECTION DEBUG');
      debugPrint('=' * 80);

      final routesSnapshot = await _firestore.collection('routes').get();
      debugPrint('📊 Total routes in database: ${routesSnapshot.docs.length}');
      
      if (routesSnapshot.docs.isEmpty) {
        debugPrint('⚠️  WARNING: No routes found in Firestore!');
        return;
      }

      debugPrint('\n📋 Route Documents:');
      debugPrint('-' * 80);

      for (var doc in routesSnapshot.docs) {
        final data = doc.data();
        debugPrint('\n🛣️  Route ID: ${doc.id}');
        debugPrint('   Name: ${data['name'] ?? 'N/A'}');
        debugPrint('   Origin: ${data['origin'] ?? 'N/A'}');
        debugPrint('   Destination: ${data['destination'] ?? 'N/A'}');
        debugPrint('   Active: ${data['isActive'] ?? true}');
      }

      debugPrint('\n' + '=' * 80);
      debugPrint('🔗 VAN-ROUTE MAPPING CHECK');
      debugPrint('=' * 80);

      // Check which vans are assigned to which routes
      final routeIds = routesSnapshot.docs.map((doc) => doc.id).toSet();
      
      for (var vanDoc in vansSnapshot.docs) {
        final data = vanDoc.data();
        final vanRoute = data['currentRouteId'];
        final plateNumber = data['plateNumber'];
        
        if (vanRoute == null) {
          debugPrint('❌ Van $plateNumber: NO ROUTE ASSIGNED');
        } else if (!routeIds.contains(vanRoute)) {
          debugPrint('❌ Van $plateNumber: Route "$vanRoute" DOES NOT EXIST in routes collection');
          debugPrint('   💡 Available routes: ${routeIds.join(', ')}');
        } else {
          debugPrint('✅ Van $plateNumber: Correctly assigned to route "$vanRoute"');
        }
      }

      debugPrint('\n' + '=' * 80);
      debugPrint('📝 INDEX REQUIREMENTS');
      debugPrint('=' * 80);
      debugPrint('For the query to work, you need a composite index on "vans" collection:');
      debugPrint('  1. currentRouteId (Ascending)');
      debugPrint('  2. status (Ascending)');
      debugPrint('\n💡 Create at: https://console.firebase.google.com/project/e-ticket-2e8d0/firestore/indexes');
      debugPrint('=' * 80 + '\n');

    } catch (e) {
      debugPrint('❌ Error debugging Firestore: $e');
    }
  }

  /// Test a specific query to see if it works
  static Future<void> testVanQuery(String routeId) async {
    try {
      debugPrint('\n🧪 TESTING VAN QUERY');
      debugPrint('=' * 80);
      debugPrint('Query: vans where currentRouteId=$routeId AND status=boarding');
      
      final query = await _firestore.collection('vans')
          .where('currentRouteId', isEqualTo: routeId)
          .where('status', isEqualTo: 'boarding')
          .get();
      
      debugPrint('✅ Query executed successfully!');
      debugPrint('📊 Results: ${query.docs.length} van(s) found');
      
      for (var doc in query.docs) {
        final data = doc.data();
        debugPrint('  🚐 ${data['plateNumber']}: ${data['status']} (${data['currentOccupancy']}/${data['capacity']})');
      }
      
      debugPrint('=' * 80 + '\n');
    } catch (e) {
      debugPrint('❌ Query FAILED: $e');
      
      if (e.toString().contains('index')) {
        debugPrint('\n🔥 INDEX ERROR DETECTED!');
        debugPrint('The query requires a composite index.');
        debugPrint('\n📝 Solution:');
        debugPrint('1. Look for a link in the error message above');
        debugPrint('2. Click the link to auto-create the index');
        debugPrint('3. Wait 1 minute for index to build');
        debugPrint('4. Try again');
      }
      
      debugPrint('=' * 80 + '\n');
    }
  }
}
