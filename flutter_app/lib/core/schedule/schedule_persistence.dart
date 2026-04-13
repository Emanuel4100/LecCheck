import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';
import '../config/feature_flags.dart';
import '../firebase/leccheck_firebase.dart';
import 'firestore_schedule_store.dart';
import 'local_schedule_store.dart';

/// Debounced local save; optional Firestore push when signed in and sync enabled.
class SchedulePersistence {
  SchedulePersistence({
    LocalScheduleStore? local,
    FirestoreScheduleStore? firestore,
  })  : local = local ?? LocalScheduleStore(),
        firestore = firestore ?? FirestoreScheduleStore();

  final LocalScheduleStore local;
  final FirestoreScheduleStore firestore;

  Timer? _debounce;

  void dispose() {
    _debounce?.cancel();
  }

  /// Persist immediately. [user] is from FirebaseAuth (null on Linux).
  /// On Linux, [linuxUid] is read from the REST auth session automatically.
  Future<void> persistNow(ScheduleRootState root, {User? user}) async {
    _debounce?.cancel();
    await _write(root, user?.uid ?? currentAuthUid);
  }

  void persistDebounced(ScheduleRootState root, {User? user}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_write(root, user?.uid ?? currentAuthUid));
    });
  }

  Future<void> _write(ScheduleRootState root, String? uid) async {
    final map = scheduleRootToJson(
      root,
      savedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await local.saveRaw(map);
    if (uid != null &&
        FeatureFlags.enableFirebaseSync &&
        isCloudAvailable) {
      try {
        await firestore.pushRaw(uid, map);
      } on Object {
        // Local data already saved; cloud sync can be retried later.
      }
    }
  }

  Future<void> clearLocal() => local.clear();

  Future<void> clearCloud(String uid) async {
    if (!isCloudAvailable) return;
    await firestore.delete(uid);
  }
}
