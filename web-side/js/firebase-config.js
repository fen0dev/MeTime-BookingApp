// Firebase Configuration
// Note: While these credentials are visible in the browser, Firebase Security Rules
// protect your data. Make sure your Firestore rules are properly configured.

const firebaseConfig = {
    apiKey: "AIzaSyAAXmsDu8u2F5UIDu752IthVh652JXH-zM",
    authDomain: "mybeautycrave-metime.firebaseapp.com",
    projectId: "mybeautycrave-metime",
    storageBucket: "mybeautycrave-metime.firebasestorage.app",
    messagingSenderId: "559859805862",
    appId: "1:559859805862:web:ab0cce706943e897d60e67"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Export Firebase services
const db = firebase.firestore();
const functions = firebase.functions();