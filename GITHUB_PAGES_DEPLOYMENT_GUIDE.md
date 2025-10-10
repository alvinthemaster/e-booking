# 🚀 **UVexpress E-Ticket GitHub Pages Deployment Guide**

## 📋 **Complete External Setup Instructions**

Follow these step-by-step instructions to deploy your UVexpress e-ticket confirmation system using GitHub Pages hosting.

---

## 🔧 **Prerequisites**

Before starting, ensure you have:
- ✅ GitHub account
- ✅ Your Firebase project credentials
- ✅ Git installed on your computer
- ✅ Code editor (VS Code recommended)

---

## 📁 **Step 1: Prepare Your Repository**

### **Option A: Use Your Existing Repository (Recommended)**

1. **Navigate to your repository**:
   ```
   https://github.com/alvinthemaster/e-booking
   ```

2. **Go to Settings**:
   - Click the **Settings** tab in your repository
   - Scroll down to **Pages** section (left sidebar)

3. **Enable GitHub Pages**:
   - Under **Source**, select **Deploy from a branch**
   - Choose **main** branch
   - Select **/ (root)** folder
   - Click **Save**

4. **Your confirmation page will be available at**:
   ```
   https://alvinthemaster.github.io/e-booking/web/confirm.html
   ```

### **Option B: Create Dedicated Repository**

1. **Create new repository**:
   - Go to GitHub.com
   - Click **New repository**
   - Name: `uvexpress-confirmation`
   - Make it **Public** (required for free GitHub Pages)
   - Initialize with README

2. **Enable GitHub Pages**:
   - Go to repository **Settings** → **Pages**
   - Select **Deploy from a branch** → **main** → **/ (root)**
   - Click **Save**

3. **Your page will be at**:
   ```
   https://alvinthemaster.github.io/uvexpress-confirmation/
   ```

---

## 🔥 **Step 2: Get Your Firebase Configuration**

### **2.1: Access Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your UVexpress project
3. Click the **gear icon** (Project Settings)

### **2.2: Get Web App Config**
1. Scroll to **Your apps** section
2. If you have a web app, click the **config** icon (`</>`)
3. If no web app exists:
   - Click **Add app** → **Web** 
   - App nickname: `UVexpress Web Confirmation`
   - **Don't** check Firebase Hosting
   - Click **Register app**

### **2.3: Copy Configuration**
Copy the `firebaseConfig` object that looks like this:
```javascript
const firebaseConfig = {
  apiKey: "AIzaSy...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id", 
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abc123def456"
};
```

**⚠️ IMPORTANT**: Keep this configuration secure but note it needs to be in your web page for it to work.

---

## 📝 **Step 3: Update Your Web Confirmation Page**

### **3.1: Edit Firebase Configuration**
Open your `/web/confirm.html` file and update this section:

```javascript
// 🔥 REPLACE WITH YOUR ACTUAL FIREBASE CONFIG  
const firebaseConfig = {
    apiKey: "YOUR_ACTUAL_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com", 
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```

### **3.2: Customize Conductor PIN (Optional)**
Change the default PIN from `2024`:
```javascript
// UVexpress Conductor PIN (Change this for production!)
const CONDUCTOR_PIN = 'YOUR_NEW_PIN'; // Must be 4 digits
```

### **3.3: Test Locally (Optional)**
Before deploying, test locally:
```bash
cd C:\Users\yourb\OneDrive\Documents\GitHub\e-booking\web
python -m http.server 8000
```
Visit: `http://localhost:8000/confirm.html?token=test`

---

## 🚀 **Step 4: Deploy to GitHub Pages**

### **Method A: Using Git Commands**

1. **Open terminal in your project folder**:
   ```bash
   cd C:\Users\yourb\OneDrive\Documents\GitHub\e-booking
   ```

2. **Add and commit changes**:
   ```bash
   git add .
   git commit -m "Add UVexpress web confirmation system"
   git push origin main
   ```

3. **GitHub Pages will automatically deploy** (takes 1-10 minutes)

### **Method B: Using GitHub Web Interface**

1. **Go to your repository** on GitHub.com
2. **Navigate to `/web/` folder**
3. **Click on `confirm.html`**
4. **Click the pencil icon** (Edit this file)
5. **Update the Firebase configuration**
6. **Scroll down to commit changes**
7. **Commit title**: `Update Firebase config for UVexpress`
8. **Click "Commit changes"**

---

## 🔐 **Step 5: Configure Firebase Security**

### **5.1: Update Firestore Rules**
1. **Go to Firebase Console** → **Firestore Database** → **Rules**
2. **Replace existing rules** with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow web access to confirmation tokens
    match /confirmation_tokens/{tokenId} {
      allow read, write;
    }
    
    // Allow reading bookings and updating confirmation status
    match /bookings/{bookingId} {
      allow read;
      allow update: if request.resource.data.keys().hasAny([
        'bookingStatus', 'confirmationStatus', 'confirmedBy', 'confirmedAt'
      ]);
    }
    
    // Keep your existing rules for other collections
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. **Click "Publish"**

### **5.2: Enable Web Domain**
1. **Go to Authentication** → **Settings** → **Authorized domains**
2. **Add your GitHub Pages domain**:
   ```
   alvinthemaster.github.io
   ```
3. **Click "Add domain"**

---

## 🧪 **Step 6: Test Your Deployment**

### **6.1: Basic Connectivity Test**
1. **Visit your deployed page**:
   ```
   https://alvinthemaster.github.io/e-booking/web/confirm.html?token=test
   ```

2. **Expected results**:
   - ✅ Page loads with UVexpress branding
   - ✅ Shows "Invalid Token" error (expected for test token)
   - ✅ No JavaScript console errors
   - ✅ Mobile-responsive design

### **6.2: Real Token Test**
1. **Book a test ticket** in your UVexpress app
2. **Go to Firestore Console** → **bookings** collection
3. **Find your booking** and copy the `confirmationToken` value
4. **Visit**: `https://alvinthemaster.github.io/e-booking/web/confirm.html?token=COPIED_TOKEN`
5. **Verify**:
   - ✅ Passenger details load correctly
   - ✅ PIN field accepts 4 digits
   - ✅ Conductor PIN `2024` works
   - ✅ Booking status updates to "onboard"

### **6.3: QR Code Scanning Test**
1. **Generate QR code** with your URL
2. **Scan with smartphone camera**
3. **Tap notification** to open page
4. **Test full confirmation workflow**

---

## 📱 **Step 7: Update Your Flutter App**

Your Flutter app should already be configured, but verify the base URL:

```dart
// In lib/services/web_confirmation_service.dart
class WebConfirmationService {
  static const String baseUrl = 'https://alvinthemaster.github.io/e-booking/web';
  
  // Generate confirmation URL  
  String generateConfirmationUrl(String token) {
    return '$baseUrl/confirm.html?token=$token';
  }
}
```

---

## 🔧 **Step 8: Production Configuration**

### **8.1: Change Default PIN**
For security, change the conductor PIN:

**In your web page** (`confirm.html`):
```javascript
const CONDUCTOR_PIN = 'YOUR_SECURE_PIN'; // 4 digits
```

**In your Flutter app** (`web_confirmation_service.dart`):
```dart
static const String conductorPin = 'YOUR_SECURE_PIN';
```

### **8.2: Custom Domain (Optional)**
1. **Purchase domain** (e.g., `uvexpress.com`)
2. **Add CNAME file** to your repository root:
   ```
   uvexpress.com
   ```
3. **Configure DNS** with your domain provider
4. **Update base URL** in your Flutter app

### **8.3: Monitor Usage**
- **Check Firebase Console** → **Firestore** for confirmation activity
- **Monitor GitHub Pages** for uptime
- **Review browser console** for any JavaScript errors

---

## 🚨 **Troubleshooting Common Issues**

### **GitHub Pages Not Working**
- ✅ Ensure repository is public
- ✅ Check Settings → Pages is enabled
- ✅ Wait 10-15 minutes for deployment
- ✅ Verify file path: `/web/confirm.html`

### **Firebase Connection Issues**
- ✅ Double-check Firebase configuration
- ✅ Ensure Firestore rules allow web access
- ✅ Add GitHub Pages domain to authorized domains
- ✅ Check browser console for detailed errors

### **QR Code Scanning Issues**
- ✅ Ensure HTTPS (GitHub Pages provides this)
- ✅ Test on different devices/browsers
- ✅ Verify QR code contains correct URL
- ✅ Check camera permissions

### **PIN Not Working**
- ✅ Ensure PIN is exactly 4 digits
- ✅ Verify PIN matches in both web page and Flutter app
- ✅ Check for typos in configuration

---

## ✅ **Deployment Checklist**

- [ ] GitHub Pages enabled and deployed
- [ ] Firebase configuration updated in web page
- [ ] Firestore security rules configured
- [ ] Authorized domains added in Firebase
- [ ] Test deployment with sample token
- [ ] Conductor PIN changed from default
- [ ] QR code scanning tested on mobile
- [ ] Full confirmation workflow verified
- [ ] Flutter app base URL updated
- [ ] Production monitoring setup

---

## 📞 **Support Information**

### **For Technical Issues**:
- **GitHub Pages Status**: [githubstatus.com](https://githubstatus.com)
- **Firebase Status**: [status.firebase.google.com](https://status.firebase.google.com)
- **Browser Console**: Press F12 to check for JavaScript errors

### **For Conductor Training**:
- **Default PIN**: `2024`
- **Process**: Scan → Tap → PIN → Confirm
- **Support URL**: `https://alvinthemaster.github.io/e-booking/web/confirm.html`

---

## 🎉 **Success!**

Once completed, your UVexpress e-ticket confirmation system will be:
- ✅ **Hosted on GitHub Pages** (free, reliable, HTTPS)
- ✅ **Accessible via any smartphone** camera
- ✅ **Integrated with Firebase** for real-time updates
- ✅ **Secure with PIN protection** for conductors
- ✅ **Production-ready** for live passenger operations

**Your confirmation URL**: `https://alvinthemaster.github.io/e-booking/web/confirm.html`

Conductors can now scan passenger QR codes with any smartphone camera to confirm boarding! 🚌📱✨