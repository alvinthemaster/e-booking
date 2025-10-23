import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_models.dart';
import '../utils/currency_formatter.dart';

class EmailService {
  // SMTP Configuration - IMPORTANT: These need to be configured
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _senderEmail = 'godtrascoeticketsystem@gmail.com'; // Replace with your email
  static const String _senderPassword = 'gtmn iusj effr irmj'; // Gmail App Password
  static const String _senderName = 'GODTRASCO E-Ticket System';

  /// Sends an e-ticket email to the passenger
  /// 
  /// [booking] - The booking details
  /// [qrCodeData] - The QR code string for the ticket
  /// [attachmentPath] - Optional PDF attachment path
  static Future<bool> sendETicketEmail({
    required Booking booking,
    required String qrCodeData,
    String? attachmentPath,
  }) async {
    try {
      // Check if running on web - SMTP doesn't work in browsers
      if (kIsWeb) {
        if (kDebugMode) {
          print('⚠️ Email service not available on web platform (SMTP requires native sockets)');
          print('📧 E-ticket would be sent to: ${booking.userEmail}');
          print('💡 Use mobile/desktop app or implement a backend API for web email functionality');
        }
        return false; // Gracefully fail on web
      }

      // Validate email configuration
      if (_senderEmail == 'YOUR_EMAIL@gmail.com' || _senderPassword == 'YOUR_APP_PASSWORD') {
        throw Exception('Email service not configured. Please update SMTP credentials.');
      }

      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _senderEmail,
        password: _senderPassword,
        ssl: false,
        allowInsecure: false,
      );

      // Generate email content
      final emailContent = _generateEmailTemplate(booking, qrCodeData);

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(booking.userEmail)
        ..subject = 'Your GODTRASCO E-Ticket - Booking #${booking.id.substring(0, 8).toUpperCase()}'
        ..html = emailContent;

      // Add PDF attachment if provided
      if (attachmentPath != null) {
        message.attachments.add(FileAttachment(File(attachmentPath)));
      }

      // Send the email
      final sendReport = await send(message, smtpServer);
      
      if (kDebugMode) {
        print('✅ E-ticket email sent successfully to: ${booking.userEmail}');
        print('📧 Send report: ${sendReport.toString()}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send e-ticket email: $e');
      }
      return false;
    }
  }

  /// Sends a booking confirmation email
  static Future<bool> sendBookingConfirmationEmail({
    required Booking booking,
  }) async {
    try {
      // Validate email configuration
      if (_senderEmail == 'YOUR_EMAIL@gmail.com' || _senderPassword == 'YOUR_APP_PASSWORD') {
        throw Exception('Email service not configured. Please update SMTP credentials.');
      }

      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _senderEmail,
        password: _senderPassword,
        ssl: false,
        allowInsecure: false,
      );

      final emailContent = _generateConfirmationEmailTemplate(booking);

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(booking.userEmail)
        ..subject = 'Booking Confirmation - GODTRASCO #${booking.id.substring(0, 8).toUpperCase()}'
        ..html = emailContent;

      final sendReport = await send(message, smtpServer);
      
      if (kDebugMode) {
        print('Confirmation email sent successfully: ${sendReport.toString()}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send confirmation email: $e');
      }
      return false;
    }
  }

  /// Generates the HTML email template for e-ticket
  static String _generateEmailTemplate(Booking booking, String qrCodeData) {
    final seatNumbers = booking.seatIds.join(', ');
    final departureDate = booking.departureTime.toLocal();
    final formattedDate = '${departureDate.day}/${departureDate.month}/${departureDate.year}';
    final formattedTime = '${departureDate.hour.toString().padLeft(2, '0')}:${departureDate.minute.toString().padLeft(2, '0')}';
    final passengerName = booking.passengerDetails?['name'] ?? booking.userName;

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GODTRASCO E-Ticket</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .email-container {
            background-color: white;
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2196F3, #1976D2);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .header p {
            margin: 10px 0 0 0;
            opacity: 0.9;
            font-size: 16px;
        }
        .content {
            padding: 30px 20px;
        }
        .ticket-info {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            border-left: 4px solid #2196F3;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 8px 0;
            border-bottom: 1px solid #eee;
        }
        .info-row:last-child {
            border-bottom: none;
        }
        .label {
            font-weight: 600;
            color: #555;
        }
        .value {
            color: #2196F3;
            font-weight: 500;
        }
        .qr-section {
            text-align: center;
            margin: 30px 0;
            padding: 20px;
            background-color: #f8f9fa;
            border-radius: 8px;
        }
        .qr-code {
            font-family: monospace;
            background-color: white;
            padding: 15px;
            border-radius: 8px;
            border: 2px dashed #2196F3;
            display: inline-block;
            margin: 10px 0;
            font-size: 14px;
            word-break: break-all;
        }
        .instructions {
            background-color: #e3f2fd;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .instructions h3 {
            color: #1976D2;
            margin-top: 0;
        }
        .instructions ul {
            margin: 10px 0;
            padding-left: 20px;
        }
        .instructions li {
            margin: 8px 0;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid #eee;
        }
        .footer p {
            margin: 5px 0;
            font-size: 14px;
            color: #666;
        }
        .total-amount {
            font-size: 24px;
            font-weight: bold;
            color: #2196F3;
        }
        .status-badge {
            background-color: #4CAF50;
            color: white;
            padding: 6px 12px;
            border-radius: 16px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>🎫 Your E-Ticket is Ready!</h1>
            <p>GODTRASCO Van Reservation System</p>
        </div>

        <div class="content">
            <h2>Hello $passengerName,</h2>
            <p>Thank you for choosing GODTRASCO! Your e-ticket has been generated successfully.</p>

            <div class="ticket-info">
                <h3 style="margin-top: 0; color: #2196F3;">🚐 Trip Details</h3>
                
                <div class="info-row">
                    <span class="label">Booking ID:</span>
                    <span class="value">#${booking.id.substring(0, 8).toUpperCase()}</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Route:</span>
                    <span class="value">${booking.routeName}</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Departure Date:</span>
                    <span class="value">$formattedDate</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Departure Time:</span>
                    <span class="value">$formattedTime</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Seat Number(s):</span>
                    <span class="value">$seatNumbers</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Passenger Name:</span>
                    <span class="value">$passengerName</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Total Amount:</span>
                    <span class="value total-amount">${CurrencyFormatter.formatPesoWithDecimals(booking.totalAmount)}</span>
                </div>
                
                <div class="info-row">
                    <span class="label">Status:</span>
                    <span class="status-badge">Confirmed</span>
                </div>
            </div>

            <!-- QR Code section temporarily removed -->
            <div style="margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-radius: 8px; border-left: 4px solid #2196F3;">
                <h3 style="color: #2196F3; margin: 0 0 10px 0;">📱 Booking Verification</h3>
                <p style="margin: 0; color: #666;">Show your booking details to the conductor for verification. QR code feature will be available soon.</p>
            </div>

            <div class="instructions">
                <h3>📋 Important Instructions</h3>
                <ul>
                    <li><strong>Arrive Early:</strong> Please arrive at the terminal 15 minutes before departure</li>
                    <li><strong>Bring Valid ID:</strong> Present a government-issued ID for verification</li>
                    <li><strong>Show QR Code:</strong> Display the QR code above to the conductor</li>
                    <li><strong>Keep This Email:</strong> Save this email as your official e-ticket</li>
                    <li><strong>Contact Support:</strong> Call our hotline for any concerns</li>
                </ul>
            </div>

            <p>Have a safe and comfortable journey with GODTRASCO!</p>
        </div>

        <div class="footer">
            <p><strong>GODTRASCO Van Services</strong></p>
            <p>📞 Hotline: +63 XXX XXX XXXX | 📧 support@godtrasco.com</p>
            <p>🌐 Visit our website for more information</p>
            <p style="font-size: 12px; margin-top: 15px;">
                This is an automated email. Please do not reply to this message.
            </p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Generates booking confirmation email template
  static String _generateConfirmationEmailTemplate(Booking booking) {
    final departureDate = booking.departureTime.toLocal();
    final formattedDate = '${departureDate.day}/${departureDate.month}/${departureDate.year}';
    final formattedTime = '${departureDate.hour.toString().padLeft(2, '0')}:${departureDate.minute.toString().padLeft(2, '0')}';
    final seatNumbers = booking.seatIds.join(', ');
    final passengerName = booking.passengerDetails?['name'] ?? booking.userName;

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Booking Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background-color: white; padding: 20px; border: 1px solid #ddd; }
        .footer { background-color: #f8f9fa; padding: 15px; text-align: center; border-radius: 0 0 8px 8px; }
        .info-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .info-table td { padding: 8px; border-bottom: 1px solid #eee; }
        .label { font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Booking Confirmation</h1>
        <p>GODTRASCO Van Reservation System</p>
    </div>
    
    <div class="content">
        <h2>Dear $passengerName,</h2>
        <p>Your booking has been confirmed! Here are your reservation details:</p>
        
        <table class="info-table">
            <tr><td class="label">Booking ID:</td><td>#${booking.id.substring(0, 8).toUpperCase()}</td></tr>
            <tr><td class="label">Route:</td><td>${booking.routeName}</td></tr>
            <tr><td class="label">Date:</td><td>$formattedDate</td></tr>
            <tr><td class="label">Time:</td><td>$formattedTime</td></tr>
            <tr><td class="label">Seats:</td><td>$seatNumbers</td></tr>
            <tr><td class="label">Total Amount:</td><td>${CurrencyFormatter.formatPesoWithDecimals(booking.totalAmount)}</td></tr>
        </table>
        
        <p><strong>Your e-ticket will be sent separately once payment is processed.</strong></p>
        
        <p>Thank you for choosing GODTRASCO!</p>
    </div>
    
    <div class="footer">
        <p>GODTRASCO Van Services | support@godtrasco.com</p>
    </div>
</body>
</html>
    ''';
  }

  /// Tests email configuration
  static Future<bool> testEmailConfiguration() async {
    try {
      if (_senderEmail == 'YOUR_EMAIL@gmail.com' || _senderPassword == 'YOUR_APP_PASSWORD') {
        return false;
      }

      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _senderEmail,
        password: _senderPassword,
        ssl: false,
        allowInsecure: false,
      );

      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(_senderEmail) // Send test email to self
        ..subject = 'GODTRASCO Email Service Test'
        ..html = '''
          <h2>Email Service Test</h2>
          <p>This is a test email to verify GODTRASCO email service configuration.</p>
          <p>If you receive this email, the service is working correctly!</p>
        ''';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Email configuration test failed: $e');
      }
      return false;
    }
  }
}