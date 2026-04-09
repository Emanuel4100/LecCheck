import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: app shows welcome', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 20));
    expect(find.text('Welcome to LecCheck'), findsOneWidget);
  });
}
