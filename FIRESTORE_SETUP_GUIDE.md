# Firestore Setup Guide for e-ticket-ff181

## 🎯 Current Status
✅ Firebase project connected: **e-ticket-ff181**  
✅ Authentication working  
✅ Firestore connected  
⚠️ **Missing indexes** (causing booking queries to fail)

---

## 📋 Required Firestore Indexes

### Option 1: Deploy via Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```powershell
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```powershell
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done):
   ```powershell
   firebase init firestore
   ```
   - Select your project: **e-ticket-ff181**
   - Use default firestore.rules
   - Use **firestore.indexes.json** for indexes

4. **Deploy the indexes**:
   ```powershell
   firebase deploy --only firestore:indexes
   ```

### Option 2: Create Indexes Manually via Firebase Console

#### Index 1: Bookings by User and Date (REQUIRED - Currently Failing)
- **Collection**: `bookings`
- **Fields to index**:
  1. `userId` - Ascending
  2. `bookingDate` - Descending
- **Query scope**: Collection

**Direct Link**: [Create Index](https://console.firebase.google.com/v1/r/project/e-ticket-ff181/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9lLXRpY2tldC1mZjE4MS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvYm9va2luZ3MvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDwoLYm9va2luZ0RhdGUQAhoMCghfX25hbWVfXxAC)

**Manual Steps**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **e-ticket-ff181**
3. Click **Firestore Database** in left menu
4. Click **Indexes** tab
5. Click **Create Index**
6. Enter:
   - Collection ID: `bookings`
   - Field 1: `userId` → Ascending
   - Field 2: `bookingDate` → Descending
7. Click **Create**

---

#### Index 2: Bookings by Van and Date
- **Collection**: `bookings`
- **Fields to index**:
  1. `vanId` - Ascending
  2. `bookingDate` - Descending
- **Query scope**: Collection

**Steps**:
1. Firestore Database → Indexes → Create Index
2. Collection ID: `bookings`
3. Field 1: `vanId` → Ascending
4. Field 2: `bookingDate` → Descending
5. Click Create

---

#### Index 3: Bookings by Status and Date
- **Collection**: `bookings`
- **Fields to index**:
  1. `status` - Ascending
  2. `bookingDate` - Descending
- **Query scope**: Collection

**Steps**:
1. Firestore Database → Indexes → Create Index
2. Collection ID: `bookings`
3. Field 1: `status` → Ascending
4. Field 2: `bookingDate` → Descending
5. Click Create

---

#### Index 4: Vans by Route, Status, and Queue
- **Collection**: `vans`
- **Fields to index**:
  1. `routeId` - Ascending
  2. `status` - Ascending
  3. `queueNumber` - Ascending
- **Query scope**: Collection

**Steps**:
1. Firestore Database → Indexes → Create Index
2. Collection ID: `vans`
3. Field 1: `routeId` → Ascending
4. Field 2: `status` → Ascending
5. Field 3: `queueNumber` → Ascending
6. Click Create

---

#### Index 5: Vans by Status and Departure Time
- **Collection**: `vans`
- **Fields to index**:
  1. `status` - Ascending
  2. `departureTime` - Ascending
- **Query scope**: Collection

**Steps**:
1. Firestore Database → Indexes → Create Index
2. Collection ID: `vans`
3. Field 1: `status` → Ascending
4. Field 2: `departureTime` → Ascending
5. Click Create

---

## ⏱️ Index Creation Time

- Indexes typically take **2-5 minutes** to build
- You'll see "Building..." status during creation
- Once status shows "Enabled" (green), they're ready to use

---

## 🔐 Firestore Security Rules

Make sure your Firestore rules are set up. Go to **Firestore Database → Rules** and use these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Routes collection - read only for all authenticated users
    match /routes/{routeId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admins via Admin SDK
    }
    
    // Vans collection - read for authenticated users
    match /vans/{vanId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only admins via Admin SDK
    }
    
    // Bookings collection
    match /bookings/{bookingId} {
      // Users can read their own bookings
      allow read: if isAuthenticated() && 
                     resource.data.userId == request.auth.uid;
      
      // Users can create bookings for themselves
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      
      // Users can update their own bookings (for cancellation, payment status)
      allow update: if isAuthenticated() && 
                       resource.data.userId == request.auth.uid;
      
      // Users cannot delete bookings
      allow delete: if false;
    }
    
    // Users collection (for storing user profiles if needed)
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
  }
}
```

---

## ✅ Verification Steps

After creating indexes:

1. **Wait 2-5 minutes** for indexes to build
2. **Check index status** in Firebase Console → Firestore → Indexes
3. **Run your app** and try:
   - Login
   - View bookings
   - Book a seat
4. **Check logs** - the error should be gone:
   ```
   W/Firestore: The query requires an index
   ```

---

## 🚀 Quick Deploy Commands

If you have Firebase CLI installed:

```powershell
# Login
firebase login

# Set project
firebase use e-ticket-ff181

# Deploy indexes
firebase deploy --only firestore:indexes

# Deploy rules
firebase deploy --only firestore:rules
```

---

## 📊 Sample Data Structure

After indexes are created, you can test with sample data:

### Sample Booking Document
```json
{
  "userId": "FB8rW6lZR5RWmWyS5lHxpDZkAu42",
  "vanId": "gvqP2YamJtpLcuMRHwvZ",
  "routeId": "SCLRIO5R1ckXKwz2ykxd",
  "bookingDate": "2025-10-23T10:30:00Z",
  "status": "pending",
  "seats": ["L1A", "L1B"],
  "totalAmount": 330,
  "paymentStatus": "pending"
}
```

### Sample Van Document (Update status to "boarding")
```json
{
  "plateNumber": "PLATE VAN 1",
  "driverName": "Driver Name",
  "routeId": "SCLRIO5R1ckXKwz2ykxd",
  "status": "boarding",
  "vehicleType": "van",
  "capacity": 18,
  "occupiedSeats": 0,
  "queueNumber": 1,
  "departureTime": "2025-10-23T11:00:00Z"
}
```

---

## ⚠️ Current Issue

Your van "PLATE VAN 1" has status **"in_queue"** but the app only shows vans with status **"boarding"**.

**To fix**: Update the van status in Firestore Console:
1. Go to Firestore Database → Data
2. Find collection: `vans`
3. Find document: `gvqP2YamJtpLcuMRHwvZ`
4. Edit field: `status` → Change from "in_queue" to **"boarding"**
5. Save

---

## 📞 Need Help?

If you encounter issues:
1. Check Firebase Console → Firestore → Indexes (make sure all show "Enabled")
2. Check app logs for any error messages
3. Verify data structure matches expected format
4. Ensure Firestore rules allow the operations you're trying

---

## 🎉 Success Indicators

Once everything is set up correctly, you should see:
- ✅ No "requires an index" errors in logs
- ✅ Bookings load successfully
- ✅ Vans appear on home screen
- ✅ Seat selection works
- ✅ Booking creation succeeds
