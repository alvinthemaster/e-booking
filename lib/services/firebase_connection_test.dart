import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseConnectionTest {
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};
    
    try {
      // 1. Check Firebase App initialization
      final app = Firebase.app();
      results['initialized'] = true;
      results['appName'] = app.name;
      results['projectId'] = app.options.projectId;
      results['apiKey'] = app.options.apiKey;
      results['messagingSenderId'] = app.options.messagingSenderId;
      results['storageBucket'] = app.options.storageBucket;
      
      debugPrint('✅ Firebase App Initialized');
      debugPrint('📱 App Name: ${app.name}');
      debugPrint('🔑 Project ID: ${app.options.projectId}');
      debugPrint('🔐 API Key: ${app.options.apiKey}');
      debugPrint('📨 Messaging Sender ID: ${app.options.messagingSenderId}');
      debugPrint('📦 Storage Bucket: ${app.options.storageBucket}');
      
      // 2. Test Firestore connection
      try {
        final firestore = FirebaseFirestore.instance;
        
        // Try to read a collection (this will fail if no internet/wrong credentials)
        await firestore
            .collection('_connection_test')
            .limit(1)
            .get(const GetOptions(source: Source.server))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Firestore connection timeout'),
            );
        
        results['firestoreConnected'] = true;
        results['firestoreLatency'] = 'Connected successfully';
        debugPrint('✅ Firestore Connected');
        
        // Check actual collections
        final bookingsCount = await firestore.collection('bookings').limit(1).get();
        final vansCount = await firestore.collection('vans').limit(1).get();
        final routesCount = await firestore.collection('routes').limit(1).get();
        
        results['collections'] = {
          'bookings': bookingsCount.docs.isNotEmpty,
          'vans': vansCount.docs.isNotEmpty,
          'routes': routesCount.docs.isNotEmpty,
        };
        
        debugPrint('📚 Collections Status:');
        debugPrint('  - Bookings: ${bookingsCount.docs.isNotEmpty ? "Has data" : "Empty"}');
        debugPrint('  - Vans: ${vansCount.docs.isNotEmpty ? "Has data" : "Empty"}');
        debugPrint('  - Routes: ${routesCount.docs.isNotEmpty ? "Has data" : "Empty"}');
        
      } catch (e) {
        results['firestoreConnected'] = false;
        results['firestoreError'] = e.toString();
        debugPrint('❌ Firestore Connection Failed: $e');
      }
      
      // 3. Test Firebase Auth
      try {
        final auth = FirebaseAuth.instance;
        final currentUser = auth.currentUser;
        
        results['authInitialized'] = true;
        results['currentUser'] = currentUser != null ? {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'emailVerified': currentUser.emailVerified,
        } : null;
        
        debugPrint('✅ Firebase Auth Initialized');
        if (currentUser != null) {
          debugPrint('👤 Current User: ${currentUser.email}');
        } else {
          debugPrint('👤 No user currently signed in');
        }
        
      } catch (e) {
        results['authInitialized'] = false;
        results['authError'] = e.toString();
        debugPrint('❌ Firebase Auth Failed: $e');
      }
      
    } catch (e) {
      results['initialized'] = false;
      results['error'] = e.toString();
      debugPrint('❌ Firebase Initialization Failed: $e');
    }
    
    return results;
  }
  
  static void printConnectionReport(Map<String, dynamic> results) {
    debugPrint('\n' + '=' * 60);
    debugPrint('FIREBASE CONNECTION TEST REPORT');
    debugPrint('=' * 60);
    
    if (results['initialized'] == true) {
      debugPrint('✅ Firebase Initialized: YES');
      debugPrint('📱 Project ID: ${results['projectId']}');
      debugPrint('🔑 API Key: ${results['apiKey']?.substring(0, 20)}...');
      
      if (results['firestoreConnected'] == true) {
        debugPrint('✅ Firestore Connected: YES');
        debugPrint('📚 Collections Available:');
        final collections = results['collections'] as Map<String, dynamic>?;
        if (collections != null) {
          collections.forEach((key, value) {
            debugPrint('  - $key: ${value ? "✓" : "✗"}');
          });
        }
      } else {
        debugPrint('❌ Firestore Connected: NO');
        debugPrint('Error: ${results['firestoreError']}');
      }
      
      if (results['authInitialized'] == true) {
        debugPrint('✅ Firebase Auth: YES');
        final user = results['currentUser'];
        if (user != null) {
          debugPrint('👤 User: ${user['email']}');
        } else {
          debugPrint('👤 User: Not signed in');
        }
      } else {
        debugPrint('❌ Firebase Auth: NO');
      }
      
    } else {
      debugPrint('❌ Firebase Initialized: NO');
      debugPrint('Error: ${results['error']}');
    }
    
    debugPrint('=' * 60 + '\n');
  }
}
