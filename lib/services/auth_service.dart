import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samabus/models/user.dart' as app_user;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<app_user.User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map(_mapSupabaseUser);

  app_user.User? _mapSupabaseUser(AuthState authState) {
    final supabaseUser = authState.session?.user;
    if (supabaseUser == null) {
      return null;
    }
    // TODO: Fetch additional user details (role, profile) from your profiles table
    //       based on supabaseUser.id and populate the app_user.User model correctly.
    //       This placeholder might cause issues if used before profile exists.
    return app_user.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? 'no-email@example.com', // Default if null
      phoneNumber: supabaseUser.phone ?? '0000000000', // Default if null
      role: app_user.UserRole.traveler, // Placeholder Role - MUST be fetched
      isVerified: supabaseUser.emailConfirmedAt != null || supabaseUser.phoneConfirmedAt != null,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      updatedAt: supabaseUser.updatedAt != null ? DateTime.parse(supabaseUser.updatedAt!) : DateTime.now(),
      // fullName is nullable
    );
  }

  app_user.User? get currentUser {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) {
      return null;
    }
    // TODO: Fetch additional user details from profiles table
    //       This placeholder might cause issues if used before profile exists.
    return app_user.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? 'no-email@example.com', // Default if null
      phoneNumber: supabaseUser.phone ?? '0000000000', // Default if null
      role: app_user.UserRole.traveler, // Placeholder Role - MUST be fetched
      isVerified: supabaseUser.emailConfirmedAt != null || supabaseUser.phoneConfirmedAt != null,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      updatedAt: supabaseUser.updatedAt != null ? DateTime.parse(supabaseUser.updatedAt!) : DateTime.now(),
      // fullName is nullable
    );
  }

  Future<app_user.User?> signUp({
    required String email,
    required String password,
    required app_user.UserRole role,
    String? phoneNumber,
    String? fullName,
    String? companyName,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        // Supabase handles email verification flow by default
      );
      
      final supabaseUser = response.user;
      if (supabaseUser != null) {
        // TODO: Insert corresponding entry into 'profiles' table
        // using supabaseUser.id and the provided role, phone, name etc.
        // This might involve another SupabaseService method.
        // print('Signup successful, user ID: ${supabaseUser.id}, role: $role'); // Removed print
        
        // Placeholder user until profile is created/fetched
        // This user object might be incomplete until profile data is available
        return app_user.User( 
          id: supabaseUser.id, 
          email: supabaseUser.email ?? 'no-email@example.com',
          phoneNumber: phoneNumber ?? '0000000000', // Use provided or default
          // Remove parsing logic, use the role directly
          role: role,
          fullName: fullName, // Pass along (nullable)
          isVerified: false, // Not verified initially
          createdAt: DateTime.parse(supabaseUser.createdAt),
          updatedAt: supabaseUser.updatedAt != null ? DateTime.parse(supabaseUser.updatedAt!) : DateTime.now(),
        );
      } else {
        throw ('Sign up failed: No user returned');
      }
    } catch (e) {
      // print('AuthService Error - signUp: $e'); // Removed print
      // Consider more specific error handling/reporting
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<app_user.User?> signInWithPassword(
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid credentials');
    }

    // Get user profile
    final userResponse = await _supabase
        .from('users')
        .select()
        .eq('id', response.user!.id)
        .single();

    if (userResponse != null) {
      // Parse the full user from the response map
      return app_user.User.fromJson(userResponse); 
    } else {
      throw Exception('User profile not found');
    }
  }

  Future<app_user.User?> signInWithPhone({
    required String phoneNumber,
    required String smsCode,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.verifyOTP(
        type: OtpType.sms, // or phone_change, signup, recovery etc.
        token: smsCode, 
        phone: phoneNumber,
      );
      final supabaseUser = response.user;
      if (supabaseUser != null) {
        // TODO: Fetch full profile details for the verified phone user
        //       This placeholder might cause issues.
        return app_user.User( 
          id: supabaseUser.id,
          email: supabaseUser.email ?? 'no-email@example.com',
          phoneNumber: supabaseUser.phone ?? phoneNumber, // Use the phone number used for OTP
          role: app_user.UserRole.traveler, // Placeholder Role - MUST be fetched
          isVerified: true, // Phone is verified
          createdAt: DateTime.parse(supabaseUser.createdAt),
          updatedAt: supabaseUser.updatedAt != null ? DateTime.parse(supabaseUser.updatedAt!) : DateTime.now(),
          // fullName is nullable
        );
      } else {
        throw ('Sign in failed: No user returned after OTP verification');
      }
    } catch (e) {
      // print('AuthService Error - signInWithPhone: $e'); // Removed print
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
        // shouldCreateUser: false, // Set to true if OTP can also be for signup
      );
    } catch (e) {
      // print('AuthService Error - sendOtp: $e'); // Removed print
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  Future<app_user.User?> verifyPhoneOtp(
    String phoneNumber,
    String code,
  ) async {
    final response = await _supabase.functions.invoke(
      'verify-phone-code',
      body: {
        'phone_number': phoneNumber,
        'code': code,
      },
    );

    if (response.status != 200) {
      throw Exception('Invalid verification code');
    }

    // Update user verification status
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('users').update({
        'is_verified': true,
      }).eq('id', user.id);
    }

    if (user != null) {
      // TODO: Fetch role and other details from profiles table based on user.id
      //       This placeholder might cause issues.
      return app_user.User( 
          id: user.id,
          email: user.email ?? 'no-email@example.com',
          phoneNumber: user.phone ?? phoneNumber, // Use verified phone
          role: app_user.UserRole.traveler, // Placeholder Role - MUST be fetched
          isVerified: true, // Phone verified
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: user.updatedAt != null ? DateTime.parse(user.updatedAt!) : DateTime.now(),
          // fullName is nullable
        );
    } else {
      throw Exception('User not found');
    }
  }

  Future<bool> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
    return true;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<app_user.User?> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phoneNumber != null) updates['phone_number'] = phoneNumber;

    await _supabase.from('users').update(updates).eq('id', userId);

    // Get updated user
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    if (response != null) {
      return app_user.User.fromJson(response); // Assuming response is the full user profile map
    } else {
      throw Exception('User not found');
    }
  }
}
