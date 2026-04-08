import 'package:firebase_auth/firebase_auth.dart';

import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';
import '../config/feature_flags.dart';
import '../firebase/leccheck_firebase.dart';
import 'firestore_schedule_store.dart';
import 'local_schedule_store.dart';

/// Loads and merges local + cloud schedule on cold start (or right after Google sign-in).
Future<({SemesterSchedule? schedule, User? user})> loadInitialScheduleState({
  LocalScheduleStore? localStore,
  FirestoreScheduleStore? cloudStore,
}) async {
  final local = localStore ?? LocalScheduleStore();
  final cloud = cloudStore ?? FirestoreScheduleStore();
  final user = FirebaseAuth.instance.currentUser;

  final localRaw = await local.loadRaw();
  final localSchedule = scheduleBundleFromJson(localRaw);
  final localAt = scheduleBundleSavedAt(localRaw) ?? 0;

  if (user != null &&
      FeatureFlags.enableFirebaseSync &&
      isFirebaseInitialized) {
    final cloudRaw = await cloud.pullRaw(user.uid);
    final cloudSchedule = scheduleBundleFromJson(cloudRaw);
    final cloudAt = scheduleBundleSavedAt(cloudRaw) ?? 0;

    if (cloudSchedule == null && localSchedule != null) {
      final map = scheduleBundleToJson(
        localSchedule,
        savedAtMillis:
            localAt > 0 ? localAt : DateTime.now().millisecondsSinceEpoch,
      );
      await local.saveRaw(map);
      await cloud.pushRaw(user.uid, map);
      return (schedule: localSchedule, user: user);
    }
    if (cloudSchedule != null && localSchedule == null) {
      if (cloudRaw != null) await local.saveRaw(cloudRaw);
      return (schedule: cloudSchedule, user: user);
    }
    if (cloudSchedule != null && localSchedule != null) {
      final useLocal = localAt >= cloudAt;
      if (useLocal) {
        final map = scheduleBundleToJson(
          localSchedule,
          savedAtMillis: DateTime.now().millisecondsSinceEpoch,
        );
        await local.saveRaw(map);
        await cloud.pushRaw(user.uid, map);
        return (schedule: localSchedule, user: user);
      } else {
        if (cloudRaw != null) await local.saveRaw(cloudRaw);
        return (schedule: cloudSchedule, user: user);
      }
    }
    return (schedule: null, user: user);
  }

  return (schedule: localSchedule, user: user);
}
