# Bus Seat Layout Update - 21 Seats Configuration

## Overview
Updated the bus seat layout to match the provided image with 21 total seats.

## New Bus Layout

### Configuration:
- **Rows 1-4**: Standard 2-2 configuration (4 seats per row = 16 seats)
- **Row 5 (Back Row)**: 3-2 configuration (5 seats = 5 seats)
- **Total**: 21 seats

### Visual Layout:
```
┌─────────────────────────────────────────┐
│          [DRIVER]                       │
├─────────────────────────────────────────┤
│  [L1A] [L1B]    AISLE    [R1A] [R1B]   │  Row 1: 4 seats
│  [L2A] [L2B]    AISLE    [R2A] [R2B]   │  Row 2: 4 seats
│  [L3A] [L3B]    AISLE    [R3A] [R3B]   │  Row 3: 4 seats
│  [L4A] [L4B]    AISLE    [R4A] [R4B]   │  Row 4: 4 seats
│  [L5A] [L5B] [L5C] AISLE [R5A] [R5B]   │  Row 5: 5 seats (BACK)
└─────────────────────────────────────────┘
```

## Seat IDs

### Rows 1-4 (Standard Rows):
- **Left Side**: L1A, L1B, L2A, L2B, L3A, L3B, L4A, L4B
- **Right Side**: R1A, R1B, R2A, R2B, R3A, R3B, R4A, R4B

### Row 5 (Back Row):
- **Left Side (3 seats)**: L5A, L5B, L5C
- **Right Side (2 seats)**: R5A, R5B

## Changes Made

### 1. Updated `lib/widgets/bus_seat_layout.dart`
- Modified layout to render first 4 rows as 2-2 configuration
- Added special rendering for Row 5 with 3-2 configuration
- Left side of Row 5 uses `flex: 3` with 3 seats
- Right side of Row 5 uses `flex: 2` with 2 seats

### 2. Updated `lib/providers/seat_provider.dart`
- Changed bus seat initialization from 20 to 21 seats
- First 4 rows: Loop creates L{row}A, L{row}B, R{row}A, R{row}B
- Last row: Explicitly creates L5A, L5B, L5C, R5A, R5B

## Comparison

| Aspect | Old Bus Layout | New Bus Layout |
|--------|---------------|----------------|
| **Total Seats** | 20 | 21 |
| **Rows** | 5 uniform rows | 4 standard + 1 special |
| **Row 1-4** | 2-2 (4 seats) | 2-2 (4 seats) ✓ Same |
| **Row 5** | 2-2 (4 seats) | 3-2 (5 seats) ⭐ NEW |
| **Back Row Layout** | Standard | Extended (3 left, 2 right) |

## Van Layout (Unchanged)
For reference, van layout remains:
- **Total**: 18 seats
- **Driver Row**: D1A, D1B (2 seats beside driver)
- **Rows 1-4**: 2-2 configuration (16 seats)

## Booking Logic (Unchanged)
✅ Maximum 5 seats per booking  
✅ 13.33% discount available  
✅ ₱150 base fare per seat  
✅ ₱15 booking fee per transaction  
✅ Same seat selection interaction  
✅ Same payment flow  

## Technical Details

### Widget Structure:
```dart
Column(
  children: [
    // Driver section
    Container(DRIVER),
    
    // First 4 rows (standard)
    for (int row = 1; row <= 4; row++)
      Row(
        children: [L{row}A, L{row}B, AISLE, R{row}A, R{row}B]
      ),
    
    // Last row (special - 3-2 configuration)
    Row(
      children: [
        Expanded(flex: 3): [L5A, L5B, L5C],
        AISLE,
        Expanded(flex: 2): [R5A, R5B],
      ]
    ),
  ]
)
```

### Seat Provider Logic:
```dart
if (vehicleType == 'bus') {
  // Rows 1-4: Standard 2-2
  for (int row = 1; row <= 4; row++) {
    _seats.add(Seat(id: 'L${row}A', ...));
    _seats.add(Seat(id: 'L${row}B', ...));
    _seats.add(Seat(id: 'R${row}A', ...));
    _seats.add(Seat(id: 'R${row}B', ...));
  }
  
  // Row 5: Special 3-2
  _seats.add(Seat(id: 'L5A', ...));
  _seats.add(Seat(id: 'L5B', ...));
  _seats.add(Seat(id: 'L5C', ...)); // Extra seat
  _seats.add(Seat(id: 'R5A', ...));
  _seats.add(Seat(id: 'R5B', ...));
}
```

## Firebase Update Required

### Update Bus Capacity in Firebase:
If you have existing bus documents, update their capacity:

```javascript
// In Firebase Console → Firestore → vehicles collection
{
  "vehicleType": "bus",
  "capacity": 21,  // Update from 20 to 21
  // ... other fields
}
```

Or use this Firestore query to update all buses:
```javascript
db.collection('vehicles')
  .where('vehicleType', '==', 'bus')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      doc.ref.update({ capacity: 21 });
    });
  });
```

## Testing Checklist

✅ Bus displays with 21 seats  
✅ First 4 rows show 2-2 configuration  
✅ Last row shows 3-2 configuration (3 left, 2 right)  
✅ All seats are selectable  
✅ Seat IDs display correctly (L5A, L5B, L5C, R5A, R5B)  
✅ Selection works for all 21 seats  
✅ Discount applies to any seat  
✅ Booking flow works with new layout  
✅ Payment calculation correct  

## Visual Comparison

### Before (20 seats):
```
Row 1: [L1A] [L1B] | [R1A] [R1B]  = 4 seats
Row 2: [L2A] [L2B] | [R2A] [R2B]  = 4 seats
Row 3: [L3A] [L3B] | [R3A] [R3B]  = 4 seats
Row 4: [L4A] [L4B] | [R4A] [R4B]  = 4 seats
Row 5: [L5A] [L5B] | [R5A] [R5B]  = 4 seats
                                Total: 20 seats
```

### After (21 seats):
```
Row 1: [L1A] [L1B] | [R1A] [R1B]      = 4 seats
Row 2: [L2A] [L2B] | [R2A] [R2B]      = 4 seats
Row 3: [L3A] [L3B] | [R3A] [R3B]      = 4 seats
Row 4: [L4A] [L4B] | [R4A] [R4B]      = 4 seats
Row 5: [L5A] [L5B] [L5C] | [R5A] [R5B] = 5 seats ⭐
                                  Total: 21 seats
```

## Files Modified

1. **lib/widgets/bus_seat_layout.dart**
   - Updated Column to separate rows 1-4 from row 5
   - Row 5 uses custom flex layout (3:2 ratio)
   - Added 3 seats on left, 2 on right for row 5

2. **lib/providers/seat_provider.dart**
   - Updated bus seat initialization
   - Changed from uniform 5 rows to 4+1 special
   - Total seats: 20 → 21

## Implementation Date
October 22, 2025

## Status
✅ **COMPLETE** - Bus layout updated to match provided image with 21 seats (4 rows of 4 + 1 row of 5)
