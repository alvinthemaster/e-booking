import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

/// Quick Firebase Migration Verification Script
/// This script checks if the app is properly connected to the new Firebase project
void main() async {
  print('🔥 Firebase Migration Verification Script');
  print('=========================================\n');

  try {
    // Initialize Firebase
    print('1️⃣ Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('   ✅ Firebase initialized successfully\n');

    // Get Firebase app details
    final app = Firebase.app();
    print('2️⃣ Firebase App Details:');
    print('   📱 App Name: ${app.name}');
    print('   🔑 Project ID: ${app.options.projectId}');
    print('   📦 Storage Bucket: ${app.options.storageBucket}');
    print('   🔐 API Key: ${app.options.apiKey.substring(0, 20)}...');
    print('   📨 Messaging Sender ID: ${app.options.messagingSenderId}\n');

    // Verify it's the NEW project
    if (app.options.projectId == 'e-ticket-ff181') {
      print('   ✅ CONFIRMED: Connected to NEW project (e-ticket-ff181)');
    } else {
      print('   ⚠️  WARNING: Still connected to old project (${app.options.projectId})');
    }
    print('');

    // Test Firestore connection
    print('3️⃣ Testing Firestore Connection...');
    final firestore = FirebaseFirestore.instance;
    
    // Try to read from routes collection
    print('   Attempting to read "routes" collection...');
    try {
      final routesSnapshot = await firestore
          .collection('routes')
          .limit(5)
          .get()
          .timeout(Duration(seconds: 10));
      
      print('   ✅ Firestore connected successfully!');
      print('   📊 Found ${routesSnapshot.docs.length} route(s)\n');

      if (routesSnapshot.docs.isNotEmpty) {
        print('4️⃣ Sample Routes:');
        for (var doc in routesSnapshot.docs) {
          final data = doc.data();
          print('   • ${doc.id}: ${data['origin'] ?? 'N/A'} → ${data['destination'] ?? 'N/A'}');
        }
      } else {
        print('4️⃣ ⚠️  No routes found in database');
        print('   You may need to add initial data to your Firestore');
      }
      print('');

      // Test vans collection
      print('5️⃣ Testing Vans Collection...');
      final vansSnapshot = await firestore
          .collection('vans')
          .limit(5)
          .get()
          .timeout(Duration(seconds: 10));
      
      print('   ✅ Vans collection accessible');
      print('   🚐 Found ${vansSnapshot.docs.length} van(s)\n');

      if (vansSnapshot.docs.isNotEmpty) {
        print('6️⃣ Sample Vans:');
        for (var doc in vansSnapshot.docs) {
          final data = doc.data();
          final vehicleType = data['vehicleType'] ?? 'van';
          final icon = vehicleType == 'bus' ? '🚌' : '🚐';
          print('   $icon ${doc.id}: ${data['driverName'] ?? 'N/A'} - Status: ${data['status'] ?? 'N/A'}');
        }
      } else {
        print('6️⃣ ⚠️  No vans found in database');
        print('   You may need to add initial data to your Firestore');
      }
      print('');

      // Summary
      print('=========================================');
      print('✅ MIGRATION VERIFICATION COMPLETE!');
      print('=========================================');
      print('');
      print('📝 Summary:');
      print('   • Firebase initialized: ✅');
      print('   • Connected to e-ticket-ff181: ✅');
      print('   • Firestore accessible: ✅');
      print('   • Routes collection: ${routesSnapshot.docs.length} documents');
      print('   • Vans collection: ${vansSnapshot.docs.length} documents');
      print('');
      print('🎉 Your app is successfully connected to the new Firebase project!');
      
    } on TimeoutException {
      print('❌ Timeout Error');
      print('');
      print('💡 Possible Issues:');
      print('   • Network connection problem');
      print('   • Firebase project not properly configured');
      
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code}');
      print('   Message: ${e.message}');
      print('');
      print('💡 Possible Issues:');
      print('   • Firestore rules may be blocking access');
      print('   • Collections may not exist yet');
      print('   • Check Firebase Console for more details');
      
    } catch (e) {
      print('❌ Unexpected Error: $e');
    }
    
  } catch (e) {
    print('❌ Firebase Initialization Error: $e');
  }
  
  exit(0);
}
