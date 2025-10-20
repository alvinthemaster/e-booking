# Van Departure Countdown Widget

## Overview
A real-time countdown widget displayed on the home screen that alerts users when their booked van is full and shows time remaining until departure.

## Features
✅ **Real-time monitoring** - Streams booking and van status from Firestore  
✅ **Live countdown timer** - Updates every second showing MM:SS format  
✅ **Beautiful UI** - Gradient card with prominent display  
✅ **Automatic detection** - Shows only when user has booking on a full van  
✅ **Smart display** - Hides when no relevant booking or van not full  
✅ **Interactive** - Tap to navigate to booking history for details

## How It Works

### Detection Flow
```
User Opens App
    ↓
Widget Initializes
    ↓
Listen to User's Confirmed Bookings
    ↓
Get Most Recent Booking
    ↓
Listen to Van Status (by plate number)
    ↓
Check: currentOccupancy >= capacity?
    ↓ YES
Display Widget with Countdown
    ↓
Update Every Second Until Departure
```

### Widget States

#### 1. Hidden State
Widget is completely hidden when:
- User has no confirmed bookings
- User's booked van is not full yet
- Booking status is not "confirmed"

#### 2. Visible State (Van Full)
Widget displays when:
- User has confirmed booking(s)
- Van capacity: currentOccupancy >= capacity
- Van has scheduled departure time

### UI Components

#### Header Section
- **Icon**: Bus icon in semi-transparent container
- **Title**: "🚐 Your Van is Full!"
- **Van Info**: Plate number display
- **Capacity Badge**: Shows "18/18" in green

#### Route Information
- **Origin → Destination**: Route display
- **Seat Numbers**: User's booked seats (e.g., "L1A, L1B")

#### Countdown Timer
- **Large Display**: MM:SS format (e.g., "15:00")
- **Status Text**: "Please proceed to the boarding area"
- **Loading State**: Shows spinner while fetching departure time
- **Expired State**: Shows "DEPARTING NOW!" when time is up

#### Footer
- **Info Icon**: Small information icon
- **Action Text**: "Tap for booking details"

## Implementation Details

### File: `lib/widgets/van_departure_countdown_widget.dart`

#### Key Methods

**`_listenToBookings()`**
- Streams user's confirmed bookings from Firestore
- Filters by userId and bookingStatus = 'confirmed'
- Sorts by booking date (most recent first)
- Triggers van listener for the booking

**`_listenToVan(Booking booking)`**
- Streams van status by plate number
- Checks if van is full (currentOccupancy >= capacity)
- Starts countdown timer when full
- Cancels previous subscriptions to prevent memory leaks

**`_startCountdownTimer(Van van)`**
- Fetches scheduled departure time from van document
- Defaults to 15 minutes from now if not set
- Updates countdown every second using Timer.periodic
- Stops when time reaches zero

**`_formatDuration(Duration duration)`**
- Formats duration as "MM:SS"
- Pads with zeros for consistent display
- Returns string like "15:00", "09:45", "00:30"

### Integration: `lib/screens/home_screen.dart`

```dart
// Added to HomeTab widget
const VanDepartureCountdownWidget(),
```

Position: Top of content area, before Quick Stats section

## Data Structure

### Van Document Fields Used
```dart
{
  'plateNumber': String,
  'currentOccupancy': int,
  'capacity': int,
  'scheduledDepartureTime': Timestamp?, // Optional
}
```

### Booking Document Fields Used
```dart
{
  'userId': String,
  'bookingStatus': String, // 'confirmed'
  'vanPlateNumber': String,
  'origin': String,
  'destination': String,
  'seatIds': List<String>,
  'bookingDate': Timestamp,
}
```

## Firestore Listeners

### Booking Listener
```dart
_firestore.collection('bookings')
  .where('userId', isEqualTo: user.uid)
  .where('bookingStatus', isEqualTo: 'confirmed')
  .snapshots()
```

### Van Listener
```dart
_firestore.collection('vans')
  .where('plateNumber', isEqualTo: booking.vanPlateNumber)
  .snapshots()
```

## Performance Considerations

### Memory Management
- **Subscription cleanup**: All listeners cancelled in dispose()
- **Timer cleanup**: Countdown timer cancelled when widget disposed
- **Single instance**: Only one timer and listeners active at a time

### Network Efficiency
- **Targeted queries**: Filters by userId and specific fields
- **Snapshot listeners**: Only updates when data changes
- **Conditional rendering**: Widget doesn't render when hidden

## User Experience

### Visual Design
- **Gradient background**: Blue gradient (#2196F3 → #1976D2)
- **Elevated appearance**: Box shadow for depth
- **White text**: High contrast for readability
- **Rounded corners**: 16px border radius
- **Responsive padding**: Consistent spacing throughout

### Animations
- **Smooth transitions**: Implicit animations on state changes
- **Real-time updates**: Countdown updates smoothly every second
- **Ink splash**: Material ripple effect on tap

### Accessibility
- **High contrast**: White on blue gradient
- **Large text**: Timer uses 32px font
- **Clear messaging**: Descriptive labels and status text
- **Touch target**: Full card is tappable

## Testing

### Manual Test Steps

1. **Create Confirmed Booking**
   - Log in to app
   - Book seats on a van
   - Complete payment (status = 'confirmed')

2. **Fill Van to Capacity**
   - Use multiple accounts or admin panel
   - Book seats until currentOccupancy = 18
   - Widget should appear immediately

3. **Verify Widget Display**
   - Check widget appears on home screen
   - Verify van plate number shown
   - Verify route information correct
   - Verify seat numbers displayed

4. **Test Countdown Timer**
   - Observe timer counting down
   - Check format is MM:SS
   - Verify updates every second
   - Wait until timer reaches 00:00

5. **Test Navigation**
   - Tap on widget card
   - Should navigate to booking history
   - Verify booking details shown

### Edge Cases

#### No Bookings
- **Expected**: Widget hidden
- **Actual**: Returns `SizedBox.shrink()`

#### Van Not Full
- **Expected**: Widget hidden until full
- **Actual**: Listener detects occupancy < capacity, hides widget

#### Multiple Bookings
- **Expected**: Shows most recent confirmed booking
- **Actual**: Sorts by bookingDate descending, takes first

#### Time Expired
- **Expected**: Shows "DEPARTING NOW!"
- **Actual**: Timer stops, displays departure message

#### No Scheduled Time
- **Expected**: Defaults to 15 minutes from detection
- **Actual**: Sets departureTime = now + 15 minutes

## Troubleshooting

### Widget Not Appearing

**Check:**
1. User has confirmed booking (status = 'confirmed')
2. Van currentOccupancy >= capacity (18/18)
3. Booking has vanPlateNumber field
4. Van exists in Firestore with matching plateNumber

**Debug:**
```dart
// Add to _listenToBookings()
print('Bookings found: ${snapshot.docs.length}');
print('Booking status: ${booking.bookingStatus}');
print('Van plate: ${booking.vanPlateNumber}');
```

### Countdown Not Starting

**Check:**
1. Van document has scheduledDepartureTime field
2. Timer is not being cancelled prematurely
3. setState() is being called in timer callback

**Debug:**
```dart
// Add to _startCountdownTimer()
print('Departure time: $departureTime');
print('Current time: ${DateTime.now()}');
print('Difference: ${departureTime.difference(DateTime.now())}');
```

### Widget Not Hiding

**Check:**
1. Booking status changed to something other than 'confirmed'
2. Van occupancy decreased below capacity
3. Listeners are properly cancelled

**Debug:**
```dart
// Add to setState() calls
print('Setting state: booking=$_fullVanBooking, van=$_fullVan');
```

## Future Enhancements

### Possible Additions

1. **Multiple Van Support**
   - Show countdown for all user's full vans
   - Scrollable list if multiple bookings

2. **Customizable Alerts**
   - User can set reminder intervals
   - Option to disable widget

3. **Animated Countdown**
   - Progress ring around timer
   - Color changes as time decreases

4. **Location Integration**
   - Show distance to boarding area
   - Estimated travel time

5. **Push Integration**
   - Sync with notification system
   - Show notification history

6. **Driver Information**
   - Display driver name and contact
   - Option to call driver

7. **Real-time Updates**
   - Show other passengers count
   - Display boarding status

### Database Enhancements

**Van Document:**
```dart
{
  'scheduledDepartureTime': Timestamp,
  'actualDepartureTime': Timestamp?,
  'boardingStartTime': Timestamp?,
  'passengersBoardedCount': int,
}
```

**Booking Document:**
```dart
{
  'boardedAt': Timestamp?,
  'notificationPreferences': {
    'showCountdown': bool,
    'reminderMinutes': List<int>,
  },
}
```

## Code Maintenance

### Key Points
- Widget is stateful for real-time updates
- Uses StreamSubscription for Firestore listeners
- Timer.periodic for countdown updates
- Proper disposal prevents memory leaks

### Dependencies
```yaml
dependencies:
  flutter
  cloud_firestore
  firebase_auth
```

### Related Files
- `lib/screens/home_screen.dart` - Integration point
- `lib/models/booking_models.dart` - Booking and Van models
- `lib/services/firebase_booking_service.dart` - Booking service

## Conclusion

The Van Departure Countdown Widget provides users with real-time awareness of their van's departure status, enhancing the overall booking experience by ensuring passengers are informed and ready to board when their van is full.
