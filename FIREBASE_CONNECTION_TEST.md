# Firebase Connection Test Guide

## How to Test Firebase Connection

### Option 1: Run the App (Recommended)
The app will automatically test the Firebase connection on startup and print the results to the console.

```powershell
# Run on Windows
flutter run -d windows

# Or run on Android (if you have a device/emulator)
flutter run -d android

# Or run on Chrome
flutter run -d chrome
```

### Option 2: Check the Console Output
When the app starts, look for this output in the terminal:

```
🔍 Testing Firebase Connection...
============================================================
FIREBASE CONNECTION TEST REPORT
============================================================
✅ Firebase Initialized: YES
📱 Project ID: e-ticket-2e8d0
🔑 API Key: AIzaSyA9L9u7hTM5ivm1...
✅ Firestore Connected: YES
📚 Collections Available:
  - bookings: ✓
  - vans: ✓
  - routes: ✓
✅ Firebase Auth: YES
👤 User: [your email or "Not signed in"]
============================================================
```

### What the Test Checks:

1. **Firebase App Initialization** ✅
   - Verifies Firebase SDK is properly configured
   - Shows your project ID and API key
   - Confirms connection to the correct Firebase project

2. **Firestore Database Connection** ✅
   - Tests if app can connect to Firestore
   - Checks if required collections exist (bookings, vans, routes)
   - Verifies read/write permissions

3. **Firebase Authentication** ✅
   - Checks if Auth is initialized
   - Shows current signed-in user (if any)

### Expected Results:

#### ✅ Success (Everything Working):
```
✅ Firebase Initialized: YES
📱 Project ID: e-ticket-2e8d0
✅ Firestore Connected: YES
✅ Firebase Auth: YES
```

#### ❌ Connection Issues:
If you see errors like:
- `❌ Firestore Connected: NO` → Check internet connection or Firebase rules
- `❌ Firebase Initialized: NO` → Check firebase_options.dart configuration
- `Firestore connection timeout` → Check network connectivity

### Current Configuration:

**Project Details:**
- Project ID: `e-ticket-2e8d0`
- API Key: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`
- App ID (Android): `1:774845116609:android:1136a5b7b1bcfdf0bc6440`
- Email: `godtrascoeticketsystem@gmail.com`

**Files Updated:**
1. ✅ `lib/firebase_options.dart` - Flutter Firebase configuration
2. ✅ `android/app/google-services.json` - Android Firebase configuration
3. ✅ `lib/main.dart` - Added connection test on startup
4. ✅ `lib/services/firebase_connection_test.dart` - Connection test utility

### Troubleshooting:

If connection fails:

1. **Check Internet Connection**
   - Ensure you have active internet connection
   - Try accessing firebase.google.com in browser

2. **Verify Firebase Project Settings**
   - Go to Firebase Console: https://console.firebase.google.com/
   - Select project: `e-ticket-2e8d0`
   - Check if Firestore is enabled
   - Check if Authentication is enabled

3. **Verify API Key**
   - In Firebase Console → Project Settings
   - Check if the API key matches: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`

4. **Check Firestore Security Rules**
   - Rules should allow read/write for authenticated users
   - Test rules in Firebase Console

### Quick Test Command:

```powershell
# Clean and run fresh
flutter clean
flutter pub get
flutter run -d windows
```

Then watch the console output for the connection test report!
