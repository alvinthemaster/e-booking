# Firebase Hosting Deployment Guide
# E-Ticket Viewer Web Application

This guide will help you deploy your e-ticket viewer to Firebase Hosting.

## Prerequisites

1. **Firebase CLI installed** (check with: `firebase --version`)
   - If not installed, run: `npm install -g firebase-tools`

2. **Firebase Web App created** (required for firebase-config.js)

## Step 1: Create Web App in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/e-ticket-ff181)
2. Click **Project Settings** (⚙️ gear icon)
3. Scroll to **"Your apps"** section
4. Click **"Add app"** → Select **"</> Web"**
5. Register your app:
   - **App nickname**: `E-Ticket Viewer`
   - ☑️ Check **"Also set up Firebase Hosting"** (choose existing site or create new)
6. Click **"Register app"**
7. Copy the **App ID** (looks like: `1:321196714455:web:xxxxxxxxxxxxx`)
8. Update `web-viewer/firebase-config.js` line 12 with your App ID

## Step 2: Initialize Firebase Hosting (if not already done)

Open terminal in the `web-viewer` folder:

```powershell
cd C:\Users\yourb\OneDrive\Documents\GitHub\e-booking\web-viewer
```

Login to Firebase (if not logged in):

```powershell
firebase login
```

## Step 3: Deploy to Firebase Hosting

Deploy your e-ticket viewer:

```powershell
firebase deploy --only hosting
```

This will:
- Upload all files (index.html, styles.css, app.js, firebase-config.js)
- Deploy to Firebase Hosting
- Provide you with a hosting URL

## Step 4: Get Your Live URL

After deployment completes, you'll see:

```
✔  Deploy complete!

Hosting URL: https://e-ticket-ff181.web.app
```

Your e-ticket viewer will be live at:
- **Main URL**: `https://e-ticket-ff181.web.app`
- **Alternative**: `https://e-ticket-ff181.firebaseapp.com`

## Step 5: Configure Firebase Security Rules

Update your Firestore security rules to allow public read access to bookings by booking ID:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to bookings by bookingId
    match /bookings/{bookingId} {
      allow read: if true;  // Public read for e-ticket viewer
      allow write: if request.auth != null;  // Only authenticated users can write
    }
    
    // Other collections remain protected
    match /routes/{routeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /vans/{vanId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

⚠️ **Note**: The above rules allow anyone to read booking data if they know the booking ID. This is necessary for the public e-ticket viewer to work.

## Step 6: Test Your Deployment

1. Open your hosting URL in a browser
2. Enter a valid booking ID from your database
3. Verify the ticket displays correctly
4. Test the Print and Download PDF features

## Useful Commands

### View hosting URL
```powershell
firebase hosting:channel:list
```

### Re-deploy after changes
```powershell
firebase deploy --only hosting
```

### View deployment history
```powershell
firebase hosting:clone
```

### Set up custom domain (optional)
```powershell
firebase hosting:channel:deploy production
```

## Custom Domain Setup (Optional)

1. Go to Firebase Console → Hosting
2. Click **"Add custom domain"**
3. Enter your domain (e.g., `ticket.uvexpress.com`)
4. Follow DNS configuration instructions
5. Firebase will auto-provision SSL certificate

## Troubleshooting

### Issue: "Firebase command not found"
**Solution**: Install Firebase CLI:
```powershell
npm install -g firebase-tools
```

### Issue: "Permission denied"
**Solution**: Login to Firebase:
```powershell
firebase login
```

### Issue: "Project not found"
**Solution**: Verify project ID in `.firebaserc` matches your Firebase project

### Issue: Bookings not loading
**Solution**: 
1. Check Firebase Console → Firestore → Rules
2. Ensure read access is allowed for bookings collection
3. Verify Web App ID is correct in `firebase-config.js`

## Update Your E-Ticket Viewer

1. Make changes to files in `web-viewer/` folder
2. Save your changes
3. Run: `firebase deploy --only hosting`
4. Changes will be live in ~30 seconds

## Share Your E-Ticket Viewer

Share this URL with your users:
**https://e-ticket-ff181.web.app**

Users can:
- Enter their booking ID
- View their e-ticket
- Print their ticket
- Download as PDF

---

## Summary

Your e-ticket viewer is now hosted on Firebase! 🎉

- **Fast**: CDN-powered global delivery
- **Secure**: Automatic SSL/HTTPS
- **Free**: Generous free tier
- **Integrated**: Works seamlessly with your Firebase project

**Live URL**: https://e-ticket-ff181.web.app
