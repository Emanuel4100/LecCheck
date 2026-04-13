import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import '../auth/linux_auth_bridge.dart';

/// True when the native Firebase SDK plugin works on this platform.
/// Linux desktop lacks native firebase_core support (Pigeon channels are
/// unimplemented), so it uses REST-based auth and Firestore instead.
bool get firebaseSupportedOnThisPlatform {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return false;
  }
}

/// Whether this platform supports auth (Firebase SDK **or** Linux REST).
bool get authSupportedOnThisPlatform {
  if (firebaseSupportedOnThisPlatform) return true;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) return true;
  return false;
}

/// Whether [Firebase.initializeApp] completed for this process.
bool get isFirebaseInitialized => Firebase.apps.isNotEmpty;

/// Whether cloud sync is available (Firebase SDK initialised, or Linux
/// REST auth is signed in).
bool get isCloudAvailable {
  if (isFirebaseInitialized) return true;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return isLinuxAuthSignedIn;
  }
  return false;
}

/// The current user's UID across both Firebase SDK and Linux REST auth.
String? get currentAuthUid {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return linuxAuthUid;
  }
  return firebaseCurrentUserIfReady?.uid;
}

/// Avoids touching [FirebaseAuth] before [Firebase.initializeApp] (e.g. widget tests).
User? get firebaseCurrentUserIfReady =>
    isFirebaseInitialized ? FirebaseAuth.instance.currentUser : null;

/// Firestore instance; only valid after Firebase init on a supported platform.
FirebaseFirestore get lcFirestore => FirebaseFirestore.instance;

/// Root collection/doc path for a user (aligns with Firestore rules under `users/{userId}/...`).
String firestoreUserPath(String uid) => 'users/$uid';

/// Document id for the main semester schedule blob (implementation TBD).
const String kFirestoreScheduleDocId = 'main';
