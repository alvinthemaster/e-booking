# App Name and Icon Update - "Godtrasco booking app"

## ✅ App Name Changes Completed

### 1. **Flutter App Title**
- **File**: `lib/main.dart`
- **Changed**: `'GODTRASCO E-Ticket'` → `'Godtrasco booking app'`

### 2. **Android App Name**
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Changed**: `android:label="UVexpress E-Ticket"` → `android:label="Godtrasco booking app"`

### 3. **iOS App Name**
- **File**: `ios/Runner/Info.plist`
- **Changed**: `CFBundleName` from `uvexpress_eticket` → `Godtrasco booking app`

### 4. **Web App Name**
- **File**: `web/index.html`
- **Changed**: Title and meta tags to use "Godtrasco booking app"

### 5. **Web Manifest**
- **File**: `web/manifest.json`
- **Changed**: 
  - `name`: "Godtrasco booking app"
  - `short_name`: "Godtrasco"
  - Updated description

## 📱 App Icon Replacement Needed

### **Manual Steps Required:**

#### **Android Icons (Replace these files):**
```
android/app/src/main/res/mipmap-hdpi/ic_launcher.png (72x72px)
android/app/src/main/res/mipmap-mdpi/ic_launcher.png (48x48px)
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png (96x96px)
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png (144x144px)
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png (192x192px)
```

#### **iOS Icons (Replace files in):**
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```
- Multiple sizes required (20x20 to 1024x1024)
- Use Xcode or icon generator tool

#### **Web Icons (Replace these files):**
```
web/favicon.png (16x16 or 32x32px)
web/icons/Icon-192.png (192x192px)
web/icons/Icon-512.png (512x512px)
web/icons/Icon-maskable-192.png (192x192px)
web/icons/Icon-maskable-512.png (512x512px)
```

### **Icon Generation Tools:**
1. **Flutter Launcher Icons** (Automated):
   ```bash
   flutter pub add dev:flutter_launcher_icons
   # Configure in pubspec.yaml
   flutter pub run flutter_launcher_icons:main
   ```

2. **Online Tools**:
   - [App Icon Generator](https://appicon.co/)
   - [Icon Kitchen](https://icon.kitchen/)
   - [Flutter Icon Generator](https://romannurik.github.io/AndroidAssetStudio/)

3. **Manual Replacement**:
   - Create GODTRASCO icons in required sizes
   - Replace existing files with same names
   - Maintain PNG format for all platforms

### **Testing After Icon Replacement:**
```bash
flutter clean
flutter pub get
flutter run
```

## 🎯 Result
- **App Name**: Now displays as "Godtrasco booking app" everywhere
- **App Icons**: Need manual replacement with GODTRASCO branding
- **Consistent Branding**: Across Android, iOS, and Web platforms

The app name is now completely updated! Just replace the icon files with your GODTRASCO icons to complete the rebranding. 🚐✨