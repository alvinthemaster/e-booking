// Firebase Configuration
// TODO: Replace with your actual Firebase configuration from firebase_options.dart
const firebaseConfig = {
    apiKey: "AIzaSyCQdLMgW1C5VCszjRSq52FGh_hV8lGKr-4",
    authDomain: "e-ticket-ff181.firebaseapp.com",
    projectId: "e-ticket-ff181",
    storageBucket: "e-ticket-ff181.firebasestorage.app",
    messagingSenderId: "321196714455",
    appId: "1:321196714455:web:1f1735cd9e99e419fb4392", // You need to add web app to Firebase
    measurementId: "G-XXXXXXXXXX" // Optional
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firestore
const db = firebase.firestore();

// Export for use in other files
window.db = db;
