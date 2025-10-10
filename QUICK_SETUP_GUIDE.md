# 🚀 **UVexpress GitHub Pages Quick Setup**

## ⚡ **5-Minute Deployment**

### **1. Enable GitHub Pages**
1. Go to: `https://github.com/alvinthemaster/e-booking`
2. Click **Settings** → **Pages**
3. Source: **Deploy from a branch** → **main** → **/ (root)**
4. Click **Save**

### **2. Get Firebase Config**
1. [Firebase Console](https://console.firebase.google.com) → Your Project
2. Settings ⚙️ → Your apps → Web app config
3. Copy the `firebaseConfig` object

### **3. Update Web Page**
Edit `/web/confirm.html` and replace this section:
```javascript
const firebaseConfig = {
    apiKey: "YOUR_ACTUAL_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID", 
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```

### **4. Push to GitHub**
```bash
git add .
git commit -m "Deploy UVexpress confirmation"
git push origin main
```

### **5. Test Deployment**
Visit: `https://alvinthemaster.github.io/e-booking/web/confirm.html?token=test`

---

## 🎯 **Your URLs**

- **Confirmation Page**: `https://alvinthemaster.github.io/e-booking/web/confirm.html`
- **Flutter App Base URL**: `https://alvinthemaster.github.io/e-booking/web`
- **Default Conductor PIN**: `2024`

---

## 🔧 **Quick Tests**

### **Basic Test**:
`https://alvinthemaster.github.io/e-booking/web/confirm.html?token=test`
*Should show "Invalid Token" - this is correct!*

### **Real Test**:
1. Book ticket in app
2. Copy `confirmationToken` from Firestore
3. Visit: `your-url/confirm.html?token=COPIED_TOKEN`
4. Enter PIN `2024` to confirm

---

## 🆘 **Quick Fixes**

**Page not loading?**
- Wait 10 minutes for GitHub Pages deployment
- Check repository is public
- Verify file exists at `/web/confirm.html`

**Firebase errors?**
- Update Firebase config in `/web/confirm.html`
- Add `alvinthemaster.github.io` to Firebase authorized domains
- Check Firestore rules allow web access

**QR scanning not working?**
- Ensure HTTPS (GitHub Pages provides this)
- Test URL directly in browser first
- Verify QR contains correct URL format

---

## ✅ **Success Indicators**

- ✅ Page loads with UVexpress branding
- ✅ "Invalid Token" shown for test URLs
- ✅ Real tokens load passenger details  
- ✅ PIN `2024` confirms boarding
- ✅ Booking status updates to "onboard"
- ✅ Mobile camera scanning works

**You're ready for live passenger operations!** 🎫🚌