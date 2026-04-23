import 'package:firebase_auth/firebase_auth.dart';

import 'google_oauth_linux_stub.dart'
    if (dart.library.io) 'google_oauth_linux_io.dart' as impl;

/// Browser + loopback OAuth (PKCE) for Linux desktop.
Future<UserCredential?> signInWithGoogleLinuxDesktop() =>
    impl.signInWithGoogleLinuxDesktop();

/// Whether compile-time `LINUX_GOOGLE_OAUTH_*` defines are non-empty (IO only).
bool get linuxGoogleOAuthDesktopCredentialsConfigured =>
    impl.linuxGoogleOAuthDesktopCredentialsConfigured;

/// Sign out from the Linux REST-based auth session.
Future<void> signOutLinuxDesktop() => impl.signOutLinuxDesktop();
