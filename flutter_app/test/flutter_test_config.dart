import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/config/test_zone.dart';

import 'support/test_path_provider.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  installTestPathProvider();
  await runZoned(
    () async => await testMain(),
    zoneValues: {leccheckWidgetTestZoneKey: true},
  );
}
