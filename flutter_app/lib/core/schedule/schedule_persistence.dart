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

  Future<void> persistNow(SemesterSchedule schedule, {User? user}) async {
    _debounce?.cancel();
    await _write(schedule, user?.uid);
  }

  void persistDebounced(SemesterSchedule schedule, {User? user}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_write(schedule, user?.uid));
    });
  }

  Future<void> _write(SemesterSchedule schedule, String? uid) async {
    final map = scheduleBundleToJson(
      schedule,
      savedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await local.saveRaw(map);
    if (uid != null &&
        FeatureFlags.enableFirebaseSync &&
        isFirebaseInitialized) {
      try {
        await firestore.pushRaw(uid, map);
      } on Object {
        // Local data already saved; cloud sync can be retried later.
      }
    }
  }

  Future<void> clearLocal() => local.clear();

  Future<void> clearCloud(String uid) async {
    if (!isFirebaseInitialized) return;
    await firestore.delete(uid);
  }
}
