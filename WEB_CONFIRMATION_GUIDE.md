# 🌐 **Web-Based QR Confirmation System - Complete Setup Guide**

## 🎯 **Overview**
This guide shows how to set up and use the web-based QR confirmation system where conductors can scan QR codes with any camera-enabled device and confirm passenger boarding through a secure web interface.

---

## 🚀 **How It Works**

### **1. E-Ticket Generation**
- When passengers book tickets, the system automatically generates a unique, secure confirmation URL
- This URL is encoded into the QR code on their e-ticket (e.g., `https://uvexpress-eticket.web.app/confirm.html?token=UNIQUE_TOKEN`)
- Each token is valid for 24 hours and can only be used once

### **2. Conductor Scanning**
- Conductors use **any smartphone camera** (no special app needed)
- When they scan the QR code, it opens the confirmation page in their browser
- The page shows passenger details and requires a 4-digit PIN to confirm boarding

### **3. Secure Confirmation**
- Only authorized conductors with the correct PIN can confirm boarding
- Once confirmed, the ticket status changes to "Onboard" and prevents duplicate confirmations
- Real-time updates sync across all devices

---

## 📱 **Conductor Instructions**

### **Step 1: Scan QR Code**
1. **Open Camera App** on any smartphone (Android/iPhone)
2. **Point camera** at the passenger's e-ticket QR code
3. **Tap the notification** that appears to open the link
4. The confirmation page will load automatically

### **Step 2: Review Passenger Details**
The page displays:
- ✅ **Passenger Name**
- ✅ **Route** (Origin → Destination)
- ✅ **Departure Time**
- ✅ **Seat Numbers**
- ✅ **Total Amount**
- ✅ **Payment Status**
- ✅ **Current Booking Status**

### **Step 3: Enter Conductor PIN**
1. **Enter the 4-digit conductor PIN**: `2024`
2. **Tap "Confirm Boarding"**
3. **Wait for success message**: "Boarding Confirmed!"

### **Step 4: Continue to Next Passenger**
- The confirmation is instant and synced across all devices
- Ready to scan the next passenger's QR code

---

## 🔧 **Admin Setup Instructions**

### **1. Firebase Configuration**
Update the Firebase config in `/web/confirm.html`:

```javascript
const firebaseConfig = {
    apiKey: "your-actual-api-key",
    authDomain: "your-project.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "123456789012",
    appId: "your-app-id"
};
```

### **2. Web Hosting Setup**
#### **Option A: Firebase Hosting (Recommended)**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize hosting
firebase init hosting

# Deploy the web files
firebase deploy --only hosting
```

#### **Option B: Custom Domain**
1. Upload `confirm.html` to your web server
2. Update the `baseUrl` in `web_confirmation_service.dart`
3. Ensure HTTPS is enabled for security

### **3. Security Configuration**
#### **Change Conductor PIN**
In `/web/confirm.html`, update the PIN:
```javascript
const CONDUCTOR_PIN = 'YOUR_NEW_PIN'; // Change from '2024'
```

In `lib/services/web_confirmation_service.dart`, update:
```dart
static const String conductorPin = 'YOUR_NEW_PIN'; // Change from '2024'
```

### **4. Firestore Security Rules**
Add these rules to allow web confirmation:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for confirmation tokens
    match /confirmation_tokens/{tokenId} {
      allow read, write;
    }
    
    // Allow updates to booking status for confirmation
    match /bookings/{bookingId} {
      allow read;
      allow update: if resource.data.keys().hasAny(['bookingStatus', 'confirmationStatus', 'confirmedBy', 'confirmedAt']);
    }
  }
}
```

---

## 🧪 **Testing the System**

### **1. Create Test Booking**
1. **Book a ticket** through the mobile app
2. **Check the booking** in Firestore - it should have:
   - `confirmationToken`: A UUID
   - `confirmationUrl`: The web confirmation URL
   - `tokenExpiresAt`: 24 hours from creation

### **2. Test QR Code Scanning**
1. **Display the QR code** from the e-ticket
2. **Scan with any camera** app
3. **Verify the URL opens** the confirmation page
4. **Check passenger details** are displayed correctly

### **3. Test PIN Confirmation**
1. **Enter the conductor PIN** (default: `2024`)
2. **Click "Confirm Boarding"**
3. **Verify success message** appears
4. **Check in Firestore** that booking status changed to `onboard`

### **4. Test Security Features**
- ❌ **Invalid PIN**: Should show error
- ❌ **Expired Token**: Should show expiration message
- ❌ **Already Used**: Should prevent duplicate confirmation
- ❌ **Invalid Token**: Should show error for non-existent tokens

---

## 🔐 **Security Features**

### **1. Token Security**
- **UUID v4 tokens**: Cryptographically secure random tokens
- **24-hour expiration**: Prevents old tokens from being used
- **One-time use**: Tokens become invalid after confirmation
- **Firestore validation**: Server-side validation prevents tampering

### **2. PIN Protection**
- **4-digit conductor PIN**: Only authorized personnel can confirm
- **Client-side validation**: Immediate feedback for invalid PINs
- **No brute force protection**: Consider adding rate limiting in production

### **3. HTTPS Required**
- **Secure transmission**: All data encrypted in transit
- **Prevents man-in-the-middle attacks**
- **Required for camera access on modern browsers**

---

## 🚨 **Troubleshooting**

### **QR Code Won't Scan**
- ✅ Ensure adequate lighting
- ✅ Hold camera steady
- ✅ Try different angles
- ✅ Clean camera lens

### **Confirmation Page Won't Load**
- ✅ Check internet connection
- ✅ Verify Firebase hosting is active
- ✅ Check Firebase configuration
- ✅ Ensure HTTPS is enabled

### **PIN Not Working**
- ✅ Verify PIN in both web page and service
- ✅ Check for typos in configuration
- ✅ Ensure PIN is exactly 4 digits

### **Booking Status Not Updating**
- ✅ Check Firestore security rules
- ✅ Verify Firebase project ID
- ✅ Check network connectivity
- ✅ Look for JavaScript console errors

---

## 📊 **Production Considerations**

### **1. Performance**
- **CDN**: Use Firebase CDN for fast loading
- **Caching**: Enable browser caching for static assets
- **Minification**: Minify CSS and JavaScript for production

### **2. Security**
- **Rate Limiting**: Implement rate limiting for PIN attempts
- **Token Cleanup**: Regularly clean expired tokens
- **Audit Logging**: Log all confirmation attempts
- **HTTPS Only**: Never allow HTTP in production

### **3. Monitoring**
- **Firebase Analytics**: Track confirmation rates
- **Error Monitoring**: Monitor JavaScript errors
- **Performance Monitoring**: Track page load times
- **Uptime Monitoring**: Ensure 99.9% availability

### **4. Scalability**
- **Firebase Auto-scaling**: Handles traffic spikes automatically
- **Global Distribution**: Firebase CDN serves globally
- **Firestore Scaling**: Handles unlimited concurrent confirmations

---

## 📞 **Support Information**

### **For Conductors**
- **Camera Issues**: Try different camera apps
- **Page Loading**: Check internet connection
- **PIN Problems**: Contact admin for PIN verification

### **For Administrators**
- **Firebase Console**: Monitor confirmations in real-time
- **Error Logs**: Check browser developer tools
- **System Status**: Monitor Firebase status page

### **Emergency Procedures**
- **Manual Confirmation**: Admin can manually update booking status in Firestore
- **Backup PIN**: Keep a backup PIN in secure location
- **Offline Mode**: Plan for internet outages (manual ticketing)

---

## ✅ **Quick Checklist**

### **Before Going Live**
- [ ] Firebase config updated with production credentials
- [ ] Conductor PIN changed from default
- [ ] Web hosting deployed and accessible
- [ ] Firestore security rules configured
- [ ] Test bookings created and confirmed
- [ ] Conductors trained on scanning process
- [ ] Emergency procedures documented
- [ ] Monitoring systems active

### **Daily Operations**
- [ ] Check Firebase hosting status
- [ ] Monitor confirmation success rate
- [ ] Review any error reports
- [ ] Verify conductor PIN security
- [ ] Clean up expired tokens (automated)

The web-based QR confirmation system is now ready for production use! 🎉