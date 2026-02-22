# Sample Rental Vans Data for Firestore

This document provides sample data for the `rental_vans` collection in Firestore with all required fields.

## How to Add Sample Data

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Find or create the `rental_vans` collection
4. Click "Add Document" for each sample van below
5. Use the provided data structure

---

## Sample Van 1: Toyota Hiace

```json
{
  "vanId": "VAN001",
  "vanName": "Toyota Hiace Commuter",
  "plateNumber": "ABC 1234",
  "brand": "Toyota",
  "color": "White",
  "description": "Modern and comfortable van perfect for group travels and events. Features spacious interior with ample legroom.",
  "pricePerDay": 3500.00,
  "capacity": 15,
  "vehicleType": "Van",
  "amenities": ["Air Conditioning", "GPS Navigation", "WiFi", "Audio System", "USB Charging Ports"],
  "imageUrls": [
    "https://example.com/van1-front.jpg",
    "https://example.com/van1-interior.jpg"
  ],
  "isAvailable": true,
  "pickupLocation": "UVexpress Main Terminal, Cebu City",
  "availableFrom": "2026-02-22T00:00:00Z",
  "availableTo": "2026-12-31T23:59:59Z",
  "blockedDates": [],
  "minRentalDays": 1,
  "maxRentalDays": 30,
  "adminNotes": "Regular maintenance completed. Vehicle in excellent condition.",
  "createdAt": "2026-02-01T08:00:00Z"
}
```

---

## Sample Van 2: Nissan Urvan

```json
{
  "vanId": "VAN002",
  "vanName": "Nissan Urvan Premium",
  "plateNumber": "XYZ 5678",
  "brand": "Nissan",
  "color": "Silver",
  "description": "Premium 14-seater van with luxury features. Ideal for corporate events and long-distance travel.",
  "pricePerDay": 4000.00,
  "capacity": 14,
  "vehicleType": "Van",
  "amenities": ["Full Air Conditioning", "Leather Seats", "WiFi Hotspot", "Entertainment System", "Mini Fridge", "USB & Power Outlets"],
  "imageUrls": [
    "https://example.com/van2-front.jpg",
    "https://example.com/van2-interior.jpg",
    "https://example.com/van2-side.jpg"
  ],
  "isAvailable": true,
  "pickupLocation": "UVexpress Main Terminal, Cebu City",
  "availableFrom": "2026-02-22T00:00:00Z",
  "availableTo": "2026-12-31T23:59:59Z",
  "blockedDates": ["2026-03-15T00:00:00Z", "2026-03-16T00:00:00Z"],
  "minRentalDays": 2,
  "maxRentalDays": 30,
  "adminNotes": "Premium unit. Reserved for March 15-16.",
  "createdAt": "2026-02-01T09:00:00Z"
}
```

---

## Sample Van 3: Toyota Coaster

```json
{
  "vanId": "BUS001",
  "vanName": "Toyota Coaster Bus",
  "plateNumber": "DEF 9012",
  "brand": "Toyota",
  "color": "Blue",
  "description": "Large capacity bus perfect for school trips, company outings, and large group events.",
  "pricePerDay": 6500.00,
  "capacity": 29,
  "vehicleType": "Bus",
  "amenities": ["Air Conditioning", "PA System", "Overhead Luggage Compartments", "Reclining Seats", "Emergency Exits"],
  "imageUrls": [
    "https://example.com/bus1-front.jpg",
    "https://example.com/bus1-interior.jpg"
  ],
  "isAvailable": true,
  "pickupLocation": "UVexpress Bus Depot, North Reclamation Area",
  "availableFrom": "2026-02-22T00:00:00Z",
  "availableTo": "2026-12-31T23:59:59Z",
  "blockedDates": [],
  "minRentalDays": 1,
  "maxRentalDays": 14,
  "adminNotes": "Large bus. Requires professional driver license.",
  "createdAt": "2026-02-01T10:00:00Z"
}
```

---

## Sample Van 4: Ford Transit

```json
{
  "vanId": "VAN003",
  "vanName": "Ford Transit Executive",
  "plateNumber": "GHI 3456",
  "brand": "Ford",
  "color": "Black",
  "description": "Executive class van with captain seats. Perfect for VIP transport and business meetings.",
  "pricePerDay": 5500.00,
  "capacity": 12,
  "vehicleType": "Van",
  "amenities": ["Full Climate Control", "Captain Seats", "WiFi", "Premium Sound System", "Tinted Windows", "LED Interior Lighting", "Reading Lights"],
  "imageUrls": [
    "https://example.com/van3-front.jpg",
    "https://example.com/van3-interior.jpg"
  ],
  "isAvailable": true,
  "pickupLocation": "UVexpress Premium Terminal, IT Park",
  "availableFrom": "2026-02-22T00:00:00Z",
  "availableTo": "2026-12-31T23:59:59Z",
  "blockedDates": ["2026-04-10T00:00:00Z", "2026-04-11T00:00:00Z", "2026-04-12T00:00:00Z"],
  "minRentalDays": 1,
  "maxRentalDays": 21,
  "adminNotes": "VIP vehicle. Reserved for corporate event April 10-12.",
  "createdAt": "2026-02-01T11:00:00Z"
}
```

---

## Sample Van 5: Hyundai H350

```json
{
  "vanId": "VAN004",
  "vanName": "Hyundai H350",
  "plateNumber": "JKL 7890",
  "brand": "Hyundai",
  "color": "White",
  "description": "Budget-friendly van option with essential amenities. Great value for money.",
  "pricePerDay": 2800.00,
  "capacity": 13,
  "vehicleType": "Van",
  "amenities": ["Air Conditioning", "AM/FM Radio", "Comfortable Seats"],
  "imageUrls": [
    "https://example.com/van4-front.jpg"
  ],
  "isAvailable": true,
  "pickupLocation": "UVexpress South Terminal, South Road Properties",
  "availableFrom": "2026-02-22T00:00:00Z",
  "availableTo": "2026-12-31T23:59:59Z",
  "blockedDates": [],
  "minRentalDays": 1,
  "maxRentalDays": 30,
  "adminNotes": "Economy option. Good condition.",
  "createdAt": "2026-02-02T08:00:00Z"
}
```

---

## Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vanId` | string | Optional | Custom van identifier |
| `vanName` | string | Yes | Display name of the van |
| `plateNumber` | string | Yes | Vehicle plate number |
| `brand` | string | Optional | Vehicle manufacturer (Toyota, Nissan, etc.) |
| `color` | string | Optional | Vehicle color |
| `description` | string | Yes | Detailed description |
| `pricePerDay` | number | Yes | Daily rental price in PHP |
| `capacity` | number | Yes | Passenger capacity |
| `vehicleType` | string | Yes | Type: Van, Bus, Coaster |
| `amenities` | array | Yes | List of features/amenities |
| `imageUrls` | array | Yes | URLs of van photos |
| `isAvailable` | boolean | Yes | Availability status |
| `pickupLocation` | string | Optional | Where to pickup the van |
| `availableFrom` | timestamp | Optional | Start date of availability |
| `availableTo` | timestamp | Optional | End date of availability |
| `blockedDates` | array | Yes | Dates when van is booked/unavailable |
| `minRentalDays` | number | Optional | Minimum rental period in days |
| `maxRentalDays` | number | Optional | Maximum rental period in days |
| `adminNotes` | string | Optional | Internal admin notes (not shown to users) |
| `createdAt` | timestamp | Yes | Document creation timestamp |

---

## Important Notes

### Image URLs
- All `imageUrls` should point to actual hosted images
- You can use Firebase Storage URLs or external CDN URLs
- Example: `gs://your-project.appspot.com/rental_vans/van1.jpg`

### Date Fields
- `availableFrom`, `availableTo`, `createdAt` should use Firestore timestamp format
- In Firebase Console, use the "timestamp" type when adding dates
- `blockedDates` is an array of timestamps representing unavailable dates

### Data Types
- `pricePerDay` must be a **number** (not string)
- `capacity`, `minRentalDays`, `maxRentalDays` must be **integers**
- `isAvailable` must be a **boolean** (true/false)
- `amenities`, `imageUrls`, `blockedDates` must be **arrays**

### Admin Notes
- `adminNotes` field is for internal use only
- Not displayed to regular users in the app
- Only accessible by administrators

---

## Quick Setup in Firebase Console

1. **Create Collection**: Name it exactly `rental_vans`
2. **Add Document**: Click "Add document"
3. **Document ID**: Auto-generate or use custom (e.g., "van001")
4. **Add Fields**: Copy field names and values from samples above
5. **Set Types**: Make sure to select correct type (string, number, boolean, array, timestamp)
6. **Save**: Click "Save" to create the document

The app will automatically fetch and display all vans with the new field structure!
