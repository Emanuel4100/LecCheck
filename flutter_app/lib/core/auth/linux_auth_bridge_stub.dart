import '../schedule/firestore_schedule_store.dart';

/// Stub for web builds where dart:io is unavailable.
String? get linuxAuthUid => null;
String? get linuxAuthDisplayName => null;
String? get linuxAuthEmail => null;
bool get isLinuxAuthSignedIn => false;
Future<void> restoreLinuxAuthSession() async {}
FirestoreScheduleStore createLinuxFirestoreStore() => FirestoreScheduleStore();
