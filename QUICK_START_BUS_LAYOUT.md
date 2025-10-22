# Quick Start Guide: Bus Seat Selection

## For Developers

### How to Add a Bus in Admin Panel

1. **Create a new vehicle document in Firestore:**
   ```javascript
   // In vehicles collection
   {
     "id": "auto-generated",
     "plateNumber": "BUS 001",
     "vehicleType": "bus",  // ⚠️ Important: Set this to "bus"
     "capacity": 20,         // Bus has 20 seats (5 rows × 4)
     "status": "active",
     "queuePosition": 2,
     "currentOccupancy": 0,
     "driver": {
       "name": "John Driver",
       "license": "N01-12-345678",
       "contact": "+63 912 345 6789"
     },
     "isActive": true,
     "createdAt": "2025-10-22T10:00:00Z"
   }
   ```

2. **The app will automatically:**
   - Show bus icon (🚌) instead of van icon (🚐)
   - Display "Bus 2" instead of "Van 2"
   - Load 20-seat bus layout when booking
   - Apply same booking logic (max 5 seats, 13.33% discount, ₱15 fee)

---

## For Admins

### Testing Bus Booking Flow

**Step 1:** Add a bus vehicle in Firebase Console
- Go to Firestore → `vehicles` collection
- Add document with `vehicleType: "bus"`
- Set `capacity: 20`

**Step 2:** Open the app
- You should see the bus in the queue
- Icon shows 🚌 and label shows "Bus"

**Step 3:** Tap "Book Now"
- Seat layout shows 5 rows (L1A-L5B, R1A-R5B)
- No driver-adjacent seats (buses don't have them)

**Step 4:** Select seats and complete booking
- Everything else works the same as vans!

---

## Vehicle Type Comparison

| Feature | Van | Bus |
|---------|-----|-----|
| **Total Seats** | 18 | 20 |
| **Layout** | 2 beside driver + 4 rows × 4 | 5 rows × 4 |
| **Seat IDs** | D1A, D1B, L1A-L4B, R1A-R4B | L1A-L5B, R1A-R5B |
| **Icon** | 🚐 `Icons.directions_bus` | 🚌 `Icons.airport_shuttle` |
| **Base Fare** | ₱150 | ₱150 |
| **Discount** | 13.33% | 13.33% |
| **Booking Fee** | ₱15 | ₱15 |
| **Max Seats** | 5 per booking | 5 per booking |

---

## Visual Layout Reference

### Van Layout (18 seats):
```
┌─────────────────────────────────┐
│  [DRIVER]      [D1A] [D1B]      │
├─────────────────────────────────┤
│  [L1A] [L1B]  AISLE  [R1A] [R1B]│
│  [L2A] [L2B]  AISLE  [R2A] [R2B]│
│  [L3A] [L3B]  AISLE  [R3A] [R3B]│
│  [L4A] [L4B]  AISLE  [R4A] [R4B]│
└─────────────────────────────────┘
```

### Bus Layout (20 seats):
```
┌─────────────────────────────────┐
│          [DRIVER]               │
├─────────────────────────────────┤
│  [L1A] [L1B]  AISLE  [R1A] [R1B]│
│  [L2A] [L2B]  AISLE  [R2A] [R2B]│
│  [L3A] [L3B]  AISLE  [R3A] [R3B]│
│  [L4A] [L4B]  AISLE  [R4A] [R4B]│
│  [L5A] [L5B]  AISLE  [R5A] [R5B]│
└─────────────────────────────────┘
```

---

## Example Booking Calculation

### Van Booking (3 seats, 1 with discount):
```
Seat 1 (Regular):  ₱150.00
Seat 2 (Regular):  ₱150.00
Seat 3 (Discount): ₱130.00 (₱150 - 13.33%)
─────────────────────────────
Subtotal:          ₱430.00
Booking Fee:       ₱ 15.00
─────────────────────────────
TOTAL:             ₱445.00
```

### Bus Booking (3 seats, 1 with discount):
```
Seat 1 (Regular):  ₱150.00
Seat 2 (Regular):  ₱150.00
Seat 3 (Discount): ₱130.00 (₱150 - 13.33%)
─────────────────────────────
Subtotal:          ₱430.00
Booking Fee:       ₱ 15.00
─────────────────────────────
TOTAL:             ₱445.00
```

**Note:** Calculation is identical! Vehicle type only affects seat layout.

---

## Troubleshooting

### Issue: Bus showing as "Van" in the app
**Solution:** Check Firebase document has `"vehicleType": "bus"`

### Issue: Wrong number of seats
**Solution:** 
- Van should have `capacity: 18`
- Bus should have `capacity: 20`

### Issue: Wrong layout displayed
**Solution:** Make sure `vehicleType` field matches:
- `"van"` → Shows VanSeatLayout (18 seats)
- `"bus"` → Shows BusSeatLayout (20 seats)

### Issue: Seat reservations not syncing
**Solution:** Check that seat IDs in bookings collection match the layout:
- Van: D1A, D1B, L1A-L4B, R1A-R4B
- Bus: L1A-L5B, R1A-R5B

---

## Firebase Structure

### Vehicles Collection:
```
vehicles/
  ├── van_001/
  │   ├── vehicleType: "van"
  │   ├── capacity: 18
  │   └── ...
  └── bus_001/
      ├── vehicleType: "bus"
      ├── capacity: 20
      └── ...
```

### Bookings Collection:
```
bookings/
  ├── BOOK001/
  │   ├── vehicleType: "van"
  │   ├── seatIds: ["L1A", "L1B"]
  │   └── ...
  └── BOOK002/
      ├── vehicleType: "bus"
      ├── seatIds: ["L1A", "L1B", "L2A"]
      └── ...
```

---

## Code Examples

### Navigate to Bus Seat Selection:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SeatSelectionScreen(
      vehicleType: 'bus', // Specify bus
    ),
  ),
);
```

### Navigate to Van Seat Selection:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SeatSelectionScreen(
      vehicleType: 'van', // Specify van
    ),
  ),
);
```

### Or use default (van):
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SeatSelectionScreen(), // Defaults to van
  ),
);
```

---

## Summary

✅ **What Changed:**
- Van model now has `vehicleType` field
- Two separate layout widgets (VanSeatLayout, BusSeatLayout)
- Seat selection screen dynamically switches layouts
- Home screen shows correct icon and label

✅ **What Stayed the Same:**
- Booking logic
- Payment processing
- Discount calculation
- E-ticket generation
- All Firebase operations

✅ **Backward Compatible:**
- Existing vans default to `vehicleType: 'van'`
- No database migration needed
- Old code continues to work

---

**Need Help?** Check the full documentation in `BUS_SEAT_LAYOUT_IMPLEMENTATION.md`
