import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:url_launcher/url_launcher.dart';

import 'linux_auth_session.dart';

/// Desktop OAuth client credentials loaded at compile time via
/// --dart-define-from-file=.env (see flutter_app/.env.example).
const String _linuxOAuthClientId = String.fromEnvironment(
  'LINUX_GOOGLE_OAUTH_CLIENT_ID',
);
const String _linuxOAuthClientSecret = String.fromEnvironment(
  'LINUX_GOOGLE_OAUTH_CLIENT_SECRET',
);

String _base64UrlNoPad(List<int> bytes) {
  return base64Encode(bytes)
      .replaceAll('+', '-')
      .replaceAll('/', '_')
      .replaceAll('=', '');
}

String _randomVerifier() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(48, (_) => rnd.nextInt(256));
  return _base64UrlNoPad(bytes);
}

Future<UserCredential?> signInWithGoogleLinuxDesktop() async {
  if (defaultTargetPlatform != TargetPlatform.linux) {
    throw StateError('signInWithGoogleLinuxDesktop is only for Linux');
  }

  final codeVerifier = _randomVerifier();
  final challengeBytes = sha256.convert(utf8.encode(codeVerifier)).bytes;
  final codeChallenge = _base64UrlNoPad(challengeBytes);
  final state = _randomVerifier();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  final redirectUri = 'http://127.0.0.1:$port/';

  try {
    final authUri = Uri.https(
      'accounts.google.com',
      '/o/oauth2/v2/auth',
      <String, String>{
        'client_id': _linuxOAuthClientId,
        'response_type': 'code',
        'scope': 'openid email profile',
        'redirect_uri': redirectUri,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Could not open browser for Google sign-in.');
    }

    final request = await server.first
        .timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw TimeoutException('Google sign-in timed out.'),
        );

    final uri = request.uri;
    final err = uri.queryParameters['error'];
    if (err != null) {
      final desc = uri.queryParameters['error_description'] ?? err;
      await _respondHtml(request, ok: false, message: desc);
      throw StateError('Google sign-in failed: $desc');
    }
    if (uri.queryParameters['state'] != state) {
      await _respondHtml(request, ok: false, message: 'Invalid state');
      throw StateError('OAuth state mismatch.');
    }
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      await _respondHtml(request, ok: false, message: 'Missing code');
      throw StateError('Google did not return an authorization code.');
    }
    await _respondHtml(request, ok: true, message: '');

    final tokenJson = await _exchangeCode(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );

    final idToken = tokenJson['id_token'] as String?;
    final accessToken = tokenJson['access_token'] as String?;
    if (idToken == null) {
      throw StateError('Token response missing id_token.');
    }

    await LinuxAuthSession.instance.signInWithGoogleTokens(
      googleIdToken: idToken,
      googleAccessToken: accessToken,
    );
    return null;
  } finally {
    await server.close(force: true);
  }
}

Future<void> signOutLinuxDesktop() => LinuxAuthSession.instance.signOut();

Future<void> _respondHtml(HttpRequest request, {required bool ok, required String message}) async {
  request.response.statusCode = ok ? 200 : 400;
  request.response.headers.contentType = ContentType.html;
  request.response.write(
    '<!DOCTYPE html><html><head><meta charset="utf-8"><title>LecCheck</title></head>'
    '<body style="font-family:sans-serif;padding:24px">'
    '${ok ? '<p>Sign-in complete. You can close this tab and return to LecCheck.</p>' : '<p>Sign-in failed. $message</p>'}'
    '</body></html>',
  );
  await request.response.close();
}

Future<Map<String, dynamic>> _exchangeCode({
  required String code,
  required String codeVerifier,
  required String redirectUri,
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('https://oauth2.googleapis.com/token');
    final req = await client.postUrl(uri);
    req.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    final body = <String, String>{
      'code': code,
      'client_id': _linuxOAuthClientId,
      'client_secret': _linuxOAuthClientSecret,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': redirectUri,
    };
    req.write(
      body.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&'),
    );
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Token exchange failed (${res.statusCode}): $text');
    }
    final json = jsonDecode(text);
    if (json is! Map<String, dynamic>) {
      throw StateError('Invalid token response');
    }
    return json;
  } finally {
    client.close(force: true);
  }
}
