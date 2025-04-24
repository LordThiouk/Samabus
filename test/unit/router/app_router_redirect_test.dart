import 'package:flutter/material.dart'; // Needed for BuildContext
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:samabus/models/user.dart' as app_user;
import 'package:samabus/providers/auth_provider.dart';
import 'package:samabus/providers/auth_status.dart';
import 'package:samabus/routes/app_router.dart'; // Import the class containing the static method
import 'package:samabus/screens/auth/login_screen.dart';

// Generate Mocks
@GenerateMocks([AuthProvider, GoRouterState])
import 'app_router_redirect_test.mocks.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized(); 

  late MockAuthProvider mockAuthProvider;
  late MockGoRouterState mockGoRouterState;
  // Use BuildContext from a dummy widget for testing purposes
  final BuildContext mockContext = GlobalKey().currentContext ?? // Simplified context access
      Builder(builder: (context) => Container()).createElement(); 

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockGoRouterState = MockGoRouterState();

    // Default stubs
    when(mockAuthProvider.status).thenReturn(AuthStatus.uninitialized);
    when(mockAuthProvider.user).thenReturn(null);
    when(mockAuthProvider.errorMessage).thenReturn(null);
    when(mockGoRouterState.matchedLocation).thenReturn('/'); // Default to splash
    when(mockAuthProvider.signOut()).thenAnswer((_) async {}); // Stub signOut
  });

  // Updated helper function to call the extracted logic
  String? testRedirectLogic({
    required AuthStatus status,
    app_user.User? user,
    String? currentLocation,
  }) {
    when(mockAuthProvider.status).thenReturn(status);
    when(mockAuthProvider.user).thenReturn(user);
    when(mockGoRouterState.matchedLocation).thenReturn(currentLocation ?? '/');

    // Directly call the extracted redirect logic function
    return appRedirectLogic(mockContext, mockGoRouterState, mockAuthProvider);
  }

  group('AppRouter Redirect Logic', () {
    
    test('stays on current page if status is uninitialized', () {
      final redirectPath = testRedirectLogic(
        status: AuthStatus.uninitialized,
        currentLocation: '/',
      );
      expect(redirectPath, isNull); // Should stay
    });

    test('stays on current page if status is authenticating', () {
      final redirectPath = testRedirectLogic(
        status: AuthStatus.authenticating,
        currentLocation: '/',
      );
      expect(redirectPath, isNull); // Should stay
    });

    test('stays on current page if status is loadingProfile', () {
      final redirectPath = testRedirectLogic(
        status: AuthStatus.loadingProfile,
        currentLocation: '/',
      );
      expect(redirectPath, isNull); // Should stay
    });

    group('Authenticated User', () {
      final travelerUser = app_user.User(id: '1', role: app_user.UserRole.traveler, createdAt: DateTime.now(), isVerified: true);
      final transporteurUser = app_user.User(id: '2', role: app_user.UserRole.transporteur, createdAt: DateTime.now(), isVerified: true);
      final adminUser = app_user.User(id: '3', role: app_user.UserRole.admin, createdAt: DateTime.now(), isVerified: true);

      test('redirects Traveler from / to /traveler', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: travelerUser,
          currentLocation: '/',
        );
        expect(redirectPath, '/traveler');
      });

      test('redirects Transporteur from /login to /transporteur', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: transporteurUser,
          currentLocation: LoginScreen.routeName, // e.g., '/login'
        );
        expect(redirectPath, '/transporteur');
      });
      
      test('redirects Admin from /signup to /admin', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: adminUser,
          currentLocation: '/signup', // Example auth route
        );
        expect(redirectPath, '/admin');
      });

      test('stays on /traveler if already there (Traveler)', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: travelerUser,
          currentLocation: '/traveler',
        );
        expect(redirectPath, isNull);
      });
       
      test('stays on /transporteur if already there (Transporteur)', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: transporteurUser,
          currentLocation: '/transporteur',
        );
        expect(redirectPath, isNull);
      });

      test('stays on /admin if already there (Admin)', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: adminUser,
          currentLocation: '/admin',
        );
        expect(redirectPath, isNull);
      });

      test('redirects to /login if authenticated but user/role is null', () async {
         final redirectPath = testRedirectLogic(
          status: AuthStatus.authenticated,
          user: null, // Simulate missing user/role
          currentLocation: '/',
        );
        // Wait for the microtask (signOut call) to potentially run
        await Future.delayed(Duration.zero);
        
        expect(redirectPath, LoginScreen.routeName);
        // Verify signOut was triggered by the logic inside appRedirectLogic
        verify(mockAuthProvider.signOut()).called(1);
      });
    });

    group('Unauthenticated User', () {
      test('stays on / if unauthenticated', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.unauthenticated,
          currentLocation: '/',
        );
        expect(redirectPath, isNull);
      });

      test('stays on /login if unauthenticated', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.unauthenticated,
          currentLocation: LoginScreen.routeName,
        );
        expect(redirectPath, isNull);
      });

      test('redirects from /traveler to /login if unauthenticated', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.unauthenticated,
          currentLocation: '/traveler',
        );
        expect(redirectPath, LoginScreen.routeName);
      });
      
       test('redirects from /transporteur to /login if unauthenticated', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.unauthenticated,
          currentLocation: '/transporteur',
        );
        expect(redirectPath, LoginScreen.routeName);
      });
       
       test('redirects from /admin to /login if unauthenticated', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.unauthenticated,
          currentLocation: '/admin',
        );
        expect(redirectPath, LoginScreen.routeName);
      });
    });
     
    group('Error State', () {
       test('stays on / if error state', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.error,
          currentLocation: '/',
        );
        expect(redirectPath, isNull);
      });

      test('stays on /login if error state', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.error,
          currentLocation: LoginScreen.routeName,
        );
        expect(redirectPath, isNull);
      });

      test('redirects from /traveler to /login if error state', () {
        final redirectPath = testRedirectLogic(
          status: AuthStatus.error,
          currentLocation: '/traveler',
        );
        expect(redirectPath, LoginScreen.routeName);
      });
    });

  });
} 