import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Unused
import '../models/user.dart' as app_user;
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isTraveler => _currentUser?.role == app_user.UserRole.traveler;
  bool get isTransporteur => _currentUser?.role == app_user.UserRole.transporteur;
  bool get isAdmin => _currentUser?.role == app_user.UserRole.admin;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final supabaseUser = await _supabaseService.getCurrentUser();
      if (supabaseUser != null) {
        // Fetch user data from the database
        final userData = await _supabaseService.client
            .from('users')
            .select()
            .eq('id', supabaseUser.id)
            .single();
        
        _currentUser = app_user.User.fromJson(userData);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String phoneNumber,
    required app_user.UserRole role,
    String? fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create auth user
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile
      final userData = {
        'id': response.user!.id,
        'email': email,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'role': role.toString().split('.').last,
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final createdUser = await _supabaseService.createUser(userData: userData);
      _currentUser = app_user.User.fromJson(createdUser);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Invalid credentials');
      }

      // Get user profile
      final userData = await _supabaseService.client
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      _currentUser = app_user.User.fromJson(userData);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;

      await _supabaseService.client
          .from('users')
          .update(updates)
          .eq('id', _currentUser!.id);

      // Refresh user data
      final userData = await _supabaseService.client
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .single();
      
      _currentUser = app_user.User.fromJson(userData);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPhone() async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, this would send a verification code
      // For now, we'll just mark the user as verified
      await _supabaseService.client
          .from('users')
          .update({
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      // Refresh user data
      final userData = await _supabaseService.client
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .single();
      
      _currentUser = app_user.User.fromJson(userData);
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
