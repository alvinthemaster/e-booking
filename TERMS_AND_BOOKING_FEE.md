# Terms & Conditions and Booking Fee Implementation

## Overview
This document outlines the implementation of Terms & Conditions with No Refund Policy and ₱2.00 booking fee.

## Features Implemented

### 1. Terms & Conditions Modal
**File**: `lib/widgets/terms_conditions_modal.dart`

#### Features:
- ✅ **Responsive Design**: Modal adapts to different screen sizes (max 85% of screen height)
- ✅ **Scrollable Content**: Long terms can be scrolled without UI overlap
- ✅ **No Refund Policy**: Prominently displayed with warning box
- ✅ **Agreement Checkbox**: Users must check to accept terms
- ✅ **Accept & Continue**: Button only enabled after checkbox is checked
- ✅ **Cancel Option**: Users can dismiss the modal

#### Key Sections:
1. **No Refund Policy** (highlighted)
2. Booking Confirmation
3. Seat Reservation
4. Passenger Information
5. Departure Time
6. E-Ticket Validity
7. Payment (includes booking fee notice)
8. Cancellation by Operator
9. Luggage Policy
10. Code of Conduct

### 2. Booking Fee Implementation

#### ₱2.00 Flat Fee Added
**Files Modified**:
- `lib/providers/seat_provider.dart`
- `lib/screens/seat_selection_screen.dart`
- `lib/screens/payment_screen.dart`

#### Fee Structure:
```dart
// In SeatProvider
double get bookingFee => _selectedSeats.isNotEmpty ? 2.0 : 0.0;
double calculateTotalAmountWithFee() => calculateTotalAmount() + bookingFee;
```

#### Breakdown Display:

**Seat Selection Screen**:
```
Subtotal: ₱150.00
Booking Fee: ₱2.00
─────────────────
Total Amount: ₱152.00
```

**Payment Screen**:
```
Fare Subtotal: ₱150.00
Discount Applied: -₱20.00 (if applicable)
Booking Fee: ₱2.00
─────────────────
Total Amount: ₱152.00
```

### 3. User Flow

#### Before (Without Terms):
1. Select seats → 2. Booking form → 3. Payment

#### After (With Terms):
1. Select seats → 2. **Accept Terms & Conditions** → 3. Booking form → 4. Payment

### 4. Responsive UI Improvements

#### Modal Responsiveness:
```dart
final screenHeight = MediaQuery.of(context).size.height;
final maxHeight = screenHeight * 0.85; // Maximum 85% of screen height

Container(
  constraints: BoxConstraints(
    maxHeight: maxHeight,
    maxWidth: 600,
  ),
  // ...
)
```

#### Scroll Handling:
- Modal content is wrapped in `Flexible` and `SingleChildScrollView`
- Header and footer are fixed
- Content scrolls independently

#### No Overlap Guarantee:
- Uses `Dialog` with proper `insetPadding`
- Responsive constraints prevent overflow
- Bottom action buttons always visible
- SafeArea consideration for notch/home indicator

### 5. Payment Calculations

#### Base Price Calculation (Updated):
```dart
basePrice: widget.totalAmount - widget.discountAmount - 2.0
```

**Example**:
- Fare: ₱150.00
- Discount: -₱20.00
- Booking Fee: +₱2.00
- **Total**: ₱132.00
- **Base Price**: ₱132.00 - ₱20.00 - ₱2.00 = ₱110.00

## Testing Instructions

### 1. Test Terms & Conditions Modal

**Steps**:
1. Launch app and navigate to seat selection
2. Select at least one seat
3. Click "Continue to Booking"
4. **Verify**: Terms & Conditions modal appears
5. **Verify**: Cannot proceed without checking agreement box
6. **Verify**: Modal is scrollable on small screens
7. **Verify**: Can cancel and return to seat selection
8. **Verify**: After accepting, proceeds to booking form

### 2. Test Booking Fee

**Steps**:
1. Select 1 seat (₱150 base fare)
2. Check "Show Details" in selection summary
3. **Verify**: Shows:
   - Subtotal: ₱150.00
   - Booking Fee: ₱2.00
   - Total: ₱152.00
4. Proceed to payment screen
5. **Verify**: Payment summary shows:
   - Fare Subtotal: ₱150.00
   - Booking Fee: ₱2.00
   - Total: ₱152.00

### 3. Test with Discount

**Steps**:
1. Select 2 seats
2. Apply discount to 1 seat (13.33% = ₱20)
3. **Verify**: Shows:
   - Subtotal: ₱280.00 (₱150 + ₱130)
   - Booking Fee: ₱2.00
   - Total: ₱282.00
4. In payment screen:
   - Fare Subtotal: ₱280.00
   - Discount Applied: -₱20.00
   - Booking Fee: ₱2.00
   - Total: ₱282.00

### 4. Test Responsive UI

**Screen Sizes to Test**:
- Small (360x640): Modal should fit with scrolling
- Medium (375x812): Comfortable viewing
- Large (414x896): Spacious layout
- Tablet (768x1024): Centered with max width

**Verify**:
- No content cut off
- All buttons accessible
- Checkbox clearly visible
- No overlap with system UI (notch, navigation bar)

## Code Changes Summary

### New Files:
- `lib/widgets/terms_conditions_modal.dart` (323 lines)

### Modified Files:

#### 1. `lib/providers/seat_provider.dart`
```dart
+ double get bookingFee => _selectedSeats.isNotEmpty ? 2.0 : 0.0;
+ double calculateTotalAmountWithFee() => calculateTotalAmount() + bookingFee;
```

#### 2. `lib/screens/seat_selection_screen.dart`
```dart
+ import '../widgets/terms_conditions_modal.dart';
+ showDialog(context: context, builder: (context) => TermsConditionsModal(...));
+ totalAmount: seatProvider.calculateTotalAmountWithFee()
+ Subtotal, Booking Fee, and Total breakdown display
```

#### 3. `lib/screens/payment_screen.dart`
```dart
+ Fare Subtotal: (widget.totalAmount - 2.0)
+ Discount Applied: -₱{discount} (if applicable)
+ Booking Fee: ₱2.00
+ basePrice calculation updated: totalAmount - discountAmount - 2.0
```

## Key Features

### ✅ No Refund Policy
- Clearly stated in Terms & Conditions
- Warning box with red background
- Users must acknowledge before booking

### ✅ Booking Fee
- ₱2.00 flat fee per booking (not per seat)
- Clearly displayed in all summaries
- Included in total amount calculations

### ✅ Responsive Design
- Works on all screen sizes
- No UI overlap
- Scrollable when content exceeds screen height
- Modal centered and properly sized

### ✅ User Experience
- Clear information presentation
- Required acknowledgment before proceeding
- Transparent pricing breakdown
- Accessible cancel option

## Future Enhancements (Optional)

1. **Localization**: Translate terms to local language
2. **Version Tracking**: Track T&C version user accepted
3. **PDF Export**: Allow users to download T&C as PDF
4. **Dynamic Fees**: Make booking fee configurable from admin panel
5. **Email Copy**: Send T&C copy to user's email
6. **Analytics**: Track acceptance rate and user behavior

## Notes

- Booking fee is a flat ₱2.00 regardless of number of seats
- Terms must be accepted each time user proceeds to booking
- Modal uses `barrierDismissible: false` to ensure explicit action
- Base price calculation properly excludes both discount and booking fee
- All monetary values use proper decimal formatting (2 decimal places)
