# Admin IDs & Keys for Godtrasco E-Ticket App

This file collects the important IDs and keys an admin may need to manage or integrate the a  - `paymentMethod` (string) — e.g. `GCash`, `Maya`, `PayPal`p with Firebase and platform services. Keep this file safe — some entries are sensitive (API keys) and should be rotated or protected in production.

> Note: These values were extracted from `android/app/google-services.json` and `lib/firebase_options.dart` in the project workspace.

---

## Firebase Project
- Project ID: `e-ticket-2e8d0`
- Project Number: `774845116609`
- Firebase Realtime Database URL: `https://e-ticket-2e8d0-default-rtdb.asia-southeast1.firebasedatabase.app`
- Storage Bucket: `e-ticket-2e8d0.firebasestorage.app`

Where to manage: Firebase Console → Project Settings → General / Realtime Database / Storage

---

## Android
- Android package name: `com.uvexpress.eticket.uvexpress_eticket`
- Android appId (Firebase): `1:774845116609:android:1136a5b7b1bcfdf0bc6440`
- Android API key: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`
- (From) `android/app/google-services.json` and `lib/firebase_options.dart` (android)

Files to change: `android/app/google-services.json`, `lib/firebase_options.dart` (android section)

---

# Admin IDs & Firestore Transaction Schema for Godtrasco E-Ticket App

This file is a single reference for admins to manage Firebase IDs and the Firestore schema used for app/web transactions (routes, vans, schedules, seats, bookings, payments). Use this to add vans and seat availability and to ensure the mobile app and web app communicate through Firestore.

Values at the top are taken from the project's Firebase configuration files (kept here for convenience). Below that you'll find recommended Firestore collection names, document field schemas, sample documents, suggested security rules, and admin tasks.

> Important: API keys in client config are for client-side use. For server/admin operations use a Firebase Service Account JSON and the Admin SDK. Rotate keys if exposed.

---

## Project / Client IDs (from project files)
- Project ID: `e-ticket-2e8d0`
- Project Number: `774845116609`
- Realtime DB URL: `https://e-ticket-2e8d0-default-rtdb.asia-southeast1.firebasedatabase.app`
- Storage Bucket: `e-ticket-2e8d0.firebasestorage.app`

Android
- Package name: `com.uvexpress.eticket.uvexpress_eticket`
- Android Firebase appId: `1:774845116609:android:1136a5b7b1bcfdf0bc6440`
- Android API Key: `AIzaSyA9L9u7hTM5ivm1mi8YnkQiJzvuquUECs0`

Web
- Web Firebase appId: `1:774845116609:web:97e574378399bfabbc6440`
- Web API Key: `AIzaSyAVi4bFIlWzIW2H1Gs_1mxnhjQZ0XPXyFM`
- Auth Domain: `e-ticket-2e8d0.firebaseapp.com`

Files to update after changes: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` (if used), `lib/firebase_options.dart`

---

## Firestore: Collections & Document Schemas (used by app/web)

Below are the collections and document shapes the app expects. Follow these names exactly (or update the code if you change them).

1) `routes` (fixed routes)
- Document ID: auto or `route-{slug}`
- Fields:
	- `name` (string) — human readable e.g. "Glan → General Santos"
	- `origin` (string)
	- `destination` (string)
	- `basePrice` (number) — price per seat
	- `estimatedDuration` (number) — minutes
	- `waypoints` (array[string]) — optional stops
	- `isActive` (bool)

Example (document `route-glan-gensan`):
{
	"name": "Glan → General Santos",
	"origin": "Glan",
	"destination": "General Santos",
	"basePrice": 180.0,
	"estimatedDuration": 120,
	"waypoints": ["Polomolok"],
	"isActive": true
}

2) `vans` (vehicle info)
- Document ID: `van-{plate}` or auto id
- Fields:
	- `plateNumber` (string)
	- `model` (string)
	- `capacity` (number) — total seats
	- `seatLayout` (map) — optional structured layout or list of seats
	- `isActive` (bool)

Example:
{
	"plateNumber": "UVX-123",
	"model": "Toyota HiAce",
	"capacity": 12,
	"seatLayout": {
		"seats": ["1A","1B","2A","2B",...]
	},
	"isActive": true
}

3) `schedules` (a scheduled van run for a route)
- Document ID: auto or `schedule-{routeId}-{timestamp}`
- Fields:
	- `routeId` (string) — reference to `routes` doc id
	- `vanId` (string) — reference to `vans` doc id
	- `departureTime` (timestamp)
	- `arrivalEstimate` (timestamp) optional
	- `availableSeats` (number) — computed remaining seats
	- `seatIds` (array[string]) — available seat identifiers or full seat objects
	- `status` (string) — e.g. `scheduled`, `in_transit`, `completed`, `cancelled`

Example:
{
	"routeId": "route-glan-gensan",
	"vanId": "van-UVX-123",
	"departureTime": <timestamp>,
	"availableSeats": 10,
	"seatIds": ["1A","1B","2A",...],
	"status": "scheduled"
}

4) `bookings` (user bookings / transactions)
- Document ID: auto from Firestore or booking code
- Fields (matching the app Booking model):
	- `userId` (string)
	- `userName` (string)
	- `userEmail` (string)
	- `routeId` (string)
	- `routeName` (string)
	- `origin`, `destination` (string)
	- `departureTime` (timestamp)
	- `bookingDate` (timestamp)
	- `seatIds` (array[string])
	- `numberOfSeats` (number)
	- `basePrice` (number)
	- `discountAmount` (number)
	- `totalAmount` (number)
	- `paymentMethod` (string) — e.g. `GCash`, `Physical Payment`
	- `paymentStatus` (string/enum) — `pending`, `paid`, `failed`, `refunded`
	- `bookingStatus` (string) — `active`, `completed`, `cancelled`
	- `qrCodeData` (string) — optional data used in QR generation
	- `eTicketId` (string) — optional external id
	- `passengerDetails` (map) — name/email/phone

Example:
{
	"userId": "uid_abc123",
	"userName": "Juan dela Cruz",
	"userEmail": "juan@example.com",
	"routeId": "route-glan-gensan",
	"routeName": "Glan → General Santos",
	"departureTime": <timestamp>,
	"bookingDate": <timestamp>,
	"seatIds": ["1A","1B"],
	"numberOfSeats": 2,
	"basePrice": 180.0,
	"discountAmount": 24.0,
	"totalAmount": 336.0,
	"paymentMethod": "GCash",
	"paymentStatus": "paid",
	"bookingStatus": "active",
	"qrCodeData": "UVE-20250929-0001",
	"passengerDetails": {"name":"Juan dela Cruz","email":"juan@example.com","phone":"09171234567"}
}

5) `seatReservations` (optional per-schedule seat lock)
- Document ID: `reservation-{scheduleId}-{seatId}` or keep under `schedules/{scheduleId}/reservations/{seatId}`
- Fields:
	- `scheduleId` (string)
	- `seatId` (string)
	- `bookingId` (string) — if reserved by a booking
	- `reservedBy` (string) — userId
	- `reservedAt` (timestamp)
	- `expiresAt` (timestamp) — optional to auto-release locks

This collection helps the app implement temporary seat locks while users checkout.

6) `payments` (optional separate ledger)
- Document ID: auto
- Fields: `bookingId`, `amount`, `method`, `status`, `transactionRef`, `createdAt`

7) `users` (if you store profile metadata separately)
- Document ID: user uid
- Fields: `displayName`, `email`, `phone`, `discountEligible` (boolean), etc.

---

## How the app & web should communicate (high-level)
- Both the mobile app and the web app read/write the same Firestore collections above.
- Typical flow for a booking:
	1. App shows `routes` and `schedules` (query `routes` and `schedules` where `isActive` / `status==scheduled`).
	2. User chooses schedule & seats. App writes a temporary `seatReservations` doc (with short TTL) to lock seats.
	3. User completes payment; on success the app creates a `bookings` document and updates `seatReservations` to include `bookingId` (or directly mark seats as reserved in `schedules`).
	4. The app updates `schedules.availableSeats` or keeps seat inventory in `seatReservations` subtree.

Design note: using a `schedules/{scheduleId}/reservations/{seatId}` subcollection reduces contention and keeps locks localized.

---

## Firestore security rules (starter example)
This example protects bookings and restricts writes to only authenticated users or admin UIDs. Replace `ADMIN_UID_1` with real admin UIDs or maintain a `admins` collection.

```javascript
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		// routes, vans, schedules - only admins can write
		match /routes/{doc} {
			allow read: if request.auth != null;
			allow write: if request.auth != null && request.auth.uid in ['ADMIN_UID_1','ADMIN_UID_2'];
		}

		match /vans/{doc} {
			allow read: if request.auth != null;
			allow write: if request.auth != null && request.auth.uid in ['ADMIN_UID_1','ADMIN_UID_2'];
		}

		match /schedules/{doc} {
			allow read: if request.auth != null;
			allow write: if request.auth != null && request.auth.uid in ['ADMIN_UID_1','ADMIN_UID_2'];
		}

		// bookings - users can create and read their own bookings
		match /bookings/{bookingId} {
			allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
			allow read: if request.auth != null && resource.data.userId == request.auth.uid;
			allow update: if request.auth != null && resource.data.userId == request.auth.uid;
			allow delete: if false; // disallow deletes or restrict to admins
		}

		// seat reservations - creation allowed for authenticated users (for locking)
		match /seatReservations/{doc} {
			allow read: if request.auth != null;
			allow create: if request.auth != null;
			allow update: if request.auth != null;
			allow delete: if request.auth != null && (request.auth.uid in ['ADMIN_UID_1','ADMIN_UID_2']);
		}

		// users collection - users can read/write their own profile
		match /users/{uid} {
			allow read, write: if request.auth != null && request.auth.uid == uid;
		}
	}
}
```

Notes:
- Replace `['ADMIN_UID_1','ADMIN_UID_2']` with actual admin UIDs or derive admin status from an `admins` collection/document.
- For critical server operations (mass updates, data migrations), use the Admin SDK with a service account.

---

## Admin Tasks (how to add van, seats, schedules)

1) Add a Route
- Console: Firestore → `routes` → Add Document → Fill fields from `routes` schema above.

2) Add a Van
- Console: Firestore → `vans` → Add Document → Fill `plateNumber`, `capacity`, `seatLayout`.

3) Create a Schedule
- Console: Firestore → `schedules` → Add Document → set `routeId` (from `routes`), `vanId` (from `vans`), `departureTime` (timestamp), `seatIds`.
- Optionally compute and set `availableSeats` (typically `van.capacity`).

4) Seed Seat Inventory / Layout
- Use `vans/{vanId}.seatLayout` or create `schedules/{scheduleId}/seats` subcollection with documents per seat:
	- `seatId`: "1A"
	- `isReserved`: false
	- `price`: optional override

5) Test booking flow
- Use an authenticated test user (create via app) and make a test booking to verify that `seatReservations` and `bookings` are created and `availableSeats` updates.

---

## Admin utilities and recommendations
- Create an `admins` collection or `config/admins` doc that lists admin UIDs. Use rules to check membership rather than hard-coding UIDs in rules.
- Use Firestore transactions when updating seat availability to prevent double-booking.
- Implement automatic expiration for seat locks (`expiresAt`) using Cloud Functions or a scheduled process.
- Use the Admin SDK (service account) to run bulk operations (import routes, vans) from CSV.

## Service Account (server/admin)
- Generate from: Firebase Console → Project Settings → Service Accounts → Generate new private key.
- Store the JSON securely (not in repo). Use it for server tasks and Cloud Functions.

---

If you want, I can:
- Add a small Node.js or Python admin script that seeds `routes`, `vans`, and `schedules` for testing.
- Create a Cloud Function sample to auto-release expired `seatReservations`.

Which of those would you like me to add next?
