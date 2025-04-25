// Import for Completer
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/providers/auth_status.dart';
import 'package:samabus/screens/auth/forgot_password_screen.dart';
import 'package:samabus/screens/auth/login_screen.dart'; // For back navigation testing
import 'package:samabus/widgets/loading_overlay.dart'; // Import LoadingOverlay

// Generate mocks
@GenerateMocks([AuthProvider, GoRouter])
import 'forgot_password_screen_test.mocks.dart';

// Helper to create the widget tree
Widget createForgotPasswordScreen({required MockAuthProvider mockAuthProvider}) {
  final goRouter = GoRouter(
    initialLocation: ForgotPasswordScreen.routeName,
    routes: [
      GoRoute(
        path: ForgotPasswordScreen.routeName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName, // Need login route for back navigation
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
    // Default stub for sendPasswordResetEmail call
    when(mockAuthProvider.sendPasswordResetEmail(email: anyNamed('email')))
        .thenAnswer((_) async => true); // Default to success
  });

  testWidgets('Renders email field, instructions, and buttons initially', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));

    // Assert
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.textContaining('Enter your email address below'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Back to Login'), findsOneWidget);
    expect(find.textContaining('Password reset link sent successfully'), findsNothing);
  });

  testWidgets('Shows validation error for empty email', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));

    // Act
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pump();

    // Assert
    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('Shows validation error for invalid email format', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'invalid-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pump();

    // Assert
    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('Calls authProvider.sendPasswordResetEmail on valid submission', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));
    const testEmail = 'test@example.com';

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Email'), testEmail);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pump(); // Allow time for async call and state update

    // Assert
    verify(mockAuthProvider.sendPasswordResetEmail(email: testEmail)).called(1);
  });

  testWidgets('Shows success message and hides form on successful submission', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));
    const testEmail = 'success@example.com';
    // Mock returns true by default in setUp

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Email'), testEmail);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pumpAndSettle(); // Allow state update and rebuild

    // Assert
    expect(find.textContaining('Password reset link sent successfully to $testEmail'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Back to Login'), findsOneWidget); // Back button should still be there
  });

  testWidgets('Shows error message when status is error', (WidgetTester tester) async {
    // Arrange
    const errorMessage = 'User not found';
    when(mockAuthProvider.sendPasswordResetEmail(email: anyNamed('email')))
        .thenAnswer((_) async => false); // Mock failure
    when(mockAuthProvider.status).thenReturn(AuthStatus.error);
    when(mockAuthProvider.errorMessage).thenReturn(errorMessage);

    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));

    // Act
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'error@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pump(); // Allow state update

    // Assert
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget); // Form should still be visible
    expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);
  });

  testWidgets('Shows loading state while sending reset link', (WidgetTester tester) async {
    // Arrange
    // Simulate the loading state directly via the provider status
    when(mockAuthProvider.status).thenReturn(AuthStatus.authenticating);
    // No need to mock sendPasswordResetEmail future for this state test

    await tester.pumpWidget(createForgotPasswordScreen(mockAuthProvider: mockAuthProvider));

    // Assert: Check for LoadingOverlay and disabled button
    // Find the LoadingOverlay widget
    final loadingOverlayFinder = find.byType(LoadingOverlay); // Assuming LoadingOverlay is imported or known
    expect(loadingOverlayFinder, findsOneWidget);
    
    // Check if the overlay is active (isLoading is true)
    final loadingOverlay = tester.widget<LoadingOverlay>(loadingOverlayFinder);
    expect(loadingOverlay.isLoading, isTrue); 

    // Check if the button is disabled
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Send Reset Link');
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);
  });

  // TODO: Test 'Back to Login' navigation (requires better GoRouter mocking or integration test)

} 