import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/providers/auth_status.dart';
import 'package:samabus/screens/auth/signup_screen.dart';
import 'package:samabus/screens/auth/login_screen.dart';
import 'package:samabus/models/user.dart' as app_user;

// Generate mocks
@GenerateMocks([AuthProvider, GoRouter])
import 'signup_screen_test.mocks.dart';

// Helper to create the widget tree
Widget createSignupScreen({required MockAuthProvider mockAuthProvider}) {
  final goRouter = GoRouter(
    initialLocation: SignupScreen.routeName,
    routes: [
      GoRoute(
        path: SignupScreen.routeName,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName,
        builder: (context, state) => const Scaffold(body: Text('Login Mock')), // Dummy
      ),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
    ],
    child: MaterialApp.router(
      routerConfig: goRouter,
    ),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Default stubs
    when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
    when(mockAuthProvider.errorMessage).thenReturn(null);
    // Default stub for signUp call
    when(mockAuthProvider.signUp(
      email: anyNamed('email'),
      password: anyNamed('password'),
      role: anyNamed('role'),
      phone: anyNamed('phone'),
      fullName: anyNamed('fullName'),
      companyName: anyNamed('companyName'),
    )).thenAnswer((_) async => true); // Default to success
  });

  testWidgets('Renders all fields correctly for Traveler role initially', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.widgetWithText(SegmentedButton<app_user.UserRole>, 'Traveler'), findsOneWidget);
    expect(find.widgetWithText(SegmentedButton<app_user.UserRole>, 'Transporteur'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Full Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone Number'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Company Name'), findsNothing); // Should be hidden initially
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Login'), findsOneWidget);
  });

  testWidgets('Shows Company Name field when Transporteur role is selected', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));

    // Act: Tap the Transporteur segment
    // Finding segmented button segments precisely can be tricky, using text might work
    await tester.tap(find.text('Transporteur'));
    await tester.pumpAndSettle(); // Allow state to update and rebuild

    // Assert
    expect(find.widgetWithText(TextField, 'Company Name'), findsOneWidget);
  });

  testWidgets('Hides Company Name field when Traveler role is selected again', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));

    // Act: Select Transporteur, then select Traveler
    await tester.tap(find.text('Transporteur'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Company Name'), findsOneWidget); // Verify it appeared

    await tester.tap(find.text('Traveler'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.widgetWithText(TextField, 'Company Name'), findsNothing);
  });

  testWidgets('Shows validation errors for empty required fields', (WidgetTester tester) async {
     // Arrange
     await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
     final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

     // Act: Ensure button is visible and tap
     await tester.ensureVisible(signupButtonFinder);
     await tester.pumpAndSettle(); // Wait for scroll
     await tester.tap(signupButtonFinder);
     await tester.pump();

     // Assert
     expect(find.text('Please enter your full name'), findsOneWidget);
     expect(find.text('Please enter a valid email'), findsOneWidget);
     expect(find.text('Please enter a valid phone number'), findsOneWidget);
     expect(find.text('Password must be at least 6 characters'), findsOneWidget);
     expect(find.text('Please confirm your password'), findsOneWidget);
   });

  testWidgets('Shows validation error for password mismatch', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
    final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
    final confirmFieldFinder = find.widgetWithText(TextField, 'Confirm Password');
    final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

    // Act
    await tester.enterText(passwordFieldFinder, 'password123');
    await tester.enterText(confirmFieldFinder, 'password456');
    await tester.ensureVisible(signupButtonFinder);
    await tester.pumpAndSettle();
    await tester.tap(signupButtonFinder);
    await tester.pump();

    // Assert
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

   testWidgets('Shows validation error for empty Company Name when Transporteur selected', (WidgetTester tester) async {
     // Arrange
     await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
     final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

     // Act: Select Transporteur, leave company blank, try submit
     await tester.tap(find.text('Transporteur'));
     await tester.pumpAndSettle();
     await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Test Name');
     await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@example.com');
     await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '123456789');
     await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
     await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'password123');
     await tester.ensureVisible(signupButtonFinder);
     await tester.pumpAndSettle();
     await tester.tap(signupButtonFinder);
     await tester.pump();

     // Assert
     expect(find.text('Please enter your company name'), findsOneWidget);
   });

   testWidgets('Calls authProvider.signUp with Traveler details on valid submission', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

      // Act
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Traveler Name');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'traveler@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '111222333');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'password123');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      await tester.pump();

      // Assert
      verify(mockAuthProvider.signUp(
          email: 'traveler@example.com',
          password: 'password123',
          role: app_user.UserRole.traveler,
          phone: '111222333',
          fullName: 'Traveler Name',
          companyName: null, // Important: should be null for traveler
       )).called(1);
   });

    testWidgets('Calls authProvider.signUp with Transporteur details on valid submission', (WidgetTester tester) async {
       // Arrange
       await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
       final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

       // Act: Select role and fill all fields
       await tester.tap(find.text('Transporteur'));
       await tester.pumpAndSettle();
       await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Transporteur Name');
       await tester.enterText(find.widgetWithText(TextField, 'Company Name'), 'Bus Co Inc.');
       await tester.enterText(find.widgetWithText(TextField, 'Email'), 'transporteur@example.com');
       await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '444555666');
       await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password456');
       await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'password456');
       await tester.ensureVisible(signupButtonFinder);
       await tester.pumpAndSettle();
       await tester.tap(signupButtonFinder);
       await tester.pump();

       // Assert
       verify(mockAuthProvider.signUp(
           email: 'transporteur@example.com',
           password: 'password456',
           role: app_user.UserRole.transporteur,
           phone: '444555666',
           fullName: 'Transporteur Name',
           companyName: 'Bus Co Inc.', // Should be passed for transporteur
        )).called(1);
    });

   testWidgets('Shows loading indicator when status is authenticating', (WidgetTester tester) async {
     // Arrange
     when(mockAuthProvider.status).thenReturn(AuthStatus.authenticating);
     await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));

     // Assert
     expect(find.byType(CircularProgressIndicator), findsOneWidget);
     final signupButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sign Up'));
     expect(signupButton.onPressed, isNull); // Button should be disabled
   });

   testWidgets('Shows error message when status is error', (WidgetTester tester) async {
     // Arrange
     final errorMessage = 'Email already exists';
     when(mockAuthProvider.status).thenReturn(AuthStatus.error);
     when(mockAuthProvider.errorMessage).thenReturn(errorMessage);
     await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));

     // Assert
     expect(find.text(errorMessage), findsOneWidget);
   });

    testWidgets('Does not show error/loading after successful signUp call completes', (WidgetTester tester) async {
      // Arrange
      // Ensure signup returns true
      when(mockAuthProvider.signUp(
        email: anyNamed('email'),
        password: anyNamed('password'),
        role: anyNamed('role'),
        phone: anyNamed('phone'),
        fullName: anyNamed('fullName'),
        companyName: anyNamed('companyName'),
      )).thenAnswer((_) async => true);
      // Initial state is unauthenticated, no error
      when(mockAuthProvider.status).thenReturn(AuthStatus.unauthenticated);
      when(mockAuthProvider.errorMessage).thenReturn(null);

      await tester.pumpWidget(createSignupScreen(mockAuthProvider: mockAuthProvider));
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');

      // Act: Fill form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Success User');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'success@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '555666777');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), 'password123');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      // Pump first to show potential loading state if _submit changes status sync
      await tester.pump(); 
      // Pump again or pumpAndSettle to resolve the Future and rebuild after completion
      await tester.pumpAndSettle(); 

      // Assert
      // Verify the call happened
      verify(mockAuthProvider.signUp(
          email: 'success@example.com',
          password: 'password123',
          role: app_user.UserRole.traveler, // Default role
          phone: '555666777',
          fullName: 'Success User',
          companyName: null,
       )).called(1);

      // Assert: No loading indicator should be present after completion
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Assert: No error message should be displayed (check for common validation errors too)
      expect(find.text('Email already exists'), findsNothing); // Example error
      expect(find.text('Please enter your full name'), findsNothing);
      expect(find.text('Passwords do not match'), findsNothing);
      // Verify via mock provider as well
      expect(mockAuthProvider.errorMessage, isNull);
    });

   // TODO: Add test for navigation back to Login

} 