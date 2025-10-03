# GODTRASCO Logo Integration Guide

## Changes Made

### 1. Project Configuration
- ✅ Updated `pubspec.yaml`:
  - Changed package name from `uvexpress_eticket` to `godtrasco_eticket`
  - Updated description to use GODTRASCO branding
  - Added assets folder configuration for logo
  
### 2. Application Branding
- ✅ Updated `lib/main.dart`:
  - Changed app class from `UVExpressApp` to `GodtrascoApp`
  - Updated app title to "GODTRASCO E-Ticket"

### 3. UI Updates
- ✅ Updated `lib/screens/auth/sign_in_screen.dart`:
  - Replaced circular gradient icon with GODTRASCO logo image
  - Changed title from "UVexpress" to "GODTRASCO"

- ✅ Updated `lib/screens/auth/sign_up_screen.dart`:
  - Replaced circular gradient icon with GODTRASCO logo image  
  - Updated welcome text to use "GODTRASCO"

- ✅ Updated `lib/screens/profile_screen.dart`:
  - Changed app version text to "GODTRASCO E-Ticket v1.0.0"
  - Updated about dialog title and description
  - Changed copyright to "© 2025 GODTRASCO. All rights reserved."

- ✅ Updated `lib/screens/eticket_screen.dart`:
  - Changed company name from "UVexpress" to "GODTRASCO"

### 4. Service Updates
- ✅ Updated `lib/services/firebase_booking_service.dart`:
  - Changed ticket reference prefix from "UVexpress-" to "GODTRASCO-"

## Manual Steps Required

### 1. Logo File
**IMPORTANT**: You need to manually copy your GODTRASCO logo image to:
```
c:\Users\yourb\OneDrive\Documents\GitHub\e-booking\assets\images\godtrasco_logo.png
```

The current file is just a placeholder. Replace it with your actual logo image.

### 2. App Icons (Recommended)
To complete the branding, you should also replace the app icons on all platforms:

#### Android Icons
Replace the following files with GODTRASCO-branded icons:
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

#### iOS Icons
Replace icons in:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

#### Web Icons
Replace icons in:
- `web/favicon.png` (16x16 or 32x32)
- `web/icons/Icon-192.png` (192x192)
- `web/icons/Icon-512.png` (512x512)
- `web/icons/Icon-maskable-192.png` (192x192)
- `web/icons/Icon-maskable-512.png` (512x512)

### 3. Testing
After copying the logo file, run:
```bash
flutter pub get
flutter run
```

## Notes
- All text-based branding has been updated to use "GODTRASCO"
- The logo is now referenced in the sign-in and sign-up screens
- Ticket references now use "GODTRASCO-" prefix
- App icons should be replaced for complete branding consistency

## Icon Generation Tools
Consider using tools like:
- [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- [App Icon Generator](https://appicon.co/)
- [Figma](https://www.figma.com/) for creating different sizes
