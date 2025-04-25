import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add localization delegates
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:samabus/config/app_config.dart'; // Needed for Supabase init
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/providers/auth_status.dart';
import 'package:samabus/screens/auth/login_screen.dart';
import 'package:samabus/screens/auth/signup_screen.dart';
import 'package:samabus/screens/traveler/traveler_home_screen.dart';
import 'package:samabus/screens/transporteur/transporteur_home_screen.dart';
import 'package:samabus/screens/auth/forgot_password_screen.dart';
import 'package:samabus/screens/splash_screen.dart';
// import 'package:samabus/services/auth_service.dart'; // Don't import implementation
import 'package:samabus/routes/app_router.dart';    // Import router
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'dart:async'; // Import async for StreamController
import 'package:mockito/mockito.dart'; // <-- Added Import
import 'package:samabus/models/user.dart' as app_user; // <-- Added Import

// Import the generated mocks
import '../test/unit/providers/auth_provider_test.mocks.dart'; // Adjust path if needed

// Helper function to set up the app within a test
// Returns the MockAuthService for test-specific stubbing
Future<MockAuthService> setupAppForTest(WidgetTester tester) async {
  // Ensure Supabase is initialized (needed for internal Supabase checks perhaps)
  try {
     print("Test Setup: Initializing Supabase...");
     await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
     print("Test Setup: Supabase Initialized.");
  } catch (e) {
     print("Test Setup: Supabase already initialized or error: $e");
  }

  // --- Use Mock AuthService --- 
  final mockAuthService = MockAuthService();

  // Stub the mandatory onAuthStateChange stream
  // Use a local controller FOR THE SETUP, tests might need their own or reuse this
  final authStateController = StreamController<AuthState>.broadcast(); 
  when(mockAuthService.onAuthStateChange).thenAnswer((_) => authStateController.stream);
  // Default stub for profile fetch (return null initially)
  when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null);

  // --- Create Providers with Mock --- 
  final authProvider = AuthProvider(mockAuthService, skipInitialCheck: true);
  final router = AppRouter.createRouter(authProvider);
  print("Test Setup: Providers (with MockAuthService) and Router created.");

  // Pump the root widget with necessary providers
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        // Add other necessary providers here if the test interacts with them
      ],
      child: MaterialApp.router(
        // Pass the router configuration
        routerConfig: router,
        // Add localizations delegates necessary for Material widgets
         localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('fr', ''), // French
          ],
      ),
    ),
  );

  // Allow time for the initial frame and potential redirects
  print("Test Setup: Pumping initial frame...");
  await tester.pump(); // Pump the first frame
  await tester.pump(const Duration(seconds: 1)); // Wait a fixed short duration
  // Log status right after pump
  try {
    final currentStatus = tester.element(find.byType(MaterialApp)).read<AuthProvider>().status;
    print("Test Setup: Pump finished. Current status: $currentStatus");
  } catch (e) {
    print("Test Setup: Could not get AuthProvider status after pump: $e");
  }

  // Return the mock service instance so tests can stub its methods
  return mockAuthService;
}


void main() {
  // Initialize binding FIRST
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Prevent test timeouts for longer integration tests involving network calls
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // NOTE: Supabase initialization is now inside setupAppForTest
  // If Supabase init is slow, consider `setUpAll` but be careful with state resets.

  group('Authentication Flow Tests', () {

    testWidgets('Initial app state navigates to LoginScreen', (WidgetTester tester) async {
      print("Test: Initial app state navigates to LoginScreen");
      await setupAppForTest(tester); // Use the helper

      // Log status right before assertion in the test
      final authProvider = tester.element(find.byType(MaterialApp)).read<AuthProvider>();
      print("Test: Status before assertion: ${authProvider.status}");

      // Assert: Should land directly on LoginScreen because initial status is unauthenticated
      print("Test: Verifying LoginScreen is present.");
      debugDumpApp(); // Dump tree for verification
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Expected to land on LoginScreen initially');
      // expect(find.text('Minimal Test Widget'), findsOneWidget, reason: 'Expected minimal widget text'); // Reverted
      expect(find.byType(SplashScreen), findsNothing, reason: 'SplashScreen should not be visible after initial redirect');
      print("Test: Initial navigation to LoginScreen verified.");
    });

    // Removed 'Check if MaterialApp renders initially' as setupAppForTest covers this

    testWidgets('Navigates to SignupScreen and attempts Traveler signup', (WidgetTester tester) async {
      print("Test: Navigates to SignupScreen and attempts Traveler signup");
      final mockAuthService = await setupAppForTest(tester); // Use the helper

      // Arrange: Verify on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      print("Test: Tapping 'Sign Up' link...");
      final signupLinkFinder = find.widgetWithText(TextButton, 'Sign Up');
      expect(signupLinkFinder, findsOneWidget);
      await tester.tap(signupLinkFinder);
      await tester.pumpAndSettle();
      print("Test: Navigated to SignupScreen.");

      // Assert: Verify on Signup Screen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Arrange: Generate unique credentials & Prepare Mock Responses
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'traveler_$timestamp@test.com';
      const password = 'password123';
      final mockAppUser = app_user.User(id: 'new-user-id', role: app_user.UserRole.traveler, createdAt: DateTime.now(), isVerified: true, fullName: 'Test Traveler $timestamp', phoneNumber: '100${timestamp % 10000000}');
      final mockSupabaseUser = MockUser();
      when(mockSupabaseUser.id).thenReturn('new-user-id');
      final mockAuthResponse = MockAuthResponse();
      when(mockAuthResponse.user).thenReturn(mockSupabaseUser);
      // Simulate successful signup (returns AuthResponse)
      when(mockAuthService.signUp(email: uniqueEmail, password: password, data: anyNamed('data')))
          .thenAnswer((_) async => mockAuthResponse);
      // Simulate successful profile fetch AFTER signup event
      when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockAppUser);

      print("Test: Using email $uniqueEmail");

      // Act: Fill form and submit
      print("Test: Filling signup form...");
      await tester.enterText(find.byKey(const Key('signup_fullname')), 'Test Traveler $timestamp');
      await tester.enterText(find.byKey(const Key('signup_email')), uniqueEmail);
      await tester.enterText(find.byKey(const Key('signup_phone')), '100${timestamp % 10000000}');
      await tester.enterText(find.byKey(const Key('signup_password')), password);
      await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);

      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(signupButtonFinder, findsOneWidget);
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();

      // Act: Tap signup button - this will trigger the mocked signUp call
      await tester.tap(signupButtonFinder);

      // Act: Manually trigger the auth state change AFTER the signup call completes
      // (Need access to the controller or a way to trigger externally)
      // For now, let's rely on pumpAndSettle and the mocked getCurrentUserAppModel
      // TODO: Refine state change simulation if needed

      // Wait for signup process and potential navigation
      print("Test: Waiting for signup process (pumpAndSettle)...");
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Reduced wait time as it's mocked

      // Assert: Check final state
      print("Test: Checking navigation after signup...");
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Expected Traveler Home Screen after successful mocked signup');
      expect(find.byType(SignupScreen), findsNothing);
      print("Test: Traveler signup navigation verified.");
    });

    testWidgets('Navigates to SignupScreen and attempts Transporteur signup (lands on Pending)', (WidgetTester tester) async {
       print("Test: Navigates to SignupScreen and attempts Transporteur signup");
       final mockAuthService = await setupAppForTest(tester);

      // Arrange: Verify on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // Act: Navigate to Signup Screen
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Arrange: Generate unique credentials & Mock Responses
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'transporteur_$timestamp@test.com';
      final companyName = 'Bus Company $timestamp';
      const password = 'password123';
      final mockAppUser = app_user.User(
          id: 'transporteur-id', 
          role: app_user.UserRole.transporteur, 
          createdAt: DateTime.now(), 
          isVerified: true, 
          fullName: 'Test Transporter $timestamp', 
          phoneNumber: '200${timestamp % 10000000}',
          companyName: companyName,
          isApproved: false // Key difference: transporteur is not approved
      );
      final mockSupabaseUser = MockUser();
      when(mockSupabaseUser.id).thenReturn('transporteur-id');
      final mockAuthResponse = MockAuthResponse();
      when(mockAuthResponse.user).thenReturn(mockSupabaseUser);

      // Stub signUp success
      when(mockAuthService.signUp(email: uniqueEmail, password: password, data: anyNamed('data')))
          .thenAnswer((_) async => mockAuthResponse);
      // Stub profile fetch to return the *pending* transporteur user
      when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockAppUser);

      print("Test: Using email $uniqueEmail for Transporteur");

      // Act: Select Transporteur role
       print("Test: Selecting Transporteur role...");
       await tester.tap(find.text('Transporteur'));
      await tester.pumpAndSettle(); // Wait for Company Name field to appear
       print("Test: Transporteur role selected.");

      // Act: Fill form and submit
       print("Test: Filling transporteur signup form...");
      await tester.enterText(find.byKey(const Key('signup_fullname')), 'Test Transporter $timestamp');
      expect(find.byKey(const Key('signup_company_name')), findsOneWidget, reason: 'Company Name field should be visible');
      await tester.enterText(find.byKey(const Key('signup_company_name')), companyName);
      await tester.enterText(find.byKey(const Key('signup_email')), uniqueEmail);
      await tester.enterText(find.byKey(const Key('signup_phone')), '200${timestamp % 10000000}');
      await tester.enterText(find.byKey(const Key('signup_password')), password);
      await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);

      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      expect(signupButtonFinder, findsOneWidget);
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
       print("Test: Tapping signup button...");
      // Act: Tap signup - triggers mocked calls
      await tester.tap(signupButtonFinder);

      // Wait for signup process and navigation (mocked, so faster)
       print("Test: Waiting for signup process (pumpAndSettle)...");
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Assert: Should navigate to TransporteurHomeScreen and show pending state
       print("Test: Checking navigation after transporteur signup...");
      expect(find.byType(TransporteurHomeScreen), findsOneWidget, reason: 'Expected Transporteur Home Screen after mocked signup');
      expect(find.byType(SignupScreen), findsNothing);
       print("Test: Checking for pending approval state...");
      expect(find.textContaining('Account Pending Approval', findRichText: true), findsOneWidget, reason: 'Expected Pending Approval text');
      print("Test: Transporteur pending state verified.");
    });

    testWidgets('Signs up, logs out, and logs back in as Traveler', (WidgetTester tester) async {
       print("Test: Signs up, logs out, and logs back in as Traveler");
       // Get mock service
       final mockAuthService = await setupAppForTest(tester);

      // Arrange: Verify on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Test setup failed: Not on LoginScreen initially');

      // --- Part 1: Sign Up ---
       print("Test: Navigating to signup...");
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueEmail = 'traveler_relogin_$timestamp@test.com';
      const password = 'password123';
      // Prepare Mock Responses for Signup
      final mockSignupAppUser = app_user.User(id: 'relogin-user-id', role: app_user.UserRole.traveler, createdAt: DateTime.now(), isVerified: true, fullName: 'Relogin Test Traveler $timestamp', phoneNumber: '300${timestamp % 10000000}');
      final mockSignupSupabaseUser = MockUser();
      when(mockSignupSupabaseUser.id).thenReturn('relogin-user-id');
      final mockSignupResponse = MockAuthResponse();
      when(mockSignupResponse.user).thenReturn(mockSignupSupabaseUser);
      // Stub signup success
      when(mockAuthService.signUp(email: uniqueEmail, password: password, data: anyNamed('data')))
          .thenAnswer((_) async => mockSignupResponse);
      // Stub profile fetch after signup
      when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockSignupAppUser);

       print("Test: Signing up as $uniqueEmail");

      await tester.enterText(find.byKey(const Key('signup_fullname')), 'Relogin Test Traveler $timestamp');
      await tester.enterText(find.byKey(const Key('signup_email')), uniqueEmail);
      await tester.enterText(find.byKey(const Key('signup_phone')), '300${timestamp % 10000000}');
      await tester.enterText(find.byKey(const Key('signup_password')), password);
      await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);

      final signupButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Up');
      await tester.ensureVisible(signupButtonFinder);
      await tester.pumpAndSettle();
      // Act: Tap signup
      await tester.tap(signupButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Mocked, faster

      // Assert: Should be on TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Signup failed or navigated incorrectly');
       print("Test: Signup successful, on Traveler Home.");

      // --- Part 2: Log Out ---
       print("Test: Logging out...");
       // Stub signOut success
       when(mockAuthService.signOut()).thenAnswer((_) async {});
       // Stub profile fetch after logout (should return null)
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null);

      final logoutButtonFinder = find.byKey(const Key('logout_button'));
      expect(logoutButtonFinder, findsOneWidget, reason: 'Logout button (Key: logout_button) not found');
      // Act: Tap logout
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Mocked, faster

      // Assert: Should be back on LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Logout did not return to Login Screen');
      expect(find.byType(TravelerHomeScreen), findsNothing);
       print("Test: Logout successful, back on Login screen.");

      // --- Part 3: Log In ---
       print("Test: Logging back in...");
       // Prepare Mock Responses for Login
       final mockLoginSupabaseUser = MockUser(); // Potentially same user as signup
       when(mockLoginSupabaseUser.id).thenReturn('relogin-user-id');
       final mockLoginResponse = MockAuthResponse();
       when(mockLoginResponse.user).thenReturn(mockLoginSupabaseUser);
       // Stub login success
       when(mockAuthService.signInWithPassword(email: uniqueEmail, password: password))
           .thenAnswer((_) async => mockLoginResponse);
       // Stub profile fetch after login (same user)
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockSignupAppUser);

      await tester.enterText(find.byKey(const Key('login_email')), uniqueEmail); 
      await tester.enterText(find.byKey(const Key('login_password')), password);

      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginButtonFinder, findsOneWidget);
      await tester.ensureVisible(loginButtonFinder);
      await tester.pumpAndSettle();
      // Act: Tap login
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Mocked, faster

      // Assert: Should be back on TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Login failed or navigated incorrectly');
      expect(find.byType(LoginScreen), findsNothing);
       print("Test: Login successful, back on Traveler Home.");
    });

    // Add Keys to TextFields (e.g., Key('login_email'), Key('login_password')) in LoginScreen
    // Add Key to Sign Up button
    // Add Key to Forgot Password link

    testWidgets('Login fails with incorrect password', (WidgetTester tester) async {
      print("Test: Login fails with incorrect password");
       // Get mock service
       final mockAuthService = await setupAppForTest(tester);

      // --- Part 1: Sign Up a user first (and logout) ---
       print("Test: Setting up user for failed login test...");
       await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
       await tester.pumpAndSettle();
       final timestamp = DateTime.now().millisecondsSinceEpoch;
       final uniqueEmail = 'fail_login_$timestamp@test.com';
       const correctPassword = 'password123';

       // Prepare Mock Responses for Signup
       final mockSignupAppUser = app_user.User(id: 'fail-login-user-id', role: app_user.UserRole.traveler, createdAt: DateTime.now(), isVerified: true, fullName: 'Fail Login User', phoneNumber: '400${timestamp % 10000000}');
       final mockSignupSupabaseUser = MockUser();
       when(mockSignupSupabaseUser.id).thenReturn('fail-login-user-id');
       final mockSignupResponse = MockAuthResponse();
       when(mockSignupResponse.user).thenReturn(mockSignupSupabaseUser);
       // Stub signup success
       when(mockAuthService.signUp(email: uniqueEmail, password: correctPassword, data: anyNamed('data')))
           .thenAnswer((_) async => mockSignupResponse);
       // Stub profile fetch after signup
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockSignupAppUser);

       await tester.enterText(find.byKey(const Key('signup_fullname')), 'Fail Login User');
       await tester.enterText(find.byKey(const Key('signup_email')), uniqueEmail);
       await tester.enterText(find.byKey(const Key('signup_phone')), '400${timestamp % 10000000}');
       await tester.enterText(find.byKey(const Key('signup_password')), correctPassword);
       await tester.enterText(find.byKey(const Key('signup_confirm_password')), correctPassword);
       // Act: Tap signup
       await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
       await tester.pumpAndSettle(const Duration(seconds: 5)); // Mocked
       expect(find.byType(TravelerHomeScreen), findsOneWidget); // Assume signup worked

       // Stub logout
       when(mockAuthService.signOut()).thenAnswer((_) async {});
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null); // Profile is null after logout
       // Act: Tap logout
       await tester.tap(find.byKey(const Key('logout_button'))); 
       await tester.pumpAndSettle(const Duration(seconds: 2)); // Mocked
       expect(find.byType(LoginScreen), findsOneWidget); // Back on login
       print("Test: User setup complete.");

      // --- Part 2: Attempt Login with wrong password ---
       print("Test: Attempting login with incorrect password...");
       // Stub signIn failure
       const exceptionMessage = 'Invalid login credentials';
       when(mockAuthService.signInWithPassword(email: uniqueEmail, password: 'wrongpassword'))
           .thenThrow(const AuthException(exceptionMessage));
       // getCurrentUserAppModel should still return null as login fails
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null);

      await tester.enterText(find.byKey(const Key('login_email')), uniqueEmail);
      await tester.enterText(find.byKey(const Key('login_password')), 'wrongpassword');

      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      // Act: Tap login
      await tester.tap(loginButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Mocked, wait for error handling

      // Assert: Still on LoginScreen and error message is shown via SnackBar
      expect(find.byType(LoginScreen), findsOneWidget, reason: 'Should remain on Login Screen after failed login');
      // Check for SnackBar (ensure LoginScreen shows SnackBars on error)
      expect(find.widgetWithText(SnackBar, exceptionMessage), findsOneWidget, reason: 'SnackBar with error message \'$exceptionMessage\' not found');
      // Check AuthProvider status
      final authProvider = tester.element(find.byType(MaterialApp)).read<AuthProvider>();
      expect(authProvider.status, AuthStatus.error, reason: 'AuthProvider status should be error after failed login');
      expect(authProvider.errorMessage, exceptionMessage, reason: 'AuthProvider error message should be set');
       print("Test: Failed login verified.");
    });

     testWidgets('Signup fails if email already exists', (WidgetTester tester) async {
        print("Test: Signup fails if email already exists");
        // Get mock service
        final mockAuthService = await setupAppForTest(tester);

       // --- Part 1: Sign up a user ---
        print("Test: Signing up initial user...");
       final timestamp = DateTime.now().millisecondsSinceEpoch;
       final existingEmail = 'duplicate_$timestamp@test.com';
       const password = 'password123';

       // Prepare Mocks for Initial Signup
       final mockInitialAppUser = app_user.User(id: 'initial-user-id', role: app_user.UserRole.traveler, createdAt: DateTime.now(), isVerified: true, fullName: 'Duplicate User 1', phoneNumber: '500${timestamp % 10000000}');
       final mockInitialSupabaseUser = MockUser();
       when(mockInitialSupabaseUser.id).thenReturn('initial-user-id');
       final mockInitialSignupResponse = MockAuthResponse();
       when(mockInitialSignupResponse.user).thenReturn(mockInitialSupabaseUser);
       // Stub initial signup success
       when(mockAuthService.signUp(email: existingEmail, password: password, data: anyNamed('data')))
           .thenAnswer((_) async => mockInitialSignupResponse);
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockInitialAppUser);

       await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
       await tester.pumpAndSettle();
       await tester.enterText(find.byKey(const Key('signup_fullname')), 'Duplicate User 1');
       await tester.enterText(find.byKey(const Key('signup_email')), existingEmail);
       await tester.enterText(find.byKey(const Key('signup_phone')), '500${timestamp % 10000000}');
       await tester.enterText(find.byKey(const Key('signup_password')), password);
       await tester.enterText(find.byKey(const Key('signup_confirm_password')), password);
       // Act: Tap signup
       await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
       await tester.pumpAndSettle(const Duration(seconds: 5)); // Mocked
       expect(find.byType(TravelerHomeScreen), findsOneWidget); // Assume signup worked

       // Stub logout
       when(mockAuthService.signOut()).thenAnswer((_) async {});
       when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null);
       // Act: Tap logout
       await tester.tap(find.byKey(const Key('logout_button')));
       await tester.pumpAndSettle(const Duration(seconds: 2)); // Mocked
       expect(find.byType(LoginScreen), findsOneWidget);
        print("Test: Initial user signed up and logged out.");

       // --- Part 2: Attempt signup with the SAME email ---
        print("Test: Attempting signup with duplicate email...");
        // Stub duplicate signup failure
        const exceptionMessage = 'User already registered';
        when(mockAuthService.signUp(email: existingEmail, password: 'otherpassword', data: anyNamed('data')))
            .thenThrow(const AuthException(exceptionMessage));
        // getCurrentUserAppModel should still return null
        when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => null);

       await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
       await tester.pumpAndSettle();
       await tester.enterText(find.byKey(const Key('signup_fullname')), 'Duplicate User 2');
       await tester.enterText(find.byKey(const Key('signup_email')), existingEmail); // Use same email
       await tester.enterText(find.byKey(const Key('signup_phone')), '501${timestamp % 10000000}');
       await tester.enterText(find.byKey(const Key('signup_password')), 'otherpassword');
       await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'otherpassword');

       // Act: Tap signup
       await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
       await tester.pumpAndSettle(const Duration(seconds: 2)); // Mocked, wait for error

       // Assert: Still on SignupScreen and error message shown 
       expect(find.byType(SignupScreen), findsOneWidget, reason: 'Should remain on Signup Screen after duplicate email signup attempt');
       // Check for error message (assuming SignupScreen displays errors directly or via SnackBar)
       // Option 1: Check for SnackBar (if implemented this way)
       // expect(find.widgetWithText(SnackBar, exceptionMessage), findsOneWidget, reason: 'SnackBar with error message "$exceptionMessage" not found');
       // Option 2: Check for error Text within the form (if implemented this way)
       expect(find.textContaining(exceptionMessage, findRichText: true), findsOneWidget, reason: 'Error message text "$exceptionMessage" not found on Signup Screen');
       // Check AuthProvider status
       final authProvider = tester.element(find.byType(MaterialApp)).read<AuthProvider>();
       expect(authProvider.status, AuthStatus.error, reason: 'AuthProvider status should be error after duplicate signup');
       expect(authProvider.errorMessage, exceptionMessage, reason: 'AuthProvider error message should be set');
        print("Test: Duplicate email signup failure verified.");
     });

    // Note: Transporteur login requires admin approval state, hard to test fully here without mocking/setup
    // testWidgets('Signs up, logs out, and logs back in as Transporteur (lands on Pending)', ...);

    testWidgets('Logout from Traveler Home Screen navigates to Login Screen', (WidgetTester tester) async {
       print("Test: Logout from Traveler Home Screen");
       await setupAppForTest(tester);

      // --- Sign Up and reach Home Screen ---
       print("Test: Signing up user for logout test...");
       await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
       await tester.pumpAndSettle();
       final timestamp = DateTime.now().millisecondsSinceEpoch;
       final uniqueEmail = 'logout_test_$timestamp@test.com';
       await tester.enterText(find.byKey(const Key('signup_fullname')), 'Logout User');
       await tester.enterText(find.byKey(const Key('signup_email')), uniqueEmail);
       await tester.enterText(find.byKey(const Key('signup_phone')), '600${timestamp % 10000000}');
       await tester.enterText(find.byKey(const Key('signup_password')), 'password123');
       await tester.enterText(find.byKey(const Key('signup_confirm_password')), 'password123');
       await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
       await tester.pumpAndSettle(const Duration(seconds: 10));
       expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Did not reach home screen after signup');
       print("Test: On Traveler Home Screen.");

      // --- Log Out ---
       print("Test: Tapping logout button...");
       await tester.tap(find.byKey(const Key('logout_button')));
       await tester.pumpAndSettle(const Duration(seconds: 5));

       // --- Assert ---
       expect(find.byType(LoginScreen), findsOneWidget, reason: 'Did not return to Login Screen after logout');
       expect(find.byType(TravelerHomeScreen), findsNothing, reason: 'Traveler Home Screen should not be visible after logout');
       print("Test: Logout navigation verified.");
    });

    testWidgets('Password Reset Flow shows confirmation message', (WidgetTester tester) async {
       print("Test: Password Reset Flow");
       await setupAppForTest(tester);

       // Arrange: Verify on LoginScreen
       expect(find.byType(LoginScreen), findsOneWidget, reason: 'Not on LoginScreen initially');

       // Act: Navigate to Forgot Password Screen
       print("Test: Navigating to Forgot Password screen...");
       // Assuming a TextButton with 'Forgot Password?' text exists
       final forgotPasswordLinkFinder = find.widgetWithText(TextButton, 'Forgot Password?');
       expect(forgotPasswordLinkFinder, findsOneWidget, reason: 'Forgot Password link not found');
       await tester.tap(forgotPasswordLinkFinder);
       await tester.pumpAndSettle();

       // Assert: Verify on Forgot Password Screen
       expect(find.byType(ForgotPasswordScreen), findsOneWidget, reason: 'Did not navigate to Forgot Password Screen');
       expect(find.byType(LoginScreen), findsNothing);
       print("Test: On Forgot Password screen.");

       // Act: Enter email and submit
       final timestamp = DateTime.now().millisecondsSinceEpoch;
       final uniqueEmail = 'reset_test_$timestamp@test.com';
        print("Test: Entering email $uniqueEmail and submitting...");
        // Assuming Key('forgot_password_email') exists on the TextField
       await tester.enterText(find.byKey(const Key('forgot_password_email')), uniqueEmail);
       // Assuming Key('reset_password_button') exists
       final resetButtonFinder = find.byKey(const Key('reset_password_button'));
       expect(resetButtonFinder, findsOneWidget, reason: 'Reset Password button not found');
       await tester.tap(resetButtonFinder);
       await tester.pumpAndSettle(const Duration(seconds: 5)); // Wait for network call

       // Assert: Should remain on ForgotPasswordScreen and show confirmation
       expect(find.byType(ForgotPasswordScreen), findsOneWidget, reason: 'Should stay on Forgot Password screen');
       // Look for confirmation text - use Key if possible
       expect(find.textContaining('Password reset email sent', findRichText: true), findsOneWidget, reason: 'Confirmation message not found');
       // Check AuthProvider status - should remain unauthenticated
        final authProvider = tester.element(find.byType(MaterialApp)).read<AuthProvider>();
       expect(authProvider.status, AuthStatus.unauthenticated, reason: 'Status should remain unauthenticated after password reset request');
        print("Test: Password reset confirmation verified.");
    });

     testWidgets('Navigation between Login, Signup, and Forgot Password screens works', (WidgetTester tester) async {
        print("Test: Navigation between Login, Signup, and Forgot Password");
        await setupAppForTest(tester);

        // Arrange: Verify on LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);

        // --- Go to Signup ---
        print("Test: Login -> Signup");
        await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
        await tester.pumpAndSettle();
        expect(find.byType(SignupScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // --- Go back to Login (from Signup AppBar) ---
        print("Test: Signup -> Login (AppBar back)");
        // Find the back button in the AppBar
        await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.arrow_back)));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SignupScreen), findsNothing);

         // --- Go to Signup again ---
         print("Test: Login -> Signup (Again)");
         await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
         await tester.pumpAndSettle();
         expect(find.byType(SignupScreen), findsOneWidget);

        // --- Go back to Login (from Signup TextButton) ---
         print("Test: Signup -> Login (TextButton back)");
         await tester.tap(find.descendant(of: find.byType(Row), matching: find.widgetWithText(TextButton, 'Login')));
         await tester.pumpAndSettle();
         expect(find.byType(LoginScreen), findsOneWidget);

        // --- Go to Forgot Password ---
         print("Test: Login -> Forgot Password");
        await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
        await tester.pumpAndSettle();
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // --- Go back to Login (from ForgotPassword AppBar) ---
         print("Test: Forgot Password -> Login (AppBar back)");
        await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.arrow_back)));
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(ForgotPasswordScreen), findsNothing);
         print("Test: Auth screen navigation verified.");
     });

    testWidgets('Login succeeds with correct credentials', (WidgetTester tester) async {
      print("Test: Login succeeds with correct credentials");
      // Get mock service
      final mockAuthService = await setupAppForTest(tester);

      // Prepare Mocks
      const testEmail = 'success@test.com';
      const testPassword = 'correctpassword';

      final mockSupabaseUser = MockUser();
      when(mockSupabaseUser.id).thenReturn('user-success-id');
      when(mockSupabaseUser.email).thenReturn(testEmail);

      final mockAuthResponse = MockAuthResponse();
      when(mockAuthResponse.user).thenReturn(mockSupabaseUser);

      final mockAppUser = app_user.User(
        id: 'user-success-id',
        role: app_user.UserRole.traveler,
        createdAt: DateTime.now(),
        isVerified: true,
        fullName: 'Success User',
      );

      // Stub successful login
      when(mockAuthService.signInWithPassword(email: testEmail, password: testPassword))
          .thenAnswer((_) async => mockAuthResponse);
      // Stub getting the user model after login
      when(mockAuthService.getCurrentUserAppModel()).thenAnswer((_) async => mockAppUser);

      // Act: Enter credentials and tap login
      await tester.enterText(find.byKey(const Key('login_email')), testEmail);
      await tester.enterText(find.byKey(const Key('login_password')), testPassword);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Mocked, allow time for navigation

      // Assert: Navigated to TravelerHomeScreen
      expect(find.byType(TravelerHomeScreen), findsOneWidget, reason: 'Should navigate to TravelerHomeScreen after successful login');
      expect(find.byType(LoginScreen), findsNothing, reason: 'LoginScreen should no longer be visible');

      // Assert: AuthProvider state is updated
      final authProvider = tester.element(find.byType(MaterialApp)).read<AuthProvider>();
      expect(authProvider.status, AuthStatus.authenticated, reason: 'AuthProvider status should be authenticated');
      expect(authProvider.user, isNotNull, reason: 'AuthProvider user should not be null');
      expect(authProvider.user?.id, mockAppUser.id, reason: 'AuthProvider user ID should match logged in user');
      expect(authProvider.user?.role, app_user.UserRole.traveler, reason: 'AuthProvider user role should be traveler');
      expect(authProvider.errorMessage, isNull, reason: 'AuthProvider error message should be null');
      print("Test: Successful login verified.");
    });

  });
} 