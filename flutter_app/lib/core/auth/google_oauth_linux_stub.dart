import 'package:firebase_auth/firebase_auth.dart';

/// Non-IO builds (e.g. web): Linux OAuth is unavailable.
bool get linuxGoogleOAuthDesktopCredentialsConfigured => false;

/// Web and other non-IO platforms: never called when [TargetPlatform.linux].
Future<UserCredential?> signInWithGoogleLinuxDesktop() async {
  throw UnsupportedError(
    'Google sign-in for Linux is only available in IO builds.',
  );
}

Future<void> signOutLinuxDesktop() async {
  throw UnsupportedError(
    'Linux sign-out is only available in IO builds.',
  );
}
