import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/screens/admin/admin_dashboard_screen.dart';

// Generate mocks
@GenerateMocks([AuthProvider])
import 'admin_dashboard_screen_test.mocks.dart';

// Helper to create the widget tree
Widget createAdminDashboardScreen({required MockAuthProvider mockAuthProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
    ],
    child: const MaterialApp(
      home: AdminDashboardScreen(),
    ),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Default stub for signOut
    when(mockAuthProvider.signOut()).thenAnswer((_) async {});
    // Add stub for user (can be null or a mock user if needed by the widget)
    when(mockAuthProvider.user).thenReturn(null);
  });

  testWidgets('Renders Scaffold, AppBar, title, and placeholder content', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createAdminDashboardScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Admin Dashboard'), findsOneWidget);
    expect(find.text('Welcome, Admin!'), findsOneWidget);
  });

  testWidgets('Renders Logout button in AppBar', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createAdminDashboardScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout)), findsOneWidget);
  });

  testWidgets('Calls signOut when Logout button is tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createAdminDashboardScreen(mockAuthProvider: mockAuthProvider));
    final logoutButtonFinder = find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout));

    // Act
    expect(logoutButtonFinder, findsOneWidget);
    await tester.tap(logoutButtonFinder);
    await tester.pump();

    // Assert
    verify(mockAuthProvider.signOut()).called(1);
  });
} 