# Bug Fix: Null vehicleType Issue

## Problem Identified
When loading vans from Firebase that don't have `vehicleType` field, the value can be null causing:
```
type 'Null' is not a subtype of type 'String' of 'function result'
```

## Root Cause
The Van model has `vehicleType` as non-nullable `String`, but older documents in Firebase don't have this field.

## Solution Applied

### 1. Added safety check in home_screen.dart:
```dart
final String safeVehicleType = van.vehicleType.isNotEmpty ? van.vehicleType : 'van';
```

### 2. Van model already has default in fromMap:
```dart
vehicleType: map['vehicleType'] ?? 'van'
```

## Testing Results
- App loads successfully
- Found BUS1 with vehicleType
- No more null errors
- Backward compatible with old van data

## Status: ✅ FIXED
