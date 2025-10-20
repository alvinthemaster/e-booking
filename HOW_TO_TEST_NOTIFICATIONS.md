# 🔔 Push Notification Testing Guide

## ✅ You Have: Android API Key
**Key**: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`

This is your **Google Cloud API Key**. To use it for push notifications, you need to:

---

## 🚀 Step 1: Enable Firebase Cloud Messaging API

### Option A: Via Google Cloud Console (Recommended)

1. **Go to Google Cloud Console**:
   - https://console.cloud.google.com/apis/library/fcm.googleapis.com

2. **Select Your Project**:
   - Choose the project linked to your Android API key

3. **Enable Firebase Cloud Messaging API**:
   - Click the blue **"ENABLE"** button
   - Wait 1-2 minutes for activation

4. **Verify**:
   - Go to https://console.cloud.google.com/apis/dashboard
   - Search for "Firebase Cloud Messaging API"
   - Should show as "Enabled"

### Option B: Via Firebase Console

1. **Go to Firebase Console**:
   - https://console.firebase.google.com/

2. **Select Your Project** → **Project Settings** (⚙️ icon)

3. **Cloud Messaging Tab**:
   - Scroll to "Cloud Messaging API (Legacy)"
   - Click "Manage API in Google Cloud Console"
   - Click "ENABLE"

---

## 🧪 Step 2: Test Using Firebase Console (Easiest Method)

Since the API might not be enabled yet for the key, use Firebase Console directly:

1. **Open Firebase Console**:
   - https://console.firebase.google.com/

2. **Navigate to Cloud Messaging**:
   - Click "Cloud Messaging" in left sidebar
   - Click "Send your first message" or "New campaign"

3. **Create Test Notification**:
   ```
   Notification title: Your Van is Full!
   Notification text: Van TEST1 is departing in 15 minutes.
   ```

4. **Send Test Message**:
   - Click "Send test message"
   - Enter your FCM token:
     ```
     dEhLs3boSH-5PETlxUQr3N:APA91bGfT22m868ZB7B4sFrlGflE4x_lPCNhNcqlAFws8F1G77RvYUqMst9Y1LyCKEzUtEn-8v9kFwTcscNhhPh1pxpc-gxHWu9y4evXc8GOaif6-TQXYXg
     ```
   - Click "Test"

5. **Expected Result**:
   - Notification appears on your device!
   - Console shows: "NotificationService: Foreground message received"

---

## 🔑 Step 3: Get Server Key (For API Testing)

The Android API key you have might not have FCM permissions. You need the **Server Key**:

1. **Firebase Console** → Your Project → **Project Settings** (⚙️)

2. **Cloud Messaging Tab**:
   - Scroll to "Cloud Messaging API (Legacy)"
   - Copy the **"Server key"** (starts with `AAAA...`)

3. **Use This Server Key** in API calls instead of your Android key

---

## 🎯 Step 4: Test with Correct Server Key

Once you have the Server Key, update the PowerShell script:

```powershell
# Replace with your actual Server Key from Firebase Console
$API_KEY = "AAAA..." # Server key (not Android key)
$FCM_TOKEN = "dEhLs3boSH-5PETlxUQr3N:APA91bGfT22m868ZB7B4sFrlGflE4x_lPCNhNcqlAFws8F1G77RvYUqMst9Y1LyCKEzUtEn-8v9kFwTcscNhhPh1pxpc-gxHWu9y4evXc8GOaif6-TQXYXg"

$headers = @{
    "Authorization" = "key=$API_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    to = $FCM_TOKEN
    notification = @{
        title = "Van Full Alert!"
        body = "Your van is departing in 15 minutes."
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" -Method Post -Headers $headers -Body $body
```

---

## 📊 Quick Comparison

| Key Type | Purpose | Where to Find |
|----------|---------|---------------|
| **Android API Key** | For Android app authentication | Google Cloud Console |
| **Server Key** | For sending push notifications from server/scripts | Firebase Console → Cloud Messaging |
| **FCM Token** | Unique device identifier | App console logs |

---

## ✅ Recommended Testing Flow

### 1. **Test via Firebase Console** (No keys needed)
   - Easiest and fastest method
   - Works immediately
   - Good for validating app configuration

### 2. **Test via App Flow** (Real scenario)
   - Create booking in Firestore
   - Fill van to capacity
   - Automatic notifications

### 3. **Test via API** (For automation)
   - Get Server Key from Firebase
   - Use PowerShell/curl/Postman
   - Good for integration testing

---

## 🎯 What to Do RIGHT NOW

### Immediate Testing (No API key needed):

1. **Keep your app running**

2. **Open Firebase Console**:
   - https://console.firebase.google.com/project/e-ticket-2e8d0/notification

3. **Click "New campaign" → Notifications**

4. **Fill in**:
   - Title: `Your Van is Full!`
   - Text: `Departing in 15 minutes`

5. **Click "Send test message"**

6. **Add FCM token** from your console logs

7. **Click "Test"**

8. **Check your device** - notification should appear!

---

## 🔍 Alternative: Test Real Flow

Instead of API testing, test the actual user flow:

### Create Test Booking:

1. **Firebase Console** → **Firestore** → **bookings** collection

2. **Add document** with these fields:
   ```
   userId: "6E9SQ9yWSDN51g9vaW4Q0RB8fc93"
   bookingStatus: "confirmed"
   vanPlateNumber: "TEST2"
   bookingDate: [current timestamp]
   routeId: "SCLRIO5R1ckXKwz2ykxd"
   seatNumbers: ["A1"]
   passengerName: "Test User"
   totalAmount: 165
   ```

3. **Fill the van**:
   - Go to **vans** collection → Find TEST2
   - Change `currentOccupancy` to `18`
   - OR change `status` to `"full"`

4. **Expected Results**:
   - ✅ Immediate notification appears
   - ✅ Widget shows on home screen
   - ✅ After 15 minutes: Reminder notification

---

## 📝 Summary

**Your Android API Key**: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`

**Best Testing Method**:
1. ✅ Use Firebase Console to send test messages (recommended)
2. ✅ Create test booking and fill van (tests full flow)
3. ⏳ Get Server Key for API testing (optional, for automation)

**Firebase Console Test Link**:
https://console.firebase.google.com/project/e-ticket-2e8d0/notification/compose

**Your FCM Token** (for testing):
```
dEhLs3boSH-5PETlxUQr3N:APA91bGfT22m868ZB7B4sFrlGflE4x_lPCNhNcqlAFws8F1G77RvYUqMst9Y1LyCKEzUtEn-8v9kFwTcscNhhPh1pxpc-gxHWu9y4evXc8GOaif6-TQXYXg
```

---

**Next Action**: Go to Firebase Console and send a test notification! 🚀
