import '../schedule/firestore_rest_store.dart';
import '../schedule/firestore_schedule_store.dart';
import 'linux_auth_session.dart';

String? get linuxAuthUid => LinuxAuthSession.instance.uid;
String? get linuxAuthDisplayName => LinuxAuthSession.instance.displayName;
String? get linuxAuthEmail => LinuxAuthSession.instance.email;
bool get isLinuxAuthSignedIn => LinuxAuthSession.instance.isSignedIn;
Future<void> restoreLinuxAuthSession() => LinuxAuthSession.instance.restore();

/// Returns a Firestore store backed by the REST API for Linux desktop.
FirestoreScheduleStore createLinuxFirestoreStore() => FirestoreRestStore();
