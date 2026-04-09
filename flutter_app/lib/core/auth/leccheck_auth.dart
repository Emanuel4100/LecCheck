import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';
import 'google_oauth_linux.dart';

/// Google Play Services [ApiException] code 10 = DEVELOPER_ERROR (SHA-1 / OAuth client mismatch).
bool isGoogleSignInAndroidDeveloperError(Object error) {
  final s = error.toString();
  if (s.contains('DEVELOPER_ERROR')) return true;
  if (s.contains('ApiException: 10') || s.contains('ApiException:10')) {
    return true;
  }
  if (error is PlatformException && error.code == 'sign_in_failed') {
    if (s.contains('10:') &&
        (s.contains('gms') ||
            s.contains('ApiException') ||
            s.contains('com.google'))) {
      return true;
    }
  }
  return false;
}

bool get googleSignInSupportedOnPlatform {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return true;
    case TargetPlatform.windows:
    case TargetPlatform.fuchsia:
      return false;
  }
}

String? _googleSignInClientIdOverride() {
  if (kIsWeb) {
    return '214900154341-blf4qu5100rt8snak2i8r50s3ult8vhq.apps.googleusercontent.com';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return DefaultFirebaseOptions.ios.iosClientId;
    case TargetPlatform.macOS:
      return DefaultFirebaseOptions.macos.iosClientId;
    default:
      return null;
  }
}

GoogleSignIn? _googleSignInInstance;

GoogleSignIn get _googleSignIn =>
    _googleSignInInstance ??= GoogleSignIn(
      clientId: _googleSignInClientIdOverride(),
    );

/// Returns [UserCredential] on success, or null if the user closed the picker.
Future<UserCredential?> signInWithGoogle() async {
  if (Firebase.apps.isEmpty) {
    throw StateError('Firebase is not initialized on this platform.');
  }
  if (kIsWeb) {
    // Web: avoid google_sign_in's People API dependency (403 if API disabled).
    return FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }
  if (defaultTargetPlatform == TargetPlatform.linux) {
    return signInWithGoogleLinuxDesktop();
  }

  final account = await _googleSignIn.signIn();
  if (account == null) return null;

  final auth = await account.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: auth.accessToken,
    idToken: auth.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}

Future<void> signOutEverywhere() async {
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
    try {
      await _googleSignIn.signOut();
    } on Object {
      // Ignore if GoogleSignIn was never used on this platform.
    }
  }
  await FirebaseAuth.instance.signOut();
}
