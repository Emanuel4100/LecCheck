import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb;

import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';
import '../auth/linux_auth_bridge.dart';
import '../config/feature_flags.dart';
import '../firebase/leccheck_firebase.dart';
import 'firestore_schedule_store.dart';
import 'local_schedule_store.dart';

const Duration _cloudTimeout = Duration(seconds: 8);

FirestoreScheduleStore _defaultCloudStore() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    return createLinuxFirestoreStore();
  }
  return FirestoreScheduleStore();
}

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
  final cloud = cloudStore ?? _defaultCloudStore();
  final authUser = firebaseCurrentUserIfReady;
  final uid = syncUserIdForTests ?? currentAuthUid;

  final localRaw = await local.loadRaw();
  final localRoot = scheduleRootFromJson(localRaw);
  final localAt = scheduleBundleSavedAt(localRaw) ?? 0;

  final cloudAllowed = uid != null &&
      FeatureFlags.enableFirebaseSync &&
      (syncUserIdForTests != null || isCloudAvailable);

  if (cloudAllowed) {
    try {
      return await _loadWithCloud(
        local: local,
        cloud: cloud,
        uid: uid,
        authUser: authUser,
        localRaw: localRaw,
        localRoot: localRoot,
        localAt: localAt,
      ).timeout(_cloudTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('Cloud sync timed out after $_cloudTimeout; using local data.');
      }
      return (root: localRoot, user: authUser);
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('Cloud sync failed: $e\n$st');
      }
      return (root: localRoot, user: authUser);
    }
  }

  return (root: localRoot, user: authUser);
}

Future<({ScheduleRootState? root, User? user})> _loadWithCloud({
  required LocalScheduleStore local,
  required FirestoreScheduleStore cloud,
  required String uid,
  required User? authUser,
  required Map<String, dynamic>? localRaw,
  required ScheduleRootState? localRoot,
  required int localAt,
}) async {
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
