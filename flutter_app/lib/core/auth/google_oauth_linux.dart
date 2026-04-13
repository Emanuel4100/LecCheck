import 'package:firebase_auth/firebase_auth.dart';

import 'google_oauth_linux_stub.dart'
    if (dart.library.io) 'google_oauth_linux_io.dart' as impl;

/// Browser + loopback OAuth (PKCE) for Linux desktop.
Future<UserCredential?> signInWithGoogleLinuxDesktop() =>
    impl.signInWithGoogleLinuxDesktop();

/// Sign out from the Linux REST-based auth session.
Future<void> signOutLinuxDesktop() => impl.signOutLinuxDesktop();
