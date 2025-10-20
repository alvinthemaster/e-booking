# Van Full Widget - Testing with Admin Panel

## Updated Detection Logic

The widget now detects a van as "full" in **TWO ways**:

### Method 1: Capacity-Based (Automatic)
```dart
currentOccupancy >= capacity
// Example: 18/18 seats booked
```

### Method 2: Status-Based (Manual/Admin) ✅ NEW!
```dart
status == 'full' OR status == 'boarding'
// Admin can manually set van status
```

## Testing Workflow

### Option A: Natural Testing (Full Capacity)
1. Book 18 seats on a van
2. Widget appears automatically
3. Countdown starts

### Option B: Admin Testing (Your Use Case) ✅
1. **Book 1 seat** on any van
2. **Open admin panel**
3. **Change van status** to either:
   - `"full"` (exact match)
   - `"boarding"` (also works)
4. **Open user app**
5. **Widget should appear** immediately!

## Important: Van Status Values

The system checks for these **exact status values** (case-insensitive):

✅ **Will Trigger Widget:**
- `"full"`
- `"Full"`
- `"FULL"`
- `"boarding"`
- `"Boarding"`
- `"BOARDING"`

❌ **Will NOT Trigger:**
- `"in_queue"`
- `"active"`
- `"inactive"`
- `"maintenance"`
- Any other status

## Admin Panel Instructions

### To Manually Mark Van as Full:

**In Firebase Console:**
```javascript
// Navigate to: Firestore Database > vans > [select van]
{
  "plateNumber": "TEST2",
  "status": "full",          // ← Set this to "full" or "boarding"
  "currentOccupancy": 1,     // ← Doesn't matter anymore!
  "capacity": 18,
  "scheduledDepartureTime": [timestamp] // Optional: set departure time
}
```

**In Custom Admin Panel:**
```dart
// Call this method
await FirebaseBookingService().updateVanStatus(vanId, 'full');

// Or
await FirebaseBookingService().updateVanStatus(vanId, 'boarding');
```

## Debug Logs

When testing, watch for these logs:

### Widget Detection:
```
🚐 Van TEST2 detected as FULL - Occupancy: 1/18, Status: "full"
```

### Notification Service:
```
VanFullNotification: Van TEST2 is FULL - Occupancy: 1/18, Status: "full"
🔔 Van status changed to "full" - checking for notifications...
```

### If Not Working:
```
⏳ Van TEST2 not full yet - Occupancy: 1/18, Status: "active"
```

## Quick Test Script

### Test the Widget Manually:

1. **Setup:**
   ```
   - Ensure you have a confirmed booking
   - Note the van's plate number
   ```

2. **Change Status in Firestore:**
   ```javascript
   // In Firestore Console
   vans > [your_van_id] > Edit
   
   status: "full"  // or "boarding"
   
   Save
   ```

3. **Verify:**
   ```
   - Open app (or hot reload if already open)
   - Go to Home screen
   - Widget should appear at the top
   - Should show countdown timer
   ```

4. **Reset for Next Test:**
   ```javascript
   // In Firestore Console
   status: "active"  // or "in_queue"
   
   Save
   ```

## Common Issues & Solutions

### Issue 1: Widget Not Appearing

**Check:**
- [ ] Booking status is "confirmed" (not "pending")
- [ ] Van status is exactly "full" or "boarding" (case doesn't matter)
- [ ] Booking has `vanPlateNumber` field matching the van
- [ ] User is logged in with the account that made the booking

**Solution:**
Run this query in Firestore to verify:
```javascript
bookings
  .where('userId', '==', [your_user_id])
  .where('bookingStatus', '==', 'confirmed')
```

### Issue 2: Wrong Van Showing

**Check:**
- [ ] `booking.vanPlateNumber` matches `van.plateNumber`
- [ ] Multiple confirmed bookings exist (shows most recent)

**Solution:**
Widget shows the **most recent confirmed booking**. Cancel old bookings or ensure correct van is assigned.

### Issue 3: Countdown Not Starting

**Check:**
- [ ] Van has `scheduledDepartureTime` field in Firestore
- [ ] Departure time is in the future

**Solution:**
Set departure time manually:
```javascript
vans > [van_id]

scheduledDepartureTime: [15 minutes from now]
```

Or widget will default to 15 minutes from detection.

## Test Scenarios

### Scenario 1: Admin Sets Van to Full
```
1. User books 1 seat ✅
2. Admin changes van.status to "full" ✅
3. User opens app
4. Widget appears with countdown ✅
```

### Scenario 2: Van Naturally Fills Up
```
1. Users book 17 seats
2. Last user books 18th seat ✅
3. System auto-sets occupancy to 18/18 ✅
4. Widget appears for all users ✅
```

### Scenario 3: Admin Sets to Boarding
```
1. Van has some bookings
2. Admin changes van.status to "boarding" ✅
3. All users with confirmed bookings see widget ✅
```

### Scenario 4: Van Status Reset
```
1. Widget is showing
2. Admin changes van.status to "in_queue"
3. Widget disappears ✅
```

## Automated Testing (Future)

```dart
// Unit test example
test('Widget appears when van status is full', () async {
  // Arrange
  await createBooking(userId: 'test123', status: 'confirmed');
  await setVanStatus(vanId: 'van001', status: 'full');
  
  // Act
  await pumpWidget(VanDepartureCountdownWidget());
  
  // Assert
  expect(find.text('Your Van is Full!'), findsOneWidget);
  expect(find.text('15:00'), findsOneWidget);
});
```

## Production Use

### For Normal Operations:
- Let the system handle automatically
- Widget appears when van reaches 18/18

### For Manual Control:
- Admin can force-trigger by setting status to "full"
- Useful for:
  - Testing
  - VIP departures
  - Emergency situations
  - Manual override

## Monitoring

### Check if System is Working:

**User Side:**
1. Open app
2. Should see widget if van is full
3. Countdown should update every second

**Admin Side:**
1. Check Firestore logs
2. Look for "🚐 Van detected as FULL" logs
3. Verify notifications sent

**Database:**
```javascript
vans > [van_id]
{
  status: "full" or "boarding",
  notificationSent: true,
  scheduledDepartureTime: [timestamp]
}
```

## Summary

✅ **Before:** Only triggered when `currentOccupancy >= capacity`  
✅ **Now:** ALSO triggers when `status == "full"` OR `status == "boarding"`  
✅ **Result:** You can test with just 1 booking by changing van status!

**Your Testing Flow:**
```
Book 1 Seat → Admin: Set Status to "full" → Widget Appears! 🎉
```
