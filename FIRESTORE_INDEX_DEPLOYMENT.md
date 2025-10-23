# Firestore Index Deployment Guide

## Problem Identified:
The query `getAvailableVansForBooking` was failing because it uses multiple `where` clauses that require a composite index in Firestore.

## Query Pattern:
```dart
_vansCollection
  .where('currentRouteId', isEqualTo: routeId)
  .where('status', isEqualTo: 'boarding')
```

## Solution Applied:

### 1. Added Missing Composite Indexes
Updated `firestore.indexes.json` with required indexes:

```json
{
  "collectionGroup": "vans",
  "fields": [
    { "fieldPath": "currentRouteId", "order": "ASCENDING" },
    { "fieldPath": "isActive", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

### 2. Optimized Query
Reduced where clauses from 3 to 2 and filter `isActive` in memory to avoid complex index requirements.

## How to Deploy Indexes:

### Option 1: Deploy via Firebase CLI (Recommended)
```powershell
# Make sure you're logged in to Firebase
firebase login

# Deploy the indexes
firebase deploy --only firestore:indexes
```

### Option 2: Create Index via Firebase Console
If you see an error with a link like this:
```
https://console.firebase.google.com/...
```
Click the link and it will auto-create the index for you.

### Option 3: Manual Creation in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `e-ticket-2e8d0`
3. Go to **Firestore Database** → **Indexes** tab
4. Click **Create Index**
5. Collection ID: `vans`
6. Add fields:
   - `currentRouteId` - Ascending
   - `status` - Ascending
7. Query scope: `Collection`
8. Click **Create**

## Verify Index Creation:

After deploying, check the Firebase Console:
- Go to Firestore → Indexes
- Look for status: "Building..." → "Enabled"
- Building can take a few minutes depending on data size

## Testing:

Run the app and try to create a booking. The error should be gone!

## Index Build Time:
- Small datasets (< 1000 documents): ~30 seconds
- Medium datasets (1000-10000 documents): 1-5 minutes  
- Large datasets (> 10000 documents): 5-30 minutes

## Current Indexes in firestore.indexes.json:

1. **bookings**: userId + bookingDate
2. **bookings**: vanId + bookingDate
3. **bookings**: status + bookingDate
4. **vans**: routeId + status + queueNumber (OLD - using routeId)
5. **vans**: status + departureTime
6. **vans**: **currentRouteId + isActive + status** ✨ NEW
7. **vans**: **isActive + status + queuePosition** ✨ NEW

The new indexes (#6 and #7) are specifically for the booking system to work properly!

## Troubleshooting:

### Error: "The query requires an index"
- Deploy indexes using: `firebase deploy --only firestore:indexes`
- Or click the error link to auto-create

### Error: "Index creation failed"
- Check field names match exactly (case-sensitive)
- Verify collection name is `vans` not `van`
- Ensure Firebase CLI is up to date: `npm install -g firebase-tools`

### Error: "Permission denied"
- Run `firebase login` again
- Ensure you have Editor/Owner role in the Firebase project

## Quick Deploy Command:

```powershell
# All in one command
firebase login; firebase deploy --only firestore:indexes
```

Wait for indexes to build (check console), then test the app!
