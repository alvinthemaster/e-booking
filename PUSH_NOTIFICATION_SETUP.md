# Push Notification System - Van Full Alert

## Overview
This system automatically notifies passengers when their booked van becomes full, alerting them that the van will depart in **15 minutes**.

## Features
- ✅ Automatic detection when van reaches full capacity
- ✅ Immediate notification to all passengers with confirmed bookings
- ✅ Scheduled notification reminder 15 minutes before departure
- ✅ Local notifications (works even when app is closed)
- ✅ Firebase Cloud Messaging integration
- ✅ Prevents duplicate notifications per van

## How It Works

### 1. Van Capacity Monitoring
- When a booking is created, the system updates the van's `currentOccupancy`
- If `currentOccupancy >= capacity`, the van is considered **FULL**

### 2. Notification Trigger
When a van becomes full:
1. System retrieves all confirmed bookings for that van
2. Calculates departure time = Current time + 15 minutes
3. Schedules individual notifications for each passenger
4. Updates van document with `scheduledDepartureTime` and `notificationSent: true`
5. Shows immediate notification: "Van is Full!"

### 3. Departure Notification
15 minutes later, passengers receive:
- **Title**: "🚐 Van Departing Soon!"
- **Body**: "Your van [PLATE] ([ORIGIN] → [DESTINATION]) will depart in 15 minutes. Please proceed to the boarding area now."

## Technical Implementation

### Services Created

#### 1. `NotificationService` (`lib/services/notification_service.dart`)
Handles:
- Firebase Cloud Messaging (FCM) initialization
- Local notification setup
- Scheduling notifications
- Notification permissions

**Key Methods:**
- `initialize()` - Sets up FCM and local notifications
- `scheduleNotification()` - Schedules a notification for a specific time
- `showNotification()` - Shows immediate notification
- `cancelNotification()` - Cancels a scheduled notification

#### 2. `VanFullNotificationService` (`lib/services/van_full_notification_service.dart`)
Handles:
- Detection of full vans
- Scheduling departure notifications for all passengers
- Preventing duplicate notifications
- Tracking notified vans

**Key Methods:**
- `checkAndNotifyIfVanFull(vanId)` - Main method to check and notify
- `clearVanNotification(vanId)` - Reset notification flag for a van
- `resetAllNotifications()` - Clear all notification flags (for testing)

### Integration Points

#### `firebase_booking_service.dart`
```dart
// After updating van occupancy
if (isBooking && clampedOccupancy >= van.capacity) {
  await _notificationService.checkAndNotifyIfVanFull(vanDoc.id);
}
```

#### `main.dart`
```dart
// Initialize notification service on app start
await NotificationService().initialize();

// Set up background message handler
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

## Packages Added

```yaml
firebase_messaging: ^15.1.5
flutter_local_notifications: ^18.0.1
timezone: ^0.9.4
```

## Firebase Configuration Required

### Android (`android/app/build.gradle`)
No additional configuration needed - already set up with Firebase.

### Android (`android/app/src/main/AndroidManifest.xml`)
Add notification permissions (if not already present):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### iOS (`ios/Runner/Info.plist`)
Add notification permissions:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

## Data Flow

```
User Books Seat
    ↓
firebase_booking_service.createBooking()
    ↓
_updateVanOccupancy() updates currentOccupancy
    ↓
Check: currentOccupancy >= capacity?
    ↓ YES
VanFullNotificationService.checkAndNotifyIfVanFull()
    ↓
Get all confirmed bookings for this van
    ↓
Schedule notification for each passenger (15 min)
    ↓
Show immediate notification: "Van is Full!"
    ↓
Update van: scheduledDepartureTime, notificationSent=true
```

## Testing

### Test Notification System
1. Create bookings until van reaches capacity (18 seats)
2. On the 18th booking, notification should trigger
3. Check logs for: "🚨 Van [PLATE] is now FULL!"
4. Verify immediate notification appears
5. Wait 15 minutes for scheduled notification

### Manual Test
```dart
// In any screen, test notification:
VanFullNotificationService().showTestNotification();
```

## Notification Behavior

### When App is:
- **Foreground**: Local notification shown with banner
- **Background**: Notification shown in notification center
- **Closed**: Notification still scheduled and will appear

### User Actions:
- **Tap notification**: Opens app (can be configured to navigate to specific screen)
- **Dismiss**: Notification removed, no action

## Future Enhancements

### Possible Additions:
1. **Customizable departure time**: Allow admin to set departure delay
2. **SMS notifications**: For users without app notifications enabled
3. **Email notifications**: Backup notification method
4. **Notification settings**: Let users customize notification preferences
5. **Multiple reminders**: 15 min, 10 min, 5 min before departure
6. **Push to specific users**: Target notifications by FCM token

### Database Extensions:
Add to Booking model:
```dart
final String? fcmToken; // User's FCM token for targeted push
final bool notificationSent; // Track if notification was sent
final DateTime? notificationTime; // When notification was sent
```

Add to Van model:
```dart
final DateTime? scheduledDepartureTime; // When van will depart
final bool notificationSent; // Already notified passengers
final DateTime? notificationSentAt; // Timestamp of notification
```

## Troubleshooting

### Notifications Not Appearing
1. **Check permissions**: Ensure notification permissions granted
2. **Check timezone**: Verify timezone initialized correctly
3. **Check logs**: Look for "NotificationService:" debug messages
4. **Test immediate notification**: Use `showTestNotification()`

### Duplicate Notifications
- Van notification flags are tracked in `_notifiedVans` Set
- Call `resetAllNotifications()` if testing repeatedly

### Notification Not Scheduling
- Ensure device allows exact alarm scheduling
- Check Android `SCHEDULE_EXACT_ALARM` permission
- Verify notification service initialized in main.dart

## Security Notes

### Firebase Cloud Messaging
- FCM tokens are user-specific
- Tokens refresh periodically - app handles this automatically
- Server-side push requires Firebase Admin SDK (for admin panel)

### Local Notifications
- No internet required for scheduled notifications
- Notifications persist even if app is uninstalled (until triggered)

## Performance Considerations

- Notification check only runs when van becomes full
- No continuous polling or listeners
- Minimal impact on battery and performance
- Notifications stored in system, not app memory

## Conclusion

The push notification system provides real-time alerts to passengers when their van is ready to depart, improving the user experience and ensuring passengers are prepared for boarding. The system is fully automated, requires no manual intervention, and works reliably across different app states.
