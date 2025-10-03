import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart' as app_auth;

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({super.key});

  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Firebase Email Test',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: authProvider.isLoading ? null : () async {
                print('🧪 Starting email test...');
                final success = await authProvider.signUp(
                  _emailController.text.trim(),
                  _passwordController.text,
                  _nameController.text.trim(),
                  '1234567890', // dummy phone for testing
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created! Check console logs for email verification status.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ?? 'Failed to create account'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: authProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Sign Up + Email Verification'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: authProvider.currentUser == null ? null : () async {
                print('🧪 Testing manual email verification send...');
                final success = await authProvider.sendEmailVerification();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                        ? 'Verification email sent!' 
                        : authProvider.errorMessage ?? 'Failed to send email'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Test Resend Verification Email'),
            ),
            const SizedBox(height: 20),

            if (authProvider.currentUser != null) ...[
              Text('Current User: ${authProvider.currentUser?.email}'),
              Text('Email Verified: ${authProvider.currentUser?.emailVerified}'),
              Text('User ID: ${authProvider.currentUser?.uid}'),
            ],

            const SizedBox(height: 20),

            if (authProvider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${authProvider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}