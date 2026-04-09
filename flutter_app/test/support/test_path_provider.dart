import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// In-process path roots for tests (avoids hung platform channels under [WidgetTester]).
class LeccheckTestPathProvider extends PathProviderPlatform {
  Directory? _dir;

  String get _root {
    _dir ??= Directory.systemTemp.createTempSync('leccheck_test_paths_');
    return _dir!.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => _root;

  @override
  Future<String?> getTemporaryPath() async => '$_root/tmp';

  @override
  Future<String?> getApplicationSupportPath() async => '$_root/support';

  @override
  Future<String?> getLibraryPath() async => '$_root/Library';

  @override
  Future<String?> getApplicationCachePath() async => '$_root/cache';

  @override
  Future<String?> getExternalStoragePath() async => null;

  @override
  Future<List<String>?> getExternalCachePaths() async => null;

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      null;

  @override
  Future<String?> getDownloadsPath() async => '$_root/Downloads';
}

void installTestPathProvider() {
  PathProviderPlatform.instance = LeccheckTestPathProvider();
}
