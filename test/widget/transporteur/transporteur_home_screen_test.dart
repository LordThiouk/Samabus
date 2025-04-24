import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:samabus/models/user.dart' as app_user;
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/screens/transporteur/transporteur_home_screen.dart';

// Generate mocks
@GenerateMocks([AuthProvider])
import 'transporteur_home_screen_test.mocks.dart';

// Helper to create the widget tree
Widget createTransporteurHomeScreen({required MockAuthProvider mockAuthProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
    ],
    child: const MaterialApp(
      home: TransporteurHomeScreen(),
    ),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;
  // Mock App User Models
  final mockApprovedUser = app_user.User(
    id: 'transporter-1',
    role: app_user.UserRole.transporteur,
    isApproved: true, // Approved
    createdAt: DateTime.now(),
    isVerified: true, // Added required field
    // Add other required fields if any, like email/phone, even if null
  );
  final mockPendingUser = app_user.User(
    id: 'transporter-2',
    role: app_user.UserRole.transporteur,
    isApproved: false, // Pending
    createdAt: DateTime.now(),
    isVerified: true, // Added required field
  );

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Default stubs
    when(mockAuthProvider.signOut()).thenAnswer((_) async {});
    // Default to approved user, override in specific tests
    when(mockAuthProvider.user).thenReturn(mockApprovedUser);
    when(mockAuthProvider.isAuthenticated).thenReturn(true); // Assume authenticated if user exists
  });

  testWidgets('Renders Scaffold, AppBar, title, and Logout button', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTransporteurHomeScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Transporteur Dashboard'), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout)), findsOneWidget);
  });

  testWidgets('Calls signOut when Logout button is tapped', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createTransporteurHomeScreen(mockAuthProvider: mockAuthProvider));
    final logoutButtonFinder = find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.logout));

    // Act
    expect(logoutButtonFinder, findsOneWidget);
    await tester.tap(logoutButtonFinder);
    await tester.pump();

    // Assert
    verify(mockAuthProvider.signOut()).called(1);
  });

  testWidgets('Renders Dashboard content when user is approved', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.user).thenReturn(mockApprovedUser);
    await tester.pumpWidget(createTransporteurHomeScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.text('Welcome, Transporteur!'), findsOneWidget);
    expect(find.textContaining('Account Pending Approval'), findsNothing);
  });

  testWidgets('Renders Pending Approval message when user is not approved', (WidgetTester tester) async {
    // Arrange
    when(mockAuthProvider.user).thenReturn(mockPendingUser);
    await tester.pumpWidget(createTransporteurHomeScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.text('Account Pending Approval'), findsOneWidget);
    expect(find.textContaining('currently under review'), findsOneWidget);
    expect(find.text('Welcome, Transporteur!'), findsNothing);
  });

  testWidgets('Renders Pending Approval message when user is null (fallback)', (WidgetTester tester) async {
     // Arrange: Simulate user being null, although router should prevent this
     when(mockAuthProvider.user).thenReturn(null);
     when(mockAuthProvider.isAuthenticated).thenReturn(false);
     await tester.pumpWidget(createTransporteurHomeScreen(mockAuthProvider: mockAuthProvider));

     // Assert: Expect pending message as a safe fallback
     expect(find.text('Account Pending Approval'), findsOneWidget);
     expect(find.textContaining('currently under review'), findsOneWidget);
     expect(find.text('Welcome, Transporteur!'), findsNothing);
   });
} 