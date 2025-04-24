import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' show UserRole;
// Import the app's User model if needed, potentially with an alias
import '../models/user.dart' as app_user;

// Abstract class defining the authentication service contract
abstract class AuthService {
  // Use the app's User model in the signature
  Future<app_user.User?> getCurrentUserAppModel();
  Stream<AuthState> get onAuthStateChange;
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? fullName,
    String? companyName,
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
      print('Error fetching profile for user $userId: $e');
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
             print('Warning: Could not parse role "$roleString" from profile. Defaulting to traveler.');
             return app_user.UserRole.traveler;
           },
        );

        // Determine verification status from Supabase user
        final isVerified = (supabaseUser.emailConfirmedAt != null && supabaseUser.emailConfirmedAt!.isNotEmpty) ||
                           (supabaseUser.phoneConfirmedAt != null && supabaseUser.phoneConfirmedAt!.isNotEmpty);

        // Get creation time from Supabase user
        final createdAt = DateTime.tryParse(supabaseUser.createdAt ?? '') ?? DateTime.now();

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
         print('Error constructing app_user.User from profile/auth data: $e');
         return null;
      }
    } else {
      print('Warning: Profile data not found for user ${supabaseUser.id}. Cannot create full App User.');
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
    required UserRole role,
    String? phone,
    String? fullName,
    String? companyName,
  }) async {
    try {
      // Prepare metadata for signup
      final Map<String, dynamic> userMetadata = {
        'role': role.toString().split('.').last, // Expects 'traveler', 'transporteur', 'admin'
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (companyName != null && role == UserRole.transporteur) 'company_name': companyName, // Check against transporteur
      };

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        phone: phone,
        data: userMetadata,
      );

      return response;
    } on AuthException catch (e) {
      print('AuthException during sign up: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
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
      print('Error during sign in: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
}
