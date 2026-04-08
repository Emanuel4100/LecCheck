import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// File-based persistence (VM / mobile / desktop). Not used on web.
class LocalScheduleStore {
  static const _fileName = 'leccheck_schedule.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>?> loadRaw() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final text = await f.readAsString();
      if (text.isEmpty) return null;
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> saveRaw(Map<String, dynamic> bundle) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(bundle));
  }

  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
