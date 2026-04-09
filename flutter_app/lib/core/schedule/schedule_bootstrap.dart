import 'package:firebase_auth/firebase_auth.dart';

import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';
import '../config/feature_flags.dart';
import '../firebase/leccheck_firebase.dart';
import 'firestore_schedule_store.dart';
import 'local_schedule_store.dart';

/// Loads and merges local + cloud schedule on cold start (or right after Google sign-in).
///
/// [syncUserIdForTests] runs the cloud merge branches with this uid using [cloudStore]
/// without requiring Firebase Auth (unit tests only).
Future<({ScheduleRootState? root, User? user})> loadInitialScheduleState({
  LocalScheduleStore? localStore,
  FirestoreScheduleStore? cloudStore,
  String? syncUserIdForTests,
}) async {
  final local = localStore ?? LocalScheduleStore();
  final cloud = cloudStore ?? FirestoreScheduleStore();
  final authUser = firebaseCurrentUserIfReady;
  final uid = syncUserIdForTests ?? authUser?.uid;

  final localRaw = await local.loadRaw();
  final localRoot = scheduleRootFromJson(localRaw);
  final localAt = scheduleBundleSavedAt(localRaw) ?? 0;

  final cloudAllowed = uid != null &&
      FeatureFlags.enableFirebaseSync &&
      (syncUserIdForTests != null || isFirebaseInitialized);

  if (cloudAllowed) {
    final cloudRaw = await cloud.pullRaw(uid);
    final cloudRoot = scheduleRootFromJson(cloudRaw);
    final cloudAt = scheduleBundleSavedAt(cloudRaw) ?? 0;

    if (cloudRoot == null && localRoot != null) {
      final map = scheduleRootToJson(
        localRoot,
        savedAtMillis:
            localAt > 0 ? localAt : DateTime.now().millisecondsSinceEpoch,
      );
      await local.saveRaw(map);
      await cloud.pushRaw(uid, map);
      return (root: localRoot, user: authUser);
    }
    if (cloudRoot != null && localRoot == null) {
      if (cloudRaw != null) await local.saveRaw(cloudRaw);
      return (root: cloudRoot, user: authUser);
    }
    if (cloudRoot != null && localRoot != null) {
      final useLocal = localAt >= cloudAt;
      if (useLocal) {
        final map = scheduleRootToJson(
          localRoot,
          savedAtMillis: DateTime.now().millisecondsSinceEpoch,
        );
        await local.saveRaw(map);
        await cloud.pushRaw(uid, map);
        return (root: localRoot, user: authUser);
      } else {
        if (cloudRaw != null) await local.saveRaw(cloudRaw);
        return (root: cloudRoot, user: authUser);
      }
    }
    return (root: null, user: authUser);
  }

  return (root: localRoot, user: authUser);
}
