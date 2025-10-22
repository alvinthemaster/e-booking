# 🔧 BOOKING ERROR FIX - Route Mismatch

## ❌ Problem Identified

Your vans are assigned to the **wrong route**!

From the app logs:
```
Van: PLATE VAN 1, Route: FTz5KprpMPeF930xOEId  ← Wrong route!
Van: PLATE BUS 1, Route: FTz5KprpMPeF930xOEId  ← Wrong route!
Van: PLATE VAN 2, Route: FTz5KprpMPeF930xOEId  ← Wrong route!
```

But when you try to book, the app looks for route:
```
SCLRIO5R1ckXKwz2ykxd  ← The actual route users are booking
```

**Result**: No vans found for the route → "No active van available for this route"

---

## ✅ Solution: Update Van Route IDs

You need to update the `currentRouteId` field for your vans in Firestore.

### Option 1: Firebase Console (Manual - 5 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Login: **ronamielabrica16@gmail.com**
3. Project: **e-ticket-ff181**
4. Navigate to: **Firestore Database** → **Data** tab
5. Open collection: **`vans`**

#### Update each van:

**Van 1: PLATE VAN 1** (Document ID: `gvqP2YamJtpLcuMRHwvZ`)
- Find field: `currentRouteId`
- Change from: `FTz5KprpMPeF930xOEId`
- Change to: **`SCLRIO5R1ckXKwz2ykxd`**
- Verify field: `status` = **`boarding`** (already correct!)
- Click **Save**

**Van 2: PLATE BUS 1** (Document ID: `NQSeoE3QfxRGcF63Xzcg`)
- Find field: `currentRouteId`
- Change from: `FTz5KprpMPeF930xOEId`
- Change to: **`SCLRIO5R1ckXKwz2ykxd`**
- Find field: `status`
- Change to: **`boarding`** (currently "in_queue")
- Click **Save**

**Van 3: PLATE VAN 2** (Document ID: `sMqYxpV8KpmPuhNkGLbd`)
- Find field: `currentRouteId`
- Change from: `FTz5KprpMPeF930xOEId`
- Change to: **`SCLRIO5R1ckXKwz2ykxd`**
- Find field: `status`
- Change to: **`boarding`** (currently "in_queue")
- Click **Save**

---

### Option 2: Quick Script (If you want)

I can create a script to update all vans at once, but manual update is faster for just 3 vans.

---

## 📋 Van Fields Checklist

For each van to accept bookings, make sure these fields are correct:

```json
{
  "currentRouteId": "SCLRIO5R1ckXKwz2ykxd",  // ← Correct route ID
  "status": "boarding",                       // ← Must be "boarding"
  "isActive": true,                           // ← Must be true
  "currentOccupancy": 0,                      // ← Less than capacity
  "capacity": 18                              // ← Or 21 for bus
}
```

---

## 🎯 After Fixing

Once you update the route IDs:

1. **Hot reload the app** (press `r` in the terminal)
2. **Check home screen** - you should see:
   - 🚐 Van: PLATE VAN 1 - Boarding
   - 🚌 Bus: PLATE BUS 1 - Boarding (if you set status to "boarding")
   - 🚐 Van: PLATE VAN 2 - Boarding (if you set status to "boarding")

3. **Try booking again** - it should work! ✅

---

## 🔍 Why This Happened

Your route has ID: `SCLRIO5R1ckXKwz2ykxd`

But your vans were assigned to a different route: `FTz5KprpMPeF930xOEId`

The booking system queries:
```dart
.where('currentRouteId', isEqualTo: 'SCLRIO5R1ckXKwz2ykxd')
.where('status', isEqualTo: 'boarding')
```

Since no vans matched both conditions, booking failed.

---

## ✅ Quick Fix Summary

**Update in Firestore for all 3 vans:**
- `currentRouteId`: Change to `SCLRIO5R1ckXKwz2ykxd`
- `status`: Change to `boarding` (for BUS1 and VAN2)

**Time**: 5 minutes
**Result**: Booking will work! 🎉

---

## 🚨 Common Mistakes to Avoid

❌ Wrong route ID → No vans found  
❌ Status = "in_queue" → Van not accepting bookings  
❌ isActive = false → Van hidden  
❌ currentOccupancy >= capacity → Van shown as full  

✅ Correct all above → Booking works!

---

Let me know once you update the route IDs and I'll help you test!
