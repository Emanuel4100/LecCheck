import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../models/schedule_models.dart';
import '../../models/schedule_serialization.dart';

Future<void> exportScheduleRoot(ScheduleRootState root) async {
  final map = scheduleRootToJson(
    root,
    savedAtMillis: DateTime.now().millisecondsSinceEpoch,
  );
  final json = const JsonEncoder.withIndent('  ').convert(map);
  if (kIsWeb) {
    await SharePlus.instance.share(
      ShareParams(text: json, subject: 'LecCheck export'),
    );
    return;
  }

  // Linux: use file_picker save dialog (share_plus is unreliable on desktop)
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Export LecCheck data',
      fileName: 'leccheck_export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath != null) {
      await File(savePath).writeAsString(json);
    }
    return;
  }

  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/leccheck_export_${DateTime.now().millisecondsSinceEpoch}.json';
  await File(path).writeAsString(json);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: 'application/json')],
      subject: 'LecCheck export',
    ),
  );
}

/// Returns parsed root or null if invalid.
Future<ScheduleRootState?> pickAndParseScheduleImport(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final res = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (res == null || res.files.isEmpty) return null;
  final file = res.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importInvalidFile)),
      );
    }
    return null;
  }
  try {
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('not a map');
    }
    final parsed = scheduleRootFromJson(raw);
    if (parsed == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importInvalidFile)),
        );
      }
      return null;
    }
    return parsed;
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importInvalidFile)),
      );
    }
    return null;
  }
}
