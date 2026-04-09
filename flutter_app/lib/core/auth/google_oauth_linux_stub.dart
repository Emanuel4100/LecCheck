import 'package:firebase_auth/firebase_auth.dart';

/// Web and other non-IO platforms: never called when [TargetPlatform.linux].
Future<UserCredential?> signInWithGoogleLinuxDesktop() async {
  throw UnsupportedError(
    'Google sign-in for Linux is only available in IO builds.',
  );
}
