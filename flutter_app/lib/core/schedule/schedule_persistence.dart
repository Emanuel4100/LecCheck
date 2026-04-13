import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';
import '../config/feature_flags.dart';
import '../firebase/leccheck_firebase.dart';
import 'firestore_schedule_store.dart';
import 'local_schedule_store.dart';

enum SyncStatus { offline, synced, syncing, noNetwork, error }

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

  final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier(SyncStatus.offline);

  void dispose() {
    _debounce?.cancel();
    syncStatus.dispose();
  }

  /// Persist immediately. [user] is from FirebaseAuth (null on Linux).
  Future<void> persistNow(ScheduleRootState root, {User? user}) async {
    _debounce?.cancel();
    await _write(root, user?.uid ?? currentAuthUid);
  }

  void persistDebounced(ScheduleRootState root, {User? user}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_write(root, user?.uid ?? currentAuthUid));
    });
  }

  Future<void> _pushWithRetry(String uid, Map<String, dynamic> map) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        await firestore.pushRaw(uid, map);
        return;
      } on SocketException {
        rethrow;
      } on Object catch (e) {
        lastError = e;
        if (kDebugMode) debugPrint('Cloud push attempt ${attempt + 1} failed: $e');
      }
    }
    throw lastError ?? StateError('Cloud push failed');
  }

  Future<void> _write(ScheduleRootState root, String? uid) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final map = scheduleRootToJson(root, savedAtMillis: now);
    lastLocalSavedAt = now;
    await local.saveRaw(map);
    if (uid != null &&
        FeatureFlags.enableFirebaseSync &&
        isCloudAvailable) {
      syncStatus.value = SyncStatus.syncing;
      try {
        await _pushWithRetry(uid, map);
        syncStatus.value = SyncStatus.synced;
      } on SocketException {
        syncStatus.value = SyncStatus.noNetwork;
      } on Object catch (e) {
        if (kDebugMode) debugPrint('Cloud sync error: $e');
        syncStatus.value = SyncStatus.error;
      }
    } else {
      syncStatus.value = SyncStatus.offline;
    }
  }

  /// Track our own writes so we can skip applying them back as remote changes.
  int lastLocalSavedAt = 0;

  /// Pull from cloud and return the parsed root if it's newer than local.
  /// Updates [syncStatus] so the indicator stays accurate when multiple devices sync.
  Future<ScheduleRootState?> pullIfNewer(String uid) async {
    if (!FeatureFlags.enableFirebaseSync || !isCloudAvailable) return null;
    try {
      final remoteRaw = await firestore.pullRaw(uid);
      if (remoteRaw == null) {
        syncStatus.value = SyncStatus.synced;
        return null;
      }
      final remoteAt = scheduleBundleSavedAt(remoteRaw) ?? 0;
      if (remoteAt <= lastLocalSavedAt) {
        syncStatus.value = SyncStatus.synced;
        return null;
      }
      await local.saveRaw(remoteRaw);
      lastLocalSavedAt = remoteAt;
      syncStatus.value = SyncStatus.synced;
      return scheduleRootFromJson(remoteRaw);
    } on SocketException {
      syncStatus.value = SyncStatus.noNetwork;
      return null;
    } on Object catch (e) {
      if (kDebugMode) debugPrint('pullIfNewer error: $e');
      syncStatus.value = SyncStatus.error;
      return null;
    }
  }

  Future<void> clearLocal() => local.clear();

  Future<void> clearCloud(String uid) async {
    if (!isCloudAvailable) return;
    await firestore.delete(uid);
  }
}
