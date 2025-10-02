# UVexpress E-Ticket Admin Web Panel

## 📋 Overview

This document outlines the Admin Web Panel features and requirements for the UVexpress E-Ticket system. The admin panel will be built using Flutter Web and must maintain real-time synchronization with the mobile app through a centralized Firebase database.

## 🔑 Key Requirements

- **Unified Database**: All data (vans, fares, discounts, bookings, trip history) must use matching IDs across the admin panel and mobile app
- **Real-time Synchronization**: Any updates must instantly reflect on both platforms
- **Firebase Integration**: Firebase Firestore serves as the centralized API layer
- **Common Data Models**: Shared data structures between web and mobile platforms

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin Web     │    │    Firebase     │    │   Mobile App    │
│     Panel       │◄──►│   Firestore     │◄──►│   (Flutter)     │
│  (Flutter Web)  │    │   (Database)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 Firebase Collections Structure

Based on the mobile app, the following collections will be shared:

### Routes Collection
```json
{
  "id": "route_glan_gensan",
  "name": "Glan → General Santos",
  "origin": "Glan",
  "destination": "General Santos",
  "basePrice": 150.0,
  "estimatedDuration": 120,
  "waypoints": ["Glan", "General Santos"],
  "isActive": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Schedules Collection
```json
{
  "id": "schedule_id",
  "routeId": "route_glan_gensan",
  "departureTime": "timestamp",
  "arrivalTime": "timestamp",
  "availableSeats": 12,
  "totalSeats": 12,
  "bookedSeats": ["A1", "A2"],
  "isActive": true,
  "vanId": "van_001",
  "driverId": "driver_001"
}
```

### Bookings Collection
```json
{
  "id": "booking_id",
  "userId": "user_id",
  "userName": "John Doe",
  "userEmail": "john@email.com",
  "routeId": "route_glan_gensan",
  "routeName": "Glan → General Santos",
  "origin": "Glan",
  "destination": "General Santos",
  "departureTime": "timestamp",
  "bookingDate": "timestamp",
  "seatIds": ["A1", "A2"],
  "numberOfSeats": 2,
  "basePrice": 180.0,
  "discountAmount": 24.0,
  "totalAmount": 336.0,
  "paymentMethod": "GCash",
  "paymentStatus": "paid",
  "bookingStatus": "active",
  "qrCodeData": "QR_DATA",
  "eTicketId": "ET-12345678",
  "passengerDetails": {},
  "discountApplied": "discount_id"
}
```

## 📌 Main Features

### 🚐 1. Van Management (Queue System)

#### 1.1 Van Registration
- **Add New Vans**
  - Plate number (unique identifier)
  - Driver information (name, license, contact)
  - Van capacity (seats configuration)
  - Van type/model
  - Registration documents

#### 1.2 Van Queue Management
- **Active Queue Display**
  - Real-time van positions
  - Next van in line indicator
  - Estimated departure times
  - Current passenger load

- **Van Operations**
  - Move van to active/inactive status
  - Emergency van removal
  - Maintenance scheduling

**Firebase Collection: `vans`**
```json
{
  "id": "van_001",
  "plateNumber": "ABC-1234",
  "capacity": 12,
  "driver": {
    "id": "driver_001",
    "name": "Juan Dela Cruz",
    "license": "N01-12-123456",
    "contact": "+639123456789"
  },
  "status": "active",
  "currentRouteId": "route_glan_gensan",
  "queuePosition": 1,
  "lastMaintenance": "timestamp",
  "nextMaintenance": "timestamp",
  "isActive": true,
  "createdAt": "timestamp"
}
```

### 💰 2. Discount Management

#### 2.1 Discount Types
- **Percentage Discounts** (e.g., 13.33% for eligible passengers)
- **Fixed Amount Discounts**
- **Bulk Booking Discounts**

#### 2.2 Discount Rules
- **Eligibility Criteria**
  - Student discounts
  - Senior citizen discounts
  - PWD discounts

#### 2.3 Discount Management Interface
- Create new discount rules
- Edit existing discounts
- Activate/deactivate discounts
- Set validity periods
- Usage tracking and analytics

**Firebase Collection: `discounts`**
```json
{
  "id": "discount_student",
  "name": "Student Discount",
  "description": "13.33% discount for students",
  "type": "percentage",
  "value": 13.33,
  "eligibility": ["student"],
  "applicableRoutes": ["all"],
  "validFrom": "timestamp",
  "validTo": "timestamp",
  "maxUsage": 1000,
  "currentUsage": 245,
  "isActive": true,
  "createdAt": "timestamp"
}
```

### 💵 3. Fare Management

#### 3.1 Dynamic Pricing

#### 3.2 Fare Adjustments
- **Real-time Updates**
  - Instant fare changes


### 📊 4. Trip History

#### 4.1 Complete Trip Records
- **Trip Details**
  - Route information
  - Date and time
  - Vehicle and driver details
  - Passenger count
  - Discounts applied

#### 4.2 Search and Filter
- **Filter Options**
  - Date range
  - Route
  - Driver
  - Van

#### 4.3 Trip Analytics
- Peak travel times

**Firebase Collection: `trip_history`**
```json
{
  "id": "trip_001",
  "routeId": "route_glan_gensan",
  "scheduleId": "schedule_id",
  "vanId": "van_001",
  "driverId": "driver_001",
  "departureTime": "timestamp",
  "arrivalTime": "timestamp",
  "passengerCount": 10,
  "discountsApplied": 180.0,
  "bookingIds": ["booking_1", "booking_2"],
  "status": "completed",
}
```

### 📈 5. Analytics & Reports

#### 5.1 Dashboard Metrics
- **Real-time Statistics**
  - Active bookings

#### 5.2 Report Generation
- **Time-based Reports**
  - Daily summaries
  - Weekly analysis
  - Monthly performance
  - Yearly trends

#### 5.3 Key Performance Indicators
- **Business Metrics**
  - Total bookings
  - Average fare per passenger
  - Discount utilization

#### 5.4 Export Options
- CSV format for spreadsheet analysis
- PDF reports for presentations
- JSON for API integration

**Firebase Collection: `analytics`**
```json
{
  "id": "analytics_daily_2025_10_01",
  "date": "2025-10-01",
  "totalBookings": 150,
  "discountsGiven": 3360.0,
  "averageFare": 168.0,
  "passengerCount": 180,
  "peakHour": "14:00",
  "createdAt": "timestamp"
}
```

## 🎯 User Management

### Admin Users
**Firebase Collection: `admin_users`**
```json
{
  "id": "admin_001",
  "email": "admin@uvexpress.com",
  "name": "Admin User",
  "role": "super_admin",
  "permissions": ["all"],
  "lastLogin": "timestamp",
  "isActive": true,
  "createdAt": "timestamp"
}
```

### Roles & Permissions
- **Super Admin**: Full system access
- **Route Manager**: Route and schedule management
- **Finance Manager**: Fare and discount management
- **Operations Manager**: Van and driver management
- **Analyst**: Read-only access to reports

## 🔄 Real-time Synchronization Features

### 1. Live Updates
- **Booking Status Changes**: Instant updates across platforms
- **Van Queue Updates**: Real-time position changes
- **Fare Changes**: Immediate pricing updates
- **Seat Availability**: Live seat status updates

### 2. Conflict Resolution
- **Concurrent Booking Prevention**
- **Data Consistency Checks**
- **Transaction Rollback Mechanisms**

### 3. Offline Support
- **Cache Management**
- **Sync Queue for Offline Actions**
- **Conflict Resolution on Reconnection**

## 🛡️ Security & Access Control

### Authentication
- Firebase Authentication integration
- Role-based access control
- Session management
- Multi-factor authentication


## 🚀 Implementation Phases

### Phase 1: Core Setup
1. Firebase project configuration
2. Shared data models
3. Basic authentication
4. Van management interface

### Phase 2: Operations Management
1. Queue management system
2. Real-time booking monitoring
3. Basic reporting dashboard

### Phase 3: Financial Management
1. Fare management interface
2. Discount system

### Phase 4: Analytics & Optimization
1. Advanced reporting
2. Performance analytics
3. Export functionality
4. Mobile responsiveness


## 📱 Mobile App Integration Points

### Shared Components
- Authentication system
- Booking models
- Payment processing
- QR code generation
- Push notifications

### Data Consistency
- Unified validation rules
- Shared business logic
- Common error handling
- Synchronized user sessions

## 🔧 Technical Requirements

### Frontend (Flutter Web)
- Responsive design for desktop and tablet
- Real-time data binding
- Interactive charts and graphs
- Export functionality
- Print-friendly layouts

### Backend (Firebase)
- Firestore for real-time database
- Cloud Functions for business logic
- Firebase Auth for authentication
- Cloud Storage for file uploads
- Analytics for usage tracking

### Additional Tools
- Firebase Admin SDK
- Chart.js or Flutter Charts
- PDF generation libraries
- CSV export functionality
- Push notification services

This admin web panel will ensure seamless operation management while maintaining perfect synchronization with the mobile app through the shared Firebase infrastructure.