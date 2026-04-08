import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/leccheck_firebase.dart';

/// Remote schedule document: `users/{uid}/leccheck/main`.
class FirestoreScheduleStore {
  DocumentReference<Map<String, dynamic>> _doc(String uid) => lcFirestore
      .collection('users')
      .doc(uid)
      .collection('leccheck')
      .doc('main');

  Future<Map<String, dynamic>?> pullRaw(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    final bundle = data?['bundle'];
    if (bundle is Map<String, dynamic>) return bundle;
    if (bundle is Map) return Map<String, dynamic>.from(bundle);
    return null;
  }

  Future<void> pushRaw(String uid, Map<String, dynamic> bundle) async {
    await _doc(uid).set(
      {
        'bundle': bundle,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String uid) async {
    await _doc(uid).delete();
  }
}
