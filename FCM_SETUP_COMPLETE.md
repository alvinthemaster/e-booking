# 🔔 Firebase Cloud Messaging - Complete Setup Guide

## ✅ Code Implementation Status

**All code changes have been applied to your project:**

1. ✅ **AndroidManifest.xml** updated with FCM service configuration
2. ✅ **colors.xml** created with notification color
3. ✅ **NotificationService** already implemented
4. ✅ **VanFullNotificationService** already implemented
5. ✅ **Background message handler** already configured in main.dart

---

## 🚀 Next Steps: Enable Firebase Cloud Messaging API

### Step 1: Enable Cloud Messaging API in Firebase Console

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Project Settings**
   - Click the ⚙️ gear icon in the left sidebar
   - Select **"Project settings"**

3. **Go to Cloud Messaging Tab**
   - Click on the **"Cloud Messaging"** tab at the top
   - Scroll down to **"Cloud Messaging API (Legacy)"** section

4. **Enable Cloud Messaging API (V1)**
   - Look for a link that says **"Manage API in Google Cloud Console"**
   - Click on it (opens Google Cloud Console in new tab)

5. **In Google Cloud Console**
   - You should see **"Firebase Cloud Messaging API"** page
   - Click the blue **"ENABLE"** button
   - Wait 1-2 minutes for activation
   - You should see "API enabled" confirmation

6. **Return to Firebase Console**
   - Refresh the Cloud Messaging tab
   - Verify API is now enabled

---

## 📱 Step 2: Grant App Permissions on Device

### For Android 13+ (API 33+):

When you first run the app after this update:

1. **Notification Permission Dialog**
   - A popup will appear: *"Allow E-Ticket to send you notifications?"*
   - Tap **"Allow"**
   - This is REQUIRED for notifications to work

2. **Exact Alarm Permission** (Android 12+)
   - Go to **Settings** → **Apps** → **E-Ticket**
   - Tap **"Alarms & reminders"**
   - Enable the toggle
   - This allows scheduled 15-minute departure reminders

3. **Battery Optimization** (Recommended)
   - Go to **Settings** → **Battery** → **Battery optimization**
   - Find **E-Ticket**
   - Select **"Don't optimize"**
   - This ensures notifications work even in background

---

## 🧪 Step 3: Test Notifications

### Method 1: Quick Test from Firebase Console

1. **Open Firebase Console** → Your Project
2. Click **"Cloud Messaging"** in left sidebar
3. Click **"Send your first message"** or **"New campaign"**
4. Fill in the form:
   ```
   Notification title: 🚐 Test Notification
   Notification text: Your van is full and departing soon!
   ```
5. Click **"Send test message"**
6. Copy your **FCM Token** from app console logs
7. Paste token and click **"Test"**
8. ✅ Notification should appear on your device!

### Method 2: Test Through App Flow

1. **Run the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check console for**:
   ```
   ✅ I/flutter: NotificationService: Initialized successfully
   ✅ I/flutter: NotificationService: FCM Token: [your-long-token]
   ```

3. **Create a test booking**:
   - Go to Firebase Console → Firestore → `bookings` collection
   - Add document with these fields:
     ```
     userId: "6E9SQ9yWSDN51g9vaW4Q0RB8fc93"
     bookingStatus: "confirmed"
     vanPlateNumber: "TEST1"
     bookingDate: [current timestamp]
     routeId: "SCLRIO5R1ckXKwz2ykxd"
     seatNumbers: ["A1"]
     passengerName: "Test User"
     totalAmount: 165
     ```

4. **Trigger notification**:
   - Go to Firestore → `vans` collection → Find TEST1
   - Change `currentOccupancy` to `18`
   - OR change `status` to `"full"`
   - Save changes

5. **Expected behavior**:
   - ✅ Immediate notification: "🚐 Van TEST1 is Full!"
   - ✅ Widget appears on home screen with countdown
   - ✅ After 15 minutes: "🚐 Van Departing Soon!"

---

## 🔍 Verification Checklist

After running the app, verify these console logs appear:

```
✅ I/flutter: NotificationService: Initializing Firebase Messaging...
✅ I/flutter: NotificationService: Permission status: AuthorizationStatus.authorized
✅ I/flutter: NotificationService: FCM Token: [token]
✅ I/flutter: NotificationService: Local notifications initialized
✅ I/flutter: NotificationService: Initialized successfully
```

### When van becomes full:
```
✅ I/flutter: 🚐 Van TEST1 detected as FULL - Occupancy: 18/18, Status: "full"
✅ I/flutter: VanFullNotification: Van TEST1 is FULL
✅ I/flutter: 🔔 VanFullNotification: Scheduling notification for booking [ID]
✅ I/flutter: ✅ Immediate notification sent for van TEST1
✅ I/flutter: ⏰ Scheduled 15-minute reminder for van TEST1
```

---

## ❌ Troubleshooting

### Issue 1: "Permission denied" in logs

**Solution**:
1. Uninstall app completely
2. Reinstall with `flutter run`
3. When permission dialog appears, tap **"Allow"**

### Issue 2: No FCM Token appears

**Check**:
1. Device has Google Play Services installed
2. Internet connection is active
3. Firebase project is correctly configured
4. `google-services.json` file exists in `android/app/`

**Fix**:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue 3: Notifications don't appear

**Check these settings on device**:
1. **Settings** → **Apps** → **E-Ticket** → **Notifications** → All enabled
2. **Settings** → **Apps** → **E-Ticket** → **Battery** → Don't optimize
3. **Settings** → **Sound & vibration** → Make sure not in silent mode

### Issue 4: Build fails after changes

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📊 Testing Scenarios

### Scenario 1: Book and Fill Van

1. Book a seat through the app
2. Use admin panel or Firebase to fill van (18/18 seats)
3. ✅ Notification appears immediately
4. ✅ Widget shows on home screen with countdown
5. Wait 15 minutes
6. ✅ Second notification appears: "Van departing soon"

### Scenario 2: Manual Status Change

1. Book a seat
2. Go to Firebase Console → `vans` → TEST1
3. Change `status` to `"full"`
4. ✅ Notification triggers within 2-3 seconds

### Scenario 3: Background Notifications

1. Book a seat
2. **Close the app completely** (swipe away from recent apps)
3. Change van status to full in Firebase
4. ✅ Notification should still appear even when app is closed

---

## 📝 Summary of Changes Made

### Files Modified:

1. **`android/app/src/main/AndroidManifest.xml`**
   - Added FCM service configuration
   - Added notification channel metadata
   - Added notification icon and color metadata

2. **`android/app/src/main/res/values/colors.xml`** (NEW FILE)
   - Created with notification color (#2196F3 - blue)

### Existing Files (Already Configured):

- ✅ `lib/services/notification_service.dart` - Handles FCM and local notifications
- ✅ `lib/services/van_full_notification_service.dart` - Detects full vans
- ✅ `lib/main.dart` - Background message handler configured
- ✅ `pubspec.yaml` - All required packages installed

---

## 🎯 What Happens Now

After you run the app:

1. **On First Launch**:
   - Permission dialog appears
   - FCM token is generated
   - Notification channels are created
   - Real-time listeners activate

2. **When Van Becomes Full**:
   - System detects van is at capacity (18/18)
   - Immediate notification sent to all passengers
   - Widget appears on home screen showing countdown
   - 15-minute reminder is scheduled

3. **User Experience**:
   - Tap notification → Opens app to booking details
   - See countdown widget on home screen
   - Get second notification before departure
   - Know exactly when to be at the terminal

---

## 🚀 Deploy Commands

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run on device
flutter run

# Or create release build
flutter build apk --release
```

---

## ✅ Success Indicators

You'll know everything is working when:

1. **Console shows**:
   ```
   ✅ NotificationService: Initialized successfully
   ✅ FCM Token: [token generated]
   ```

2. **Test notification from Firebase Console** arrives on device

3. **When you fill a van**:
   - Notification appears immediately
   - Widget shows on home screen
   - Countdown timer is ticking

4. **Background notifications** work even when app is closed

---

## 🔐 Firebase Console Access

**Direct Links** (replace with your project ID if different):

- **Cloud Messaging**: https://console.firebase.google.com/project/e-ticket-2e8d0/settings/cloudmessaging
- **Firestore**: https://console.firebase.google.com/project/e-ticket-2e8d0/firestore
- **Test Messages**: https://console.firebase.google.com/project/e-ticket-2e8d0/notification

---

## 📞 Need Help?

If notifications still don't work after following all steps:

1. **Check console logs** - Copy all logs starting with "NotificationService"
2. **Check Firebase Console** - Verify Cloud Messaging API is enabled
3. **Check device settings** - Ensure all permissions are granted
4. **Try test notification** from Firebase Console first

---

**Implementation Status**: ✅ **COMPLETE**  
**Next Action**: Enable Firebase Cloud Messaging API (see Step 1 above)  
**Estimated Time**: 5-10 minutes  

All code is ready - you just need to enable the API in Firebase Console and grant permissions on your device! 🎉
