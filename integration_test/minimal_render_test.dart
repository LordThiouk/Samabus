// integration_test/minimal_render_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:samabus/main.dart' as app; // Import the main app entry point

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Minimal app render test', (WidgetTester tester) async {
    // Run the app's main function to initialize everything
    // (This is needed because main sets up providers before runApp)
    print('Minimal Test: Running app.main()...');
    await app.main();
    print('Minimal Test: app.main() completed. Pumping...');
    await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for async init in main
    print('Minimal Test: Pump finished. Dumping app tree...');

    // Now check if the root widget rendered
    debugDumpApp(); // See what actually rendered
    print('Minimal Test: Checking expectations...');
    expect(find.byType(app.MyApp), findsOneWidget, reason: 'MyApp widget not found');
    expect(find.byType(MaterialApp), findsOneWidget, reason: 'MaterialApp widget not found');
    print('Minimal Test: Expectations checked.');

  });
} 