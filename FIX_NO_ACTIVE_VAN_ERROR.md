# 🚨 "No Active Van Available" Error - SOLUTION

## 🔍 Problem Diagnosed

Your error message shows:
```
Booking failed: Failed to create booking: No active van available for this route
```

This is **NOT an index issue**. The app is working correctly - it just can't find any vans with the right status!

---

## ✅ Root Cause

From your app logs earlier, I saw:
```
Processing van document: gvqP2YamJtpLcuMRHwvZ
Raw status from Firestore: in_queue
Skipping non-boarding van: PLATE VAN 1 (Status: in_queue)
```

**The app only books seats on vans with status = "boarding"**

Your van "PLATE VAN 1" has status = **"in_queue"** ❌
But it needs status = **"boarding"** ✅

---

## 🔧 Quick Fix - Update Van Status

### Option 1: Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Login with: **ronamielabrica16@gmail.com**
3. Select project: **e-ticket-ff181**
4. Click **Firestore Database** in left menu
5. Click **Data** tab
6. Find collection: **`vans`**
7. Find document: **`gvqP2YamJtpLcuMRHwvZ`** (or "PLATE VAN 1")
8. Click to edit the document
9. Find field: **`status`**
10. Change value from: `"in_queue"` → **`"boarding"`**
11. Click **Save**

**Result**: Your van will now appear on the home screen and accept bookings! ✅

---

### Option 2: Update Multiple Fields (Recommended)

While you're editing the van document, also update these fields for best results:

```json
{
  "status": "boarding",          // Change from "in_queue"
  "isActive": true,              // Make sure it's true
  "currentRouteId": "SCLRIO5R1ckXKwz2ykxd",  // Your route ID
  "currentOccupancy": 0,         // Start with 0 passengers
  "queuePosition": 1,            // First in queue
  "vehicleType": "van"           // or "bus" depending on your vehicle
}
```

---

## 📊 Van Status Values Explained

The app uses these status values (from admin panel logic):

| Status | Meaning | Accepts Bookings? |
|--------|---------|-------------------|
| **`boarding`** | Van is at terminal, actively accepting passengers | ✅ YES |
| **`in_queue`** | Van is waiting in queue, not yet boarding | ❌ NO |
| **`in_transit`** | Van is traveling to destination | ❌ NO |
| **`completed`** | Van finished the route | ❌ NO |
| **`maintenance`** | Van is under maintenance | ❌ NO |

---

## 🎯 Why This Happens

From your code (`firebase_booking_service.dart` lines 276-282):

```dart
final vansQuery = await _vansCollection
    .where('currentRouteId', isEqualTo: routeId)
    .where('isActive', isEqualTo: true)
    .where('status', isEqualTo: 'boarding') // ← Only "boarding" status!
    .get();
```

The app **only queries vans with status = "boarding"** to prevent booking seats on:
- Vans that are full
- Vans in transit
- Vans in the queue but not yet accepting passengers
- Vans under maintenance

This is correct behavior! Your admin panel should set vans to "boarding" when they're ready to accept passengers.

---

## ✅ Step-by-Step Verification

After updating the van status to "boarding":

1. **Restart your Flutter app**:
   ```powershell
   # Press 'q' to quit
   # Then run:
   flutter run
   ```

2. **Check the home screen**:
   - You should now see "PLATE VAN 1" (or your van name)
   - It should show as available for booking

3. **Try booking**:
   - Select seats
   - Proceed to payment
   - Complete the booking

4. **Check logs**:
   - Should see: `"Found bookable van: PLATE VAN 1"`
   - Should NOT see: `"Skipping non-boarding van"`

---

## 🚐 Add More Vans (Optional)

If you want to add more test vans, go to Firestore → `vans` collection → Add Document:

```json
{
  "plateNumber": "ABC-1234",
  "driverName": "Juan Dela Cruz",
  "currentRouteId": "SCLRIO5R1ckXKwz2ykxd",
  "status": "boarding",
  "isActive": true,
  "vehicleType": "van",
  "capacity": 18,
  "currentOccupancy": 0,
  "queuePosition": 2,
  "departureTime": "2025-10-23T14:00:00Z",
  "createdAt": "2025-10-23T10:00:00Z"
}
```

---

## 🔐 About Indexes

You asked about indexes - **the indexes are fine!** The issue wasn't with database queries failing, it was with no vans matching the query criteria.

However, you should still create the indexes I provided earlier for when you have user bookings:

### Critical Index (for bookings):
- Collection: `bookings`
- Fields: `userId` (Ascending), `bookingDate` (Descending)

This will fix the "query requires an index" warning when users view their booking history.

**Create it here**: [Create Booking Index](https://console.firebase.google.com/v1/r/project/e-ticket-ff181/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9lLXRpY2tldC1mZjE4MS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYm9va2luZ3MvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDwoLYm9va2luZ0RhdGUQAhoMCghfX25hbWVfXxAC)

---

## 📝 Summary

**Current Issue**: ❌ Van status is "in_queue" instead of "boarding"

**Solution**: ✅ Change van status to "boarding" in Firestore Console

**Time to Fix**: ⏱️ 2 minutes

**After Fix**:
- ✅ Van appears on home screen
- ✅ Booking works
- ✅ Seat selection works
- ✅ Payment can be processed
- ✅ E-tickets generated

---

## 💡 Pro Tip

In a production environment, your **admin web panel** should handle van status changes automatically:
- When a van arrives at terminal → Set to "boarding"
- When van is full → Set to "in_transit"
- When van reaches destination → Set to "completed"
- When van returns to terminal → Set to "in_queue" or back to "boarding"

For now, manually changing it in Firestore Console will work perfectly for testing!

---

## ❓ Still Need Help?

If you still see the error after changing the status:

1. **Check these fields** in your van document:
   - `status` = "boarding"
   - `isActive` = true
   - `currentRouteId` = your route ID (probably "SCLRIO5R1ckXKwz2ykxd")
   - `currentOccupancy` < `capacity` (e.g., 0 < 18)

2. **Clear app cache and restart**:
   ```powershell
   flutter clean
   flutter run
   ```

3. **Check Firestore rules** - make sure reads are allowed

Let me know if you need more help! 🚀
