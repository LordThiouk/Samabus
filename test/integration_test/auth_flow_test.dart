import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:samabus/main.dart' as app;
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/screens/auth/login_screen.dart'; // Import LoginScreen
import 'package:samabus/screens/auth/signup_screen.dart'; // Import SignupScreen
import 'package:samabus/screens/traveler/traveler_home_screen.dart'; // Import TravelerHomeScreen
import 'package:samabus/screens/transporteur/transporteur_home_screen.dart'; // Import TransporteurHomeScreen
import 'package:samabus/models/user.dart' as app_user; // Import User model for role enum
import 'package:samabus/screens/auth/forgot_password_screen.dart'; // Import ForgotPasswordScreen
// Import other necessary screens/providers if needed

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // setUpAll runs ONCE before all tests in the group/file
  setUpAll(() async { // Make setUpAll async
    WidgetsFlutterBinding.ensureInitialized(); // Explicitly ensure bindings before app init
    print('Setting up integration test environment...');
    // Initialize Supabase/App ONCE here
    await app.main(); // Await the app's main function
    print('App main() completed in setUpAll.');

    // Add a small delay AFTER app.main() completes to ensure initial state is settled.
    // This helps prevent issues where tests run before the initial auth state check completes.
    // You might need WidgetsFlutterBinding.instance.performReassemble(); if hot restart simulation needed
    // binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive; // Alternative if pumpAndSettle times out
    await Future.delayed(const Duration(seconds: 2)); 
  });

  tearDownAll(() {
    print('Tearing down integration test environment...');
  });

  setUp(() {
    // Reset state before each test if necessary
    print('Setting up test case...');
  });

  tearDown(() {
    // Clean up after each test if necessary
    print('Tearing down test case...');
  });

  // Example Test Group
  group('Authentication Flow Tests', () {
    testWidgets('Initial app state shows LoginScreen', (WidgetTester tester) async {
      // Arrange: App is already started in setUpAll
      // app.main(); // REMOVE from here
      // Ensure the frame is rendered AFTER setUpAll finishes
      await tester.pumpAndSettle(); 

      // Assert
      // Verify that the initial screen is LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Navigates to SignupScreen and attempts Traveler signup', (WidgetTester tester) async {
      // Arrange: Start app - NO, app already started
      // app.main(); // REMOVE
      // Ensure we are starting from a known state (Login Screen)
      // If previous tests logged in, we need to ensure logout first or handle it.
      // For now, assume starting fresh or handle logout in tearDown/setUp.
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      // Verify we are on LoginScreen before proceeding (important between tests)
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      final signupLinkFinder = find.widgetWithText(TextButton, 'Sign Up');
      expect(signupLinkFinder, findsOneWidget);
      await tester.tap(signupLinkFinder);
      await tester.pumpAndSettle();

      // Assert: Verify on Signup Screen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Arrange: Generate unique credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'traveler_$timestamp@test.com';
      final password = 'password123';

      // Act: Fill form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Test Traveler $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '100${timestamp % 10000000}'); // Generate pseudo-unique phone
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);
      
      // Ensure the Traveler role is selected (it should be by default)
      // We might need a more robust way to find the SegmentedButton if simple text fails
      // expect(tester.widget<SegmentedButton>(find.byType(SegmentedButton<app_user.UserRole>)).selected.first, app_user.UserRole.traveler);

      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(signupButtonFinder, findsOneWidget);
      await tester.ensureVisible(signupButtonFinder); // Scroll if needed
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);

      // Wait for signup process and potential navigation
      // Increased duration as this involves network calls
      await tester.pumpAndSettle(const Duration(seconds: 5)); 

      // Assert: Should navigate to TravelerHomeScreen (assuming auto-verification)
      // This assertion depends heavily on Supabase email verification settings
      // If verification is ON, this will fail, and we should expect LoginScreen or a verification message.
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Expected to land on Traveler Home Screen after signup (assuming auto-verification)');
      expect(find.byType(SignupScreen), findsNothing);
    });

    testWidgets('Navigates to SignupScreen and attempts Transporteur signup (lands on Pending)', (WidgetTester tester) async {
      // Arrange: Start app - NO
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      final signupLinkFinder = find.widgetWithText(TextButton, 'Sign Up');
      expect(signupLinkFinder, findsOneWidget);
      await tester.tap(signupLinkFinder);
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Arrange: Generate unique credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'transporteur_$timestamp@test.com';
      final companyName = 'Bus Company $timestamp';
      final password = 'password123';

      // Act: Select Transporteur role
      // Tapping the text within the SegmentedButton segment
      await tester.tap(find.text('Transporteur'));
      await tester.pumpAndSettle(); // Wait for Company Name field to appear

      // Act: Fill form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Test Transporter $timestamp');
      expect(find.widgetWithText(TextField, 'Company Name'), findsOneWidget, reason: 'Company Name field should be visible after selecting Transporteur');
      await tester.enterText(find.widgetWithText(TextField, 'Company Name'), companyName);
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '200${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);

      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(signupButtonFinder, findsOneWidget);
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);

      // Wait for signup process and potential navigation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert: Should navigate to TransporteurHomeScreen and show Pending state
      expect(find.byType(TransporteurHomeScreen), findsOneWidget, reason: 'Expected to land on Transporteur Home Screen after signup');
      expect(find.byType(SignupScreen), findsNothing);
      expect(find.text('Account Pending Approval'), findsOneWidget, reason: 'Expected Pending Approval title');
      expect(find.textContaining('currently under review'), findsOneWidget, reason: 'Expected Pending Approval description');
      expect(find.text('Welcome, Transporteur!'), findsNothing, reason: 'Approved dashboard text should not be visible');
    });

    testWidgets('Signs up, logs out, and logs back in as Traveler', (WidgetTester tester) async {
      // --- Part 1: Sign Up --- 
      // Arrange: Start app - NO
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Arrange: Generate unique credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'traveler_login_test_$timestamp@test.com';
      final password = 'password123';

      // Act: Fill form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Login Test Traveler $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '300${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);
      
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); 

      // Assert: Should be on TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup failed or navigated incorrectly');

      // --- Part 2: Log Out ---
      // Act: Find and tap logout button
      final logoutButtonFinder = find.descendant(
        of: find.byType(AppBar).first, // Be specific if multiple AppBars exist
        matching: find.byIcon(Icons.logout)
      );
      expect(logoutButtonFinder, findsOneWidget, reason: 'Logout button not found on Traveler Home Screen');
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for logout and redirect

      // Assert: Should be back on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout did not return to Login Screen');
      expect(find.byType(TravelerHomeScreen), findsNothing);

      // --- Part 3: Log In ---
      // Act: Enter credentials used for signup
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      
      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButtonFinder, findsOneWidget);
      await tester.ensureVisible(loginButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for login and redirect

      // Assert: Should be back on TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Login failed or navigated incorrectly');
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Login fails with incorrect password', (WidgetTester tester) async {
      // --- Part 1: Sign Up & Logout (to ensure user exists) --- 
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'fail_login_test_$timestamp@test.com';
      final correctPassword = 'password123';
      final incorrectPassword = 'wrongpassword';

      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Fail Login Test $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '400${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), correctPassword);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), correctPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle(const Duration(seconds: 5)); 
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup failed');

      final logoutButtonFinder = find.descendant(of: find.byType(AppBar).first, matching: find.byIcon(Icons.logout));
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout failed');

      // --- Part 2: Attempt Incorrect Login ---
      // Act: Enter correct email but incorrect password
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), incorrectPassword); 
      
      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButtonFinder, findsOneWidget);
      await tester.ensureVisible(loginButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(loginButtonFinder);
      // Need pump, not pumpAndSettle, to catch the state *during* the error display
      await tester.pump(const Duration(seconds: 3)); 

      // Assert: Should still be on LoginScreen and show error
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Should remain on Login Screen after failed attempt');
      expect(find.byType(TravelerHomeScreen), findsNothing);
      // Check for the specific error message provided by Supabase/AuthService
      // This might be in a SnackBar, a Text widget, etc.
      // Let's look for the common Supabase message.
      expect(find.text('Invalid login credentials'), findsOneWidget, reason: 'Error message for invalid credentials not found'); 
    });

    testWidgets('Signup fails if email already exists', (WidgetTester tester) async {
      // --- Part 1: Sign Up User 1 & Logout --- 
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final existingEmail = 'existing_$timestamp@test.com'; // Email to be reused
      final firstPassword = 'password123';

      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'First User $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), existingEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '500${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), firstPassword);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), firstPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle(const Duration(seconds: 5)); 
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup 1 failed');

      final logoutButtonFinder = find.descendant(of: find.byType(AppBar).first, matching: find.byIcon(Icons.logout));
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout failed');

      // --- Part 2: Attempt Signup with Same Email ---
      // Act: Navigate back to Signup Screen
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Act: Fill form with the SAME email but different details
      final secondPassword = 'password456';
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Second User $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), existingEmail); // <<< SAME EMAIL
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '501${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), secondPassword);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), secondPassword);
      
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(signupButtonFinder, findsOneWidget);
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      // Use pump to catch error state
      await tester.pump(const Duration(seconds: 3)); 

      // Assert: Should still be on SignupScreen and show error
      expect(find.byType(SignupScreen), findsOneWidget, reason: 'Should remain on Signup Screen after duplicate email attempt');
      expect(find.byType(TravelerHomeScreen), findsNothing);
      // Check for Supabase specific error message
      expect(find.text('User already registered'), findsOneWidget, reason: 'Error message for duplicate email not found');
    });

    testWidgets('Signs up, logs out, and logs back in as Transporteur (lands on Pending)', (WidgetTester tester) async {
      // --- Part 1: Sign Up & Logout ---
      // Arrange: Start app - NO
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Arrange: Generate unique Transporteur credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'transporter_login_$timestamp@test.com';
      final companyName = 'Bus Login Test $timestamp';
      final password = 'password123';

      // Act: Select Transporteur role
      await tester.tap(find.text('Transporteur'));
      await tester.pumpAndSettle();

      // Act: Fill Transporteur form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Login Transporter $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Company Name'), companyName);
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '600${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);
      
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); 

      // Assert: Should be on TransporteurHomeScreen showing Pending
      expect(find.byType(TransporteurHomeScreen), findsOneWidget, reason: 'Transporteur signup failed or navigated incorrectly');
      expect(find.text('Account Pending Approval'), findsOneWidget, reason: 'Expected Pending Approval message after Transporteur signup');

      // Act: Log out
      final logoutButtonFinder = find.descendant(of: find.byType(AppBar).first, matching: find.byIcon(Icons.logout));
      expect(logoutButtonFinder, findsOneWidget, reason: 'Logout button not found on Transporteur Home Screen');
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert: Should be back on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout did not return to Login Screen');
      expect(find.byType(TransporteurHomeScreen), findsNothing);

      // --- Part 2: Log In ---
      // Act: Enter Transporteur credentials
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      
      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButtonFinder, findsOneWidget);
      await tester.ensureVisible(loginButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); 

      // Assert: Should be back on TransporteurHomeScreen, still pending
      expect(find.byType(TransporteurHomeScreen), findsOneWidget, reason: 'Transporteur login failed or navigated incorrectly');
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('Account Pending Approval'), findsOneWidget, reason: 'Expected Pending Approval message after Transporteur login');
      expect(find.text('Welcome, Transporteur!'), findsNothing);
    });

    testWidgets('Logout from Traveler Home Screen navigates to Login Screen', (WidgetTester tester) async {
      // --- Part 1: Sign Up & Reach Home Screen ---
      // Arrange: Start app - NO
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Arrange: Generate unique Traveler credentials
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'logout_test_$timestamp@test.com';
      final password = 'password123';

      // Act: Fill form and submit
      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Logout Test $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '700${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);
      
      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(signupButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); 

      // Assert: Should be on TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup failed, cannot test logout');

      // --- Part 2: Log Out ---
      // Act: Find and tap logout button
      final logoutButtonFinder = find.descendant(
        of: find.byType(AppBar).first, // Be specific if multiple AppBars exist
        matching: find.byIcon(Icons.logout)
      );
      expect(logoutButtonFinder, findsOneWidget, reason: 'Logout button not found on Traveler Home Screen');
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for logout and redirect

      // Assert: Should be back on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout did not return to Login Screen');
      expect(find.byType(TravelerHomeScreen), findsNothing);
    });

    testWidgets('Password Reset Flow shows confirmation message', (WidgetTester tester) async {
      // --- Part 1: Sign Up User & Logout --- 
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final existingEmail = 'reset_test_$timestamp@test.com';
      final password = 'password123';

      await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Reset Test $timestamp');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), existingEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Phone Number'), '800${timestamp % 10000000}');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.enterText(find.widgetWithText(TextField, 'Confirm Password'), password);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle(const Duration(seconds: 5)); 
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup failed');

      final logoutButtonFinder = find.descendant(of: find.byType(AppBar).first, matching: find.byIcon(Icons.logout));
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout failed');

      // --- Part 2: Request Password Reset ---
      // Act: Navigate to Forgot Password Screen
      final forgotPasswordLinkFinder = find.widgetWithText(TextButton, 'Forgot Password?');
      expect(forgotPasswordLinkFinder, findsOneWidget);
      await tester.tap(forgotPasswordLinkFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Act: Enter the existing email and submit
      await tester.enterText(find.widgetWithText(TextField, 'Email'), existingEmail);
      final sendButtonFinder = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      expect(sendButtonFinder, findsOneWidget);
      await tester.ensureVisible(sendButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(sendButtonFinder);
      
      // Use pump to allow time for processing and potential message display
      await tester.pump(const Duration(seconds: 3)); 

      // Assert: Confirmation message should be shown
      // Assuming the message is displayed in a SnackBar, adjust if needed
      expect(find.byType(SnackBar), findsOneWidget, reason: 'Confirmation SnackBar not found');
      expect(find.textContaining('Password reset instructions sent'), findsOneWidget, reason: 'Confirmation message not found in SnackBar');

      // Assert: Should ideally navigate back to LoginScreen after showing confirmation
      await tester.pumpAndSettle(); // Let navigation complete if any
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Should navigate back to LoginScreen after reset request');
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });

    testWidgets('Navigation between Login, Signup, and Forgot Password screens works', (WidgetTester tester) async {
      // Arrange: Start app - NO
      // app.main(); // REMOVE
      await tester.pumpAndSettle(); // Ensure initial state is rendered
      expect(find.byType(LoginScreen), findsOneWidget);

      // --- Test Login -> Signup -> Login ---
      // Act: Tap Signup link
      final signupLinkFromLogin = find.widgetWithText(TextButton, 'Sign Up');
      expect(signupLinkFromLogin, findsOneWidget);
      await tester.tap(signupLinkFromLogin);
      await tester.pumpAndSettle();

      // Assert: On Signup screen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Act: Tap Login link
      final loginLinkFromSignup = find.widgetWithText(TextButton, 'Login'); // Assuming text is 'Login'
      expect(loginLinkFromSignup, findsOneWidget);
      await tester.tap(loginLinkFromSignup);
      await tester.pumpAndSettle();

      // Assert: Back on Login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SignupScreen), findsNothing);

      // --- Test Login -> Forgot Password -> Login ---
      // Act: Tap Forgot Password link
      final forgotLinkFromLogin = find.widgetWithText(TextButton, 'Forgot Password?');
      expect(forgotLinkFromLogin, findsOneWidget);
      await tester.tap(forgotLinkFromLogin);
      await tester.pumpAndSettle();

      // Assert: On Forgot Password screen
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Act: Tap Back to Login button
      // Assuming it's an IconButton with a back arrow in the AppBar
      // Or potentially a TextButton, adjust finder as needed.
      final backButtonFromForgot = find.descendant(
        of: find.byType(AppBar), // Assuming AppBar exists on ForgotPasswordScreen
        matching: find.byTooltip('Back') // Standard back button tooltip
      );
      // Fallback if no AppBar or tooltip:
      // final backButtonFromForgot = find.widgetWithText(TextButton, 'Back to Login'); 
      expect(backButtonFromForgot, findsOneWidget);
      await tester.tap(backButtonFromForgot);
      await tester.pumpAndSettle();

      // Assert: Back on Login screen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ForgotPasswordScreen), findsNothing);
    });

    // TODO: Add tests for:
    // - Session Persistence (needs app restart capabilities)

  });
} 