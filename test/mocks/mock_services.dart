// import 'package:mockito/mockito.dart'; // REMOVE THIS LINE
import 'package:mockito/annotations.dart';
import 'package:samabus/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Keep Supabase imports

// Define mocks for Supabase and our services
@GenerateMocks([
  AuthService,
  AuthResponse,
  User,
  Session,
  SupabaseClient,
  GoTrueClient
])
void main() {} // Dummy main for build_runner