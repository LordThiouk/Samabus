import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import './auth_status.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  app_user.User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthProvider(this._authService, {bool skipInitialCheck = false}) {
    // print('AuthProvider: Constructor called.');
    _authStateSubscription = _authService.onAuthStateChange.listen(_onAuthStateChanged);
    if (!skipInitialCheck) {
      // print('AuthProvider: Calling _checkInitialSession...');
      _checkInitialSession();
    } else {
      // print('AuthProvider: Skipping initial session check.');
      // Note: No longer forcing status for tests here, rely on skipInitialCheck
      _setStatus(AuthStatus.unauthenticated); // Manually set status for tests
      // print('AuthProvider: Manually set initial status to unauthenticated for testing.');
    }
  }

  // Getters
  AuthStatus get status => _status;
  app_user.User? get user => _user;
  String? get errorMessage => _errorMessage;
  // Update isAuthenticated to reflect the final authenticated state
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Check initial session state without blocking constructor
  Future<void> _checkInitialSession() async {
     // print('AuthProvider: _checkInitialSession started.');
     _setStatus(AuthStatus.authenticating); // Indicate we are checking
    try {
      // print('AuthProvider: Checking Supabase.instance.client.auth.currentSession...');
      final currentSession = Supabase.instance.client.auth.currentSession;
      // print('AuthProvider: currentSession result: ${currentSession?.toJson()}');

      if (currentSession != null) {
         // print('AuthProvider: Initial session found. Setting status to loadingProfile and calling _loadUserProfile...');
         _setStatus(AuthStatus.loadingProfile); // Set status before async fetch
         await _loadUserProfile(); // Attempt to load profile
         // print('AuthProvider: _loadUserProfile completed within _checkInitialSession.');
      } else {
         // print('AuthProvider: No initial session found. Setting status to unauthenticated.');
         _setStatus(AuthStatus.unauthenticated);
         // print('AuthProvider: Status set to unauthenticated. Notifying listeners.');
      }
    } catch (e) {
      // print('AuthProvider: Error checking initial session: $e');
      _user = null;
      _setStatus(AuthStatus.error);
      _errorMessage = 'Failed to initialize session.';
    }
    // print('AuthProvider: _checkInitialSession finished.');
  }


  void _onAuthStateChanged(AuthState authState) async {
    // print('AuthProvider AuthState changed: ${authState.event}, session: ${authState.session != null}');

    // Handle signed in, token refreshed, user updated
    if (authState.event == AuthChangeEvent.signedIn ||
        authState.event == AuthChangeEvent.tokenRefreshed ||
        authState.event == AuthChangeEvent.userUpdated) {
      if (authState.session != null) {
        _setStatus(AuthStatus.loadingProfile); // Set status before async fetch
        await _loadUserProfile();
      } else {
        // This case might occur if Supabase fires signedIn but session is null (edge case)
        // print('AuthProvider Warning: ${authState.event} event but session is null.');
        _user = null;
        _setStatus(AuthStatus.unauthenticated);
      }
    }
    // Handle signed out, user deleted
    else if (authState.event == AuthChangeEvent.signedOut || authState.event == AuthChangeEvent.userDeleted) {
      _user = null;
      _setStatus(AuthStatus.unauthenticated);
    }
    // Handle password recovery - user remains unauthenticated
    else if (authState.event == AuthChangeEvent.passwordRecovery) {
      // Keep status as unauthenticated, maybe set a message?
       // print('AuthProvider: Password recovery event.');
       if (_status != AuthStatus.unauthenticated) {
          _setStatus(AuthStatus.unauthenticated);
       }
    }
    // Handle MFA if implemented
    else if (authState.event == AuthChangeEvent.mfaChallengeVerified) {
       // print('AuthProvider: MFA verified event.');
       // Should trigger a profile load similar to signedIn
       _setStatus(AuthStatus.loadingProfile);
       await _loadUserProfile();
    }
     // Note: Supabase might fire initialSession, but our _checkInitialSession covers this.
     // We rely on subsequent signedIn or signedOut events after the initial check.
  }

  // Helper function to load user profile
  Future<void> _loadUserProfile() async {
    // print('AuthProvider: _loadUserProfile started.');
    try {
      // print('AuthProvider: Calling _authService.getCurrentUserAppModel()...');
      _user = await _authService.getCurrentUserAppModel();
      // print('AuthProvider: _authService.getCurrentUserAppModel() completed. User: ${_user?.toJson()}');

      if (_user != null) {
        _setStatus(AuthStatus.authenticated);
        // print('AuthProvider: User Profile Loaded: ${_user!.id}, Role: ${_user!.role}');
      } else {
        // Could happen if profile doesn't exist in our tables yet after signup
        // print('AuthProvider Warning: Authenticated but failed to fetch app user model (profile might be missing).');
        // Keep status as loadingProfile or switch to an error/specific state?
        // For now, treat as unauthenticated for routing purposes, but log warning.
        _setStatus(AuthStatus.unauthenticated);
        // Consider signing out the Supabase session if profile is mandatory?
        // await _authService.signOut();
      }
    } catch (e) {
      // print('AuthProvider Error fetching user profile: $e');
      _user = null;
      _setStatus(AuthStatus.error);
      _errorMessage = 'Failed to load user profile.';
    }
    // print('AuthProvider: _loadUserProfile finished.');
  }

  // Helper to set status and notify
  void _setStatus(AuthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      if (newStatus != AuthStatus.error) {
        _errorMessage = null; // Clear error on non-error status change
      }
      // print('AuthProvider Status changed: $_status');
      notifyListeners();
    }
  }

  // Public methods wrapping AuthService calls

  Future<bool> signUp({
    required String email,
    required String password,
    required app_user.UserRole role,
    String? phone,
    String? fullName,
    String? companyName,
  }) async {
    // Let the listener handle status changes
    // _setStatus(AuthStatus.authenticating);
    _errorMessage = null; // Clear previous error
    notifyListeners(); // Notify UI immediately if there was a previous error
    try {
      // Prepare the data map for AuthService
      final Map<String, dynamic> data = {
        'role': role.name, // Pass role name as string
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (companyName != null && companyName.isNotEmpty) 'company_name': companyName,
        // Add other metadata if needed
      };
      // print('AuthProvider: Calling signUp with email: $email, data: $data');

      // Call AuthService.signUp with email, password, and the data map
      await _authService.signUp(
        email: email,
        password: password,
        data: data, // Pass the prepared data map
      );
      // Success! State update will be handled by the _onAuthStateChanged listener
      // IF email verification is off OR after user verifies email.
      // Until then, state remains unauthenticated or as it was.
      // print('AuthProvider: SignUp call successful for $email. Waiting for Supabase event/verification.');
      return true; // Indicate the API call succeeded
    } on AuthException catch (e) {
      // print('AuthProvider: SignUp AuthException - ${e.message}');
      _errorMessage = e.message;
      _setStatus(AuthStatus.error); // Set error status explicitly here
      return false;
    } catch (e) {
      // print('AuthProvider: SignUp Unknown Error - $e');
      _errorMessage = 'An unknown error occurred during sign up.';
      _setStatus(AuthStatus.error); // Set error status explicitly here
      return false;
    }
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Let the listener handle status changes
    // _setStatus(AuthStatus.authenticating);
    _errorMessage = null; // Clear previous error
    notifyListeners();
    try {
      await _authService.signInWithPassword(email: email, password: password);
      // Success! State update handled by listener (_onAuthStateChanged -> loadingProfile -> authenticated)
       // print('AuthProvider: signInWithPassword call successful for $email.');
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.error); // Set error status explicitly here
      return false;
    } catch (e) {
      _errorMessage = 'An unknown error occurred during sign in.';
      _setStatus(AuthStatus.error); // Set error status explicitly here
      return false;
    }
  }

  Future<void> signOut() async {
    try {
       // print('AuthProvider: signOut called.');
      await _authService.signOut();
      // State update handled by listener
    } catch (e) {
      // print('AuthProvider: Error during sign out: $e');
      _errorMessage = 'Failed to sign out.';
      _setStatus(AuthStatus.error);
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _errorMessage = null;
    try {
      await _authService.sendPasswordResetEmail(email: email);
       // print('AuthProvider: sendPasswordResetEmail call successful for $email.');
      // State remains unauthenticated
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setStatus(AuthStatus.unauthenticated); // Ensure state is correct (this calls notifyListeners if status changes)
      notifyListeners(); // Reinstated: Notify UI of error message - _setStatus handles notification
      return false;
    } catch (e) {
      _errorMessage = 'An unknown error occurred sending password reset email.';
      _setStatus(AuthStatus.unauthenticated); // Ensure state is correct (this calls notifyListeners if status changes)
       notifyListeners(); // Reinstated: Notify UI of error message - _setStatus handles notification
      return false;
    }
  }

  // Clean up subscription
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
