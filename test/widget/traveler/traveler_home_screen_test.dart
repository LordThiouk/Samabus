import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/screens/traveler/traveler_home_screen.dart';

// Generate mocks
@GenerateMocks([AuthProvider])
import 'traveler_home_screen_test.mocks.dart';

// Helper to create the widget tree
Widget createTravelerHomeScreen({required MockAuthProvider mockAuthProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
    ],
    child: const MaterialApp(
      // Need MaterialApp to provide context for Scaffold, AppBar etc.
      home: TravelerHomeScreen(),
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

  testWidgets('Renders Scaffold, AppBar, and title', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTravelerHomeScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    // Assuming the title is set in the AppBar
    expect(find.widgetWithText(AppBar, 'Traveler Home'), findsOneWidget);
    // Check for placeholder text in the body
    expect(find.text('Welcome, Traveler!'), findsOneWidget);
  });

  testWidgets('Renders Logout button in AppBar', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTravelerHomeScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    // Find the IconButton within the AppBar actions likely used for logout
    // Finding by icon is more robust than tooltip if tooltip isn't set
    expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout)), findsOneWidget);
  });

  testWidgets('Calls signOut when Logout button is tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTravelerHomeScreen(mockAuthProvider: mockAuthProvider));
    final logoutButtonFinder = find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout));

    // Act
    expect(logoutButtonFinder, findsOneWidget); // Ensure button is found before tapping
    await tester.tap(logoutButtonFinder);
    await tester.pump(); // Allow time for async call if needed

    // Assert
    verify(mockAuthProvider.signOut()).called(1);
  });
} 