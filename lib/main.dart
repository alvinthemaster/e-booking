import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/booking_provider.dart';
import 'providers/seat_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'screens/auth/sign_in_screen.dart';
import 'widgets/user_booking_listener.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/firebase_connection_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    'NotificationService: Handling background message: ${message.messageId}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Verify Firebase initialization
  print(
    'Firebase apps initialized: ${Firebase.apps.map((app) => app.name).toList()}',
  );

  // Test Firebase connection
  print('\n🔍 Testing Firebase Connection...');
  final connectionResults = await FirebaseConnectionTest.testConnection();
  FirebaseConnectionTest.printConnectionReport(connectionResults);

  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const GodtrascoApp());
}

class GodtrascoApp extends StatelessWidget {
  const GodtrascoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => SeatProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Godtrasco booking app',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              scaffoldBackgroundColor: Colors.grey[50],
              textTheme: GoogleFonts.poppinsTextTheme(),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF2196F3)),
                titleTextStyle: GoogleFonts.poppins(
                  color: const Color(0xFF2196F3),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                ),
              ),
            ),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/sign-in': (context) => const SignInScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            // Show sign-in screen if not authenticated, otherwise show home with booking listener
            home: authProvider.isAuthenticated
                ? const UserBookingListener(child: HomeScreen())
                : const SignInScreen(),
          );
        },
      ),
    );
  }
}
