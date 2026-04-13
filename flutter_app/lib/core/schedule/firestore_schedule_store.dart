import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/leccheck_firebase.dart';

Map<String, dynamic>? _extractBundle(Map<String, dynamic>? data) {
  if (data == null) return null;
  final bundle = data['bundle'];
  if (bundle is Map<String, dynamic>) return bundle;
  if (bundle is Map) return Map<String, dynamic>.from(bundle);
  return null;
}

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
    return _extractBundle(snap.data());
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

  /// Real-time stream of the remote bundle. Emits `null` when the doc doesn't
  /// exist. Only usable on platforms with the native Firestore SDK (not Linux).
  Stream<({Map<String, dynamic>? bundle, bool hasPendingWrites})> watchRaw(
      String uid) {
    return _doc(uid).snapshots().map((snap) {
      return (
        bundle: snap.exists ? _extractBundle(snap.data()) : null,
        hasPendingWrites: snap.metadata.hasPendingWrites,
      );
    });
  }

  Future<void> delete(String uid) async {
    await _doc(uid).delete();
  }
}
