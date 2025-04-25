// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:go_router/go_router.dart';
import 'package:samabus/main.dart';
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/providers/auth_status.dart';
import 'package:samabus/routes/app_router.dart';

@GenerateMocks([AuthProvider])
import 'widget_test.mocks.dart';

void main() {
  // Initialize binding
  TestWidgetsFlutterBinding.ensureInitialized(); 
  
  late MockAuthProvider mockAuthProvider;
  late GoRouter testRouter;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Default stubs for the mock provider
    when(mockAuthProvider.status).thenReturn(AuthStatus.uninitialized);
    when(mockAuthProvider.user).thenReturn(null);
    when(mockAuthProvider.addListener(any)).thenAnswer((_) {});
    
    // Use the actual router logic but with the mocked provider
    testRouter = AppRouter.createRouter(mockAuthProvider);
  });

  testWidgets('MyApp builds ok', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      authProvider: mockAuthProvider,
      appRouter: testRouter,
    ));

    // Verify that MyApp renders something (e.g., MaterialApp)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
