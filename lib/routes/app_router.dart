import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user.dart' as app_user; // Ensure alias is used for UserRole
import '../providers/auth_provider.dart';
import '../providers/auth_status.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/splash_screen.dart';
// Remove generic home screen import if not needed
// import '../screens/home_screen.dart';

// Import role-specific screens
import '../screens/traveler/traveler_home_screen.dart';
import '../screens/transporteur/transporteur_home_screen.dart'; // Updated path
import '../screens/admin/admin_dashboard_screen.dart';

// --- Top-level Redirect Logic Function --- //
// Made accessible for testing, but consider keeping file-private (_appRedirectLogic)
// if preferred and adjusting test setup accordingly.
String? appRedirectLogic(BuildContext context, GoRouterState state, AuthProvider authProvider) {
  final authStatus = authProvider.status;
  final userRole = authProvider.user?.role;
  final currentLoc = state.matchedLocation;

  final isAuthRoute = currentLoc == LoginScreen.routeName ||
                      currentLoc == SignupScreen.routeName ||
                      currentLoc == ForgotPasswordScreen.routeName;
  final isSplash = currentLoc == '/';

  print('Router Redirect: status=$authStatus, location=$currentLoc, role=$userRole, isAuthRoute=$isAuthRoute, isSplash=$isSplash');

  // --- Handle Loading States --- //
  if (authStatus == AuthStatus.uninitialized ||
      authStatus == AuthStatus.authenticating ||
      authStatus == AuthStatus.loadingProfile) {
    print('Redirect: In loading state ($authStatus), staying.');
    return null; // Stay on current page (e.g., splash)
  }

  // --- Handle Authenticated State (Profile Loaded) --- //
  if (authStatus == AuthStatus.authenticated) {
    print('Redirect: Authenticated (Profile Loaded), User Role: $userRole');
    if (userRole == null) {
      print('Redirect ERROR: Authenticated but role is null! Signing out and redirecting to login.');
      Future.microtask(() => authProvider.signOut());
      return LoginScreen.routeName;
    }
    if (isSplash || isAuthRoute) {
      switch (userRole) {
        case app_user.UserRole.traveler: return '/traveler';
        case app_user.UserRole.transporteur: return '/transporteur';
        case app_user.UserRole.admin: return '/admin';
      }
    }
    return null; // Already authenticated and on a valid page
  }

  // --- Handle Unauthenticated or Error State --- //
  if (authStatus == AuthStatus.unauthenticated || authStatus == AuthStatus.error) {
    print('Redirect: Unauthenticated or Error state');
    if (!isSplash && !isAuthRoute) {
      print('Redirect: Unauthenticated/Error on protected page ($currentLoc) -> LoginScreen');
      return LoginScreen.routeName;
    }
    return null; // Allow staying on public pages
  }

  print('Redirect: Fallthrough - No condition met, staying on $currentLoc.');
  return null;
}

// --- Router Configuration Class --- //
class AppRouter {
  // Static method to create the router configuration
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/', // Start at splash screen path

      routes: <RouteBase>[
        GoRoute(
          path: '/', // Path for SplashScreen
          name: 'splash',
          builder: (BuildContext context, GoRouterState state) {
            return const SplashScreen();
          },
        ),
        // Auth Routes
        GoRoute(
          path: LoginScreen.routeName,
          name: LoginScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const LoginScreen();
          },
        ),
        GoRoute(
          path: SignupScreen.routeName,
          name: SignupScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const SignupScreen();
          },
        ),
        GoRoute(
          path: ForgotPasswordScreen.routeName,
          name: ForgotPasswordScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const ForgotPasswordScreen();
          },
        ),
        // Role-Specific Home Routes
        GoRoute(
          path: '/traveler', // Explicit path
          name: TravelerHomeScreen.routeName, // Use constant for name if needed
          builder: (BuildContext context, GoRouterState state) {
            return const TravelerHomeScreen();
          },
        ),
        GoRoute(
          path: '/transporteur', // Explicit path
          name: TransporteurHomeScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const TransporteurHomeScreen();
          },
        ),
        GoRoute(
          path: '/admin', // Explicit path
          name: AdminDashboardScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const AdminDashboardScreen();
          },
        ),
        // Remove generic HomeScreen route if it's fully replaced
        // GoRoute(
        //   path: HomeScreen.routeName, 
        //   name: HomeScreen.routeName,
        //   builder: (BuildContext context, GoRouterState state) {
        //     return const HomeScreen();
        //   },
        // ),
      ],

      // Use the extracted redirect function
      redirect: (BuildContext context, GoRouterState state) => appRedirectLogic(context, state, authProvider),
    );
  }
} 