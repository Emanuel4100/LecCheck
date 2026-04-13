import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';

const String _kUidKey = 'linux_firebase_uid';
const String _kIdTokenKey = 'linux_firebase_id_token';
const String _kRefreshTokenKey = 'linux_firebase_refresh_token';
const String _kExpiresAtKey = 'linux_firebase_expires_at';
const String _kDisplayNameKey = 'linux_firebase_display_name';
const String _kEmailKey = 'linux_firebase_email';

String get _apiKey => DefaultFirebaseOptions.linux.apiKey;

/// Lightweight Firebase Auth session for Linux desktop using REST APIs.
/// On platforms where the Firebase SDK works, this class is not used.
class LinuxAuthSession {
  LinuxAuthSession._();
  static final instance = LinuxAuthSession._();

  String? _uid;
  String? _idToken;
  String? _refreshToken;
  int _expiresAt = 0;
  String? _displayName;
  String? _email;

  String? get uid => _uid;
  String? get displayName => _displayName;
  String? get email => _email;
  bool get isSignedIn => _uid != null && _refreshToken != null;

  /// Restore persisted session from SharedPreferences.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString(_kUidKey);
    _idToken = prefs.getString(_kIdTokenKey);
    _refreshToken = prefs.getString(_kRefreshTokenKey);
    _expiresAt = prefs.getInt(_kExpiresAtKey) ?? 0;
    _displayName = prefs.getString(_kDisplayNameKey);
    _email = prefs.getString(_kEmailKey);
  }

  /// Exchange Google OAuth tokens for a Firebase Auth session via REST API.
  Future<void> signInWithGoogleTokens({
    required String googleIdToken,
    String? googleAccessToken,
  }) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$_apiKey',
    );
    final body = jsonEncode({
      'postBody':
          'id_token=${Uri.encodeQueryComponent(googleIdToken)}&providerId=google.com',
      'requestUri': 'http://localhost',
      'returnSecureToken': true,
      'returnIdpCredential': true,
    });

    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(body);
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw StateError('Firebase signInWithIdp failed (${res.statusCode}): $text');
      }
      final json = jsonDecode(text) as Map<String, dynamic>;

      _uid = json['localId'] as String?;
      _idToken = json['idToken'] as String?;
      _refreshToken = json['refreshToken'] as String?;
      _displayName = json['displayName'] as String?;
      _email = json['email'] as String?;
      final expiresIn = int.tryParse('${json['expiresIn'] ?? ''}') ?? 3600;
      _expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;

      await _persist();
    } finally {
      client.close(force: true);
    }
  }

  /// Returns a valid Firebase ID token, refreshing if expired.
  Future<String?> getValidIdToken() async {
    if (_idToken == null || _refreshToken == null) return null;
    if (DateTime.now().millisecondsSinceEpoch < _expiresAt - 60000) {
      return _idToken;
    }
    await _refreshIdToken();
    return _idToken;
  }

  Future<void> _refreshIdToken() async {
    if (_refreshToken == null) return;
    final uri = Uri.parse(
      'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
    );
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      req.write(
        'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(_refreshToken!)}',
      );
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('Token refresh failed (${res.statusCode}): $text');
        }
        return;
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      _idToken = json['id_token'] as String?;
      _refreshToken = json['refresh_token'] as String? ?? _refreshToken;
      final expiresIn = int.tryParse('${json['expires_in'] ?? ''}') ?? 3600;
      _expiresAt = DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;
      await _persist();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> signOut() async {
    _uid = null;
    _idToken = null;
    _refreshToken = null;
    _expiresAt = 0;
    _displayName = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUidKey);
    await prefs.remove(_kIdTokenKey);
    await prefs.remove(_kRefreshTokenKey);
    await prefs.remove(_kExpiresAtKey);
    await prefs.remove(_kDisplayNameKey);
    await prefs.remove(_kEmailKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_uid != null) await prefs.setString(_kUidKey, _uid!);
    if (_idToken != null) await prefs.setString(_kIdTokenKey, _idToken!);
    if (_refreshToken != null) {
      await prefs.setString(_kRefreshTokenKey, _refreshToken!);
    }
    await prefs.setInt(_kExpiresAtKey, _expiresAt);
    if (_displayName != null) {
      await prefs.setString(_kDisplayNameKey, _displayName!);
    }
    if (_email != null) await prefs.setString(_kEmailKey, _email!);
  }
}
