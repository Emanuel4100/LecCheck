import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Browser [localStorage] via shared_preferences (path_provider has no web plugin).
class LocalScheduleStore {
  static const _prefsKey = 'leccheck_schedule_bundle_v1';

  Future<Map<String, dynamic>?> loadRaw() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_prefsKey);
      if (s == null || s.isEmpty) return null;
      final decoded = jsonDecode(s);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> saveRaw(Map<String, dynamic> bundle) async {
    final p = await SharedPreferences.getInstance();
    final ok = await p.setString(_prefsKey, jsonEncode(bundle));
    if (!ok) {
      throw StateError('SharedPreferences.setString returned false');
    }
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefsKey);
  }
}
