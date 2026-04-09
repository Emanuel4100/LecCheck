import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/schedule/firestore_schedule_store.dart';
import 'package:flutter_app/core/schedule/local_schedule_store.dart';
import 'package:flutter_app/core/schedule/schedule_bootstrap.dart';
import 'package:flutter_app/models/schedule_models.dart';
import 'package:flutter_app/models/schedule_serialization.dart';

class _MemoryLocalStore extends LocalScheduleStore {
  _MemoryLocalStore(this._raw);
  Map<String, dynamic>? _raw;
  Map<String, dynamic>? lastSaved;

  @override
  Future<Map<String, dynamic>?> loadRaw() async => _raw;

  @override
  Future<void> saveRaw(Map<String, dynamic> bundle) async {
    lastSaved = Map<String, dynamic>.from(bundle);
    _raw = lastSaved;
  }
}

class _MemoryFirestoreStore extends FirestoreScheduleStore {
  Map<String, dynamic>? pulled;

  @override
  Future<Map<String, dynamic>?> pullRaw(String uid) async => pulled;

  @override
  Future<void> pushRaw(String uid, Map<String, dynamic> bundle) async {
    pulled = Map<String, dynamic>.from(bundle);
  }
}

ScheduleRootState _root(String slotName, String lang) {
  final sch = SemesterSchedule(
    startDate: DateTime(2024, 9, 1),
    endDate: DateTime(2025, 6, 30),
    language: lang,
  );
  return ScheduleRootState(
    slots: [
      SemesterSlot(id: 's1', name: slotName, schedule: sch),
    ],
    activeSemesterId: 's1',
  );
}

void main() {
  test('no uid: returns local only', () async {
    final root = _root('Local', 'en');
    final map = scheduleRootToJson(root, savedAtMillis: 100);
    final local = _MemoryLocalStore(map);
    final cloud = _MemoryFirestoreStore();

    final r = await loadInitialScheduleState(
      localStore: local,
      cloudStore: cloud,
    );

    expect(r.root?.slots.single.name, 'Local');
    expect(cloud.pulled, isNull);
  });

  test('syncUserIdForTests: pushes local to empty cloud', () async {
    final root = _root('OnlyLocal', 'en');
    final map = scheduleRootToJson(root, savedAtMillis: 200);
    final local = _MemoryLocalStore(map);
    final cloud = _MemoryFirestoreStore();

    final r = await loadInitialScheduleState(
      localStore: local,
      cloudStore: cloud,
      syncUserIdForTests: 'test_uid',
    );

    expect(r.root?.slots.single.name, 'OnlyLocal');
    expect(cloud.pulled, isNotNull);
    expect(cloud.pulled!['semesters'], isList);
  });

  test('syncUserIdForTests: prefers cloud when cloud savedAt is newer', () async {
    final localRoot = _root('LocalName', 'en');
    final cloudRoot = _root('CloudName', 'he');
    final early = DateTime(2024, 1, 1).millisecondsSinceEpoch;
    final late = DateTime(2025, 1, 1).millisecondsSinceEpoch;
    final local = _MemoryLocalStore(
      scheduleRootToJson(localRoot, savedAtMillis: early),
    );
    final cloud = _MemoryFirestoreStore()
      ..pulled = scheduleRootToJson(cloudRoot, savedAtMillis: late);

    final r = await loadInitialScheduleState(
      localStore: local,
      cloudStore: cloud,
      syncUserIdForTests: 'test_uid',
    );

    expect(r.root?.slots.single.name, 'CloudName');
    expect(r.root?.activeSchedule.language, 'he');
  });

  test('syncUserIdForTests: prefers local when local savedAt is newer', () async {
    final localRoot = _root('LocalWins', 'en');
    final cloudRoot = _root('CloudLoses', 'he');
    final early = DateTime(2024, 1, 1).millisecondsSinceEpoch;
    final late = DateTime(2025, 1, 1).millisecondsSinceEpoch;
    final local = _MemoryLocalStore(
      scheduleRootToJson(localRoot, savedAtMillis: late),
    );
    final cloud = _MemoryFirestoreStore()
      ..pulled = scheduleRootToJson(cloudRoot, savedAtMillis: early);

    final r = await loadInitialScheduleState(
      localStore: local,
      cloudStore: cloud,
      syncUserIdForTests: 'test_uid',
    );

    expect(r.root?.slots.single.name, 'LocalWins');
    expect(
      scheduleRootFromJson(cloud.pulled)?.slots.single.name,
      'LocalWins',
    );
  });
}
