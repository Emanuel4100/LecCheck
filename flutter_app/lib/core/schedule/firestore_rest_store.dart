import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../firebase_options.dart';
import '../auth/linux_auth_session.dart';
import 'firestore_schedule_store.dart';

String get _projectId => DefaultFirebaseOptions.linux.projectId;

String _docPath(String uid) =>
    'projects/$_projectId/databases/(default)/documents/users/$uid/leccheck/main';

/// Firestore REST API store for Linux desktop (no native Firestore plugin).
class FirestoreRestStore extends FirestoreScheduleStore {
  @override
  Future<Map<String, dynamic>?> pullRaw(String uid) async {
    final token = await LinuxAuthSession.instance.getValidIdToken();
    if (token == null) return null;

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/${_docPath(uid)}',
    );
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set('Authorization', 'Bearer $token');
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode == 404) return null;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('Firestore REST pull failed (${res.statusCode}): $text');
        }
        return null;
      }
      final doc = jsonDecode(text) as Map<String, dynamic>;
      final fields = doc['fields'] as Map<String, dynamic>?;
      if (fields == null) return null;
      final bundleField = fields['bundle'];
      if (bundleField == null) return null;
      return _fromFirestoreValue(bundleField) as Map<String, dynamic>?;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> pushRaw(String uid, Map<String, dynamic> bundle) async {
    final token = await LinuxAuthSession.instance.getValidIdToken();
    if (token == null) return;

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/${_docPath(uid)}'
      '?updateMask.fieldPaths=bundle&updateMask.fieldPaths=updatedAt',
    );
    final body = jsonEncode({
      'fields': {
        'bundle': _toFirestoreValue(bundle),
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      },
    });

    final client = HttpClient();
    try {
      final req = await client.openUrl('PATCH', uri);
      req.headers.set('Authorization', 'Bearer $token');
      req.headers.contentType = ContentType.json;
      req.write(body);
      final res = await req.close();
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('Firestore REST push failed (${res.statusCode}): $text');
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> delete(String uid) async {
    final token = await LinuxAuthSession.instance.getValidIdToken();
    if (token == null) return;

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/${_docPath(uid)}',
    );
    final client = HttpClient();
    try {
      final req = await client.deleteUrl(uri);
      req.headers.set('Authorization', 'Bearer $token');
      final res = await req.close();
      await res.drain<void>();
    } finally {
      client.close(force: true);
    }
  }
}

/// Convert a Dart value to Firestore REST API value format.
Map<String, dynamic> _toFirestoreValue(Object? value) {
  if (value == null) return {'nullValue': null};
  if (value is bool) return {'booleanValue': value};
  if (value is int) return {'integerValue': '$value'};
  if (value is double) return {'doubleValue': value};
  if (value is String) return {'stringValue': value};
  if (value is List) {
    return {
      'arrayValue': {
        'values': value.map((e) => _toFirestoreValue(e)).toList(),
      },
    };
  }
  if (value is Map) {
    final fields = <String, dynamic>{};
    for (final entry in value.entries) {
      fields['${entry.key}'] = _toFirestoreValue(entry.value);
    }
    return {
      'mapValue': {'fields': fields},
    };
  }
  return {'stringValue': value.toString()};
}

/// Convert a Firestore REST API value back to a Dart value.
Object? _fromFirestoreValue(Object? value) {
  if (value == null) return null;
  if (value is! Map<String, dynamic>) return null;
  if (value.containsKey('nullValue')) return null;
  if (value.containsKey('booleanValue')) return value['booleanValue'] as bool;
  if (value.containsKey('integerValue')) {
    return int.tryParse('${value['integerValue']}') ?? 0;
  }
  if (value.containsKey('doubleValue')) {
    final v = value['doubleValue'];
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }
  if (value.containsKey('stringValue')) return value['stringValue'] as String;
  if (value.containsKey('arrayValue')) {
    final arr = value['arrayValue'] as Map<String, dynamic>?;
    final values = arr?['values'] as List<dynamic>?;
    if (values == null) return <dynamic>[];
    return values.map(_fromFirestoreValue).toList();
  }
  if (value.containsKey('mapValue')) {
    final mv = value['mapValue'] as Map<String, dynamic>?;
    final fields = mv?['fields'] as Map<String, dynamic>?;
    if (fields == null) return <String, dynamic>{};
    return fields.map((k, v) => MapEntry(k, _fromFirestoreValue(v)));
  }
  if (value.containsKey('timestampValue')) {
    return value['timestampValue'] as String;
  }
  return null;
}
