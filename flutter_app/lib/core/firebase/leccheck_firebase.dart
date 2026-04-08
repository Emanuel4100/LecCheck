import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// True when [DefaultFirebaseOptions.currentPlatform] exists (Linux/Fuchsia are not configured).
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

/// Whether [Firebase.initializeApp] completed for this process.
bool get isFirebaseInitialized => Firebase.apps.isNotEmpty;

/// Firestore instance; only valid after Firebase init on a supported platform.
FirebaseFirestore get lcFirestore => FirebaseFirestore.instance;

/// Root collection/doc path for a user (aligns with Firestore rules under `users/{userId}/...`).
String firestoreUserPath(String uid) => 'users/$uid';

/// Document id for the main semester schedule blob (implementation TBD).
const String kFirestoreScheduleDocId = 'main';
