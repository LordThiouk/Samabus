import 'dart:async';
// import '../models/user.dart'; // REMOVE THIS LINE
import 'package:samabus/models/user.dart' as app_user; // Keep this alias
import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/user.dart' show UserRole; // REMOVE THIS LINE
// Import the app's User model if needed, potentially with an alias

// Abstract class defining the authentication service contract
abstract class AuthService {
  // Use the app's User model in the signature
  Future<app_user.User?> getCurrentUserAppModel();
  Stream<AuthState> get onAuthStateChange;
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({required String email});
  // Future<AuthResponse> updateUserPassword({required String newPassword}); // Add later if needed
}

// Implementation using Supabase
class AuthServiceImpl implements AuthService {
  // final SupabaseClient _supabaseClient = Supabase.instance.client; // Remove direct instance usage
  final SupabaseClient _supabaseClient; // Add final field

  // Add constructor for dependency injection
  AuthServiceImpl(this._supabaseClient);

  // Helper method to fetch profile data
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles') // Ensure this table name matches your DB
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      // print('Error fetching profile for user $userId: $e');
      // Handle potential errors like PostgrestException if user not found or RLS denies access
      return null;
    }
  }

  @override
  Future<app_user.User?> getCurrentUserAppModel() async {
    final supabaseUser = _supabaseClient.auth.currentUser;
    if (supabaseUser == null) {
      return null;
    }

    // Fetch profile data using the helper
    final profileData = await _getUserProfile(supabaseUser.id); // Calling the helper

    if (profileData != null) {
      try {
        // Parse role from profile data
        final roleString = profileData['role'] as String?;
        final role = app_user.UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == roleString,
           orElse: () {
             // print('Warning: Could not parse role "$roleString" from profile. Defaulting to traveler.');
             return app_user.UserRole.traveler;
           },
        );

        // Determine verification status from Supabase user
        final isVerified = (supabaseUser.emailConfirmedAt != null && supabaseUser.emailConfirmedAt!.isNotEmpty) ||
                           (supabaseUser.phoneConfirmedAt != null && supabaseUser.phoneConfirmedAt!.isNotEmpty);

        // Get creation time from Supabase user
        final createdAt = DateTime.tryParse(supabaseUser.createdAt) ?? DateTime.now();

        return app_user.User(
          id: supabaseUser.id,
          role: role,
          createdAt: createdAt,
          isVerified: isVerified,
          fullName: profileData['full_name'] as String?,
          phoneNumber: profileData['phone'] as String?,
          companyName: profileData['company_name'] as String?,
          isApproved: profileData['approved'] as bool?,
        );
      } catch (e) {
         // print('Error constructing app_user.User from profile/auth data: $e');
         return null;
      }
    } else {
      // print('Warning: Profile data not found for user ${supabaseUser.id}. Cannot create full App User.');
      return null;
    }
  }

  @override
  Stream<AuthState> get onAuthStateChange {
    return _supabaseClient.auth.onAuthStateChange;
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      // print('AuthService: signUp called with email: $email, data: $data');
      // Use the data map provided by AuthProvider
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: data, // Pass the map directly to Supabase
      );
      // print('AuthService: Supabase signUp response received.');
      
      // Important: Check if user needs confirmation vs. auto-confirmed
      if (response.user != null && response.session == null) {
        // print('AuthService: User needs email confirmation.');
        // Handle confirmation required state if necessary (e.g., return specific status)
      } else if (response.user != null && response.session != null) {
        // print('AuthService: User signed up and logged in (auto-confirm likely on).');
        // User is immediately logged in (auto-confirm on?)
      }
      
      return response; 
    } on AuthException catch (e) {
       // print('AuthService: SignUp AuthException - ${e.message}');
      // Rethrow specific errors if needed or handle them
      if (e.message.contains('User already registered')) {
        // Consider custom exception type
      }
      rethrow;
    } catch (e) {
       // print('AuthService: SignUp Unknown Error - $e');
      // Wrap unknown errors
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // After successful sign-in, the JWT should contain the 'user_role' claim
      // if the Edge Function worked correctly during signup.
      return response;
    } catch (e) {
      // print('Error during sign in: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      // print('Error during sign out: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      // print('Error sending password reset email: $e');
      rethrow;
    }
  }
}
