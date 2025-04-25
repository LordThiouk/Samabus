import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:samabus/services/auth_service.dart'; // Adjust import path if needed

// Generate mocks for Supabase classes
@GenerateMocks([
  SupabaseClient,
  GoTrueClient, // Supabase Auth client
  // Temporarily removed:
  // SupabaseQueryBuilder,
  // PostgrestFilterBuilder,
  // PostgrestResponse
])
import 'auth_service_test.mocks.dart';

void main() {
  // Declare mock variables
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late AuthServiceImpl authService;

  setUp(() {
    // Initialize mocks before each test
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    // Link mocks: SupabaseClient -> GoTrueClient
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    // Create the service instance, injecting the MOCK client
    authService = AuthServiceImpl(mockSupabaseClient);
  });

  // --- Test Group: signUp ---
  group('signUp', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testFullName = 'Test User';
    const testPhone = '123456789';
    final testMetadata = {
      'role': 'traveler',
      'full_name': testFullName,
      'phone': testPhone,
    };

    test('should call supabaseClient.auth.signUp with correct parameters', () async {
      // Arrange
      final fakeAuthResponse = AuthResponse(session: null, user: User(id: 'uuid', appMetadata: {}, userMetadata: {}, aud: 'aud', createdAt: DateTime.now().toIso8601String()));
      when(mockGoTrueClient.signUp(email: anyNamed('email'), password: anyNamed('password'), data: anyNamed('data')))
          .thenAnswer((_) async => fakeAuthResponse);

      // Act: Call the service method with email, password, and data map
      await authService.signUp(
        email: testEmail,
        password: testPassword,
        data: testMetadata,
      );

      // Assert: Verify mockGoTrueClient.signUp was called with expected args
      verify(mockGoTrueClient.signUp(
        email: testEmail,
        password: testPassword,
        data: testMetadata,
      )).called(1);
    });

     test('should rethrow AuthException on Supabase signUp failure', () async {
        // Arrange
        when(mockGoTrueClient.signUp(email: anyNamed('email'), password: anyNamed('password'), data: anyNamed('data')))
            .thenThrow(const AuthException('Failed to sign up'));

        // Act & Assert
        expect(
          () async => authService.signUp(
              email: testEmail, password: testPassword, data: testMetadata),
          throwsA(isA<AuthException>()),
        );
      });

  });

  // --- Test Group: signInWithPassword ---
   group('signInWithPassword', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';

      test('should call supabaseClient.auth.signInWithPassword with correct parameters', () async {
         // Arrange
         final fakeAuthResponse = AuthResponse(session: null, user: User(id: 'uuid', appMetadata: {}, userMetadata: {}, aud: 'aud', createdAt: DateTime.now().toIso8601String()));
          when(mockGoTrueClient.signInWithPassword(email: anyNamed('email'), password: anyNamed('password')))
             .thenAnswer((_) async => fakeAuthResponse);

         // Act
         await authService.signInWithPassword(email: testEmail, password: testPassword);

         // Assert
         verify(mockGoTrueClient.signInWithPassword(email: testEmail, password: testPassword)).called(1);
      });

       test('should rethrow AuthException on Supabase signIn failure', () async {
          // Arrange
          when(mockGoTrueClient.signInWithPassword(email: anyNamed('email'), password: anyNamed('password')))
             .thenThrow(const AuthException('Invalid login credentials'));

          // Act & Assert
          expect(
            () async => authService.signInWithPassword(email: testEmail, password: testPassword),
            throwsA(isA<AuthException>()),
          );
        });
   });

  // --- Test Group: signOut ---
  group('signOut', () {
     test('should call supabaseClient.auth.signOut', () async {
        // Arrange
        when(mockGoTrueClient.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockGoTrueClient.signOut()).called(1);
     });
   });

  // --- Test Group: sendPasswordResetEmail ---
   group('sendPasswordResetEmail', () {
      const testEmail = 'test@example.com';
      test('should call supabaseClient.auth.resetPasswordForEmail', () async {
         // Arrange
         when(mockGoTrueClient.resetPasswordForEmail(any)).thenAnswer((_) async {});

         // Act
         await authService.sendPasswordResetEmail(email: testEmail);

         // Assert
         verify(mockGoTrueClient.resetPasswordForEmail(testEmail)).called(1);
      });
   });

   // --- Test Group: getCurrentUserAppModel (COMMENTED OUT) ---
   /*
   // Unit testing getCurrentUserAppModel is currently blocked because
   // build_runner fails to generate mocks for PostgREST classes
   // (SupabaseQueryBuilder, PostgrestFilterBuilder) in this environment.
   // These tests require Dependency Injection and working mocks for the builder chain.
   // Coverage for this method should be ensured via Integration Tests.
   group('getCurrentUserAppModel', () {
       final testUserId = 'test-user-id';
       final mockSupabaseUser = User(
           id: testUserId,
           appMetadata: {'provider': 'email'},
           userMetadata: {},
           aud: 'authenticated',
           createdAt: DateTime.now().toIso8601String(),
           emailConfirmedAt: DateTime.now().toIso8601String(), // Verified
           phoneConfirmedAt: null, // Example
       );
        final mockProfileData = {
          'user_id': testUserId,
          'role': 'transporteur',
          'full_name': 'Test Transporter',
          'phone': '987654321',
          'company_name': 'Test Bus Co',
          'approved': true,
        };

       test('should return null if Supabase user is null', () async {
         // Arrange
         when(mockGoTrueClient.currentUser).thenReturn(null);

         // Act
         final result = await authService.getCurrentUserAppModel();

         // Assert
         expect(result, isNull);
       });

       test('should return app_user.User if Supabase user and profile exist', () async {
          // Arrange
          when(mockGoTrueClient.currentUser).thenReturn(mockSupabaseUser);
          // Setup mocks for the builder chain (requires working mocks)
          // when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
          // when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
          // when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
          // when(mockFilterBuilder.single()).thenAnswer((_) async => mockProfileData);

          // Act
          final result = await authService.getCurrentUserAppModel();

          // Assert
          expect(result, isA<app_user.User>());
          expect(result?.id, testUserId);
          expect(result?.role, app_user.UserRole.transporteur);
          // ... other checks ...
       });

        test('should return null if profile fetch fails', () async {
           // Arrange
           when(mockGoTrueClient.currentUser).thenReturn(mockSupabaseUser);
           // Setup mocks for the builder chain to throw an error
           // when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
           // when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
           // when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
           // when(mockFilterBuilder.single()).thenThrow(Exception('DB error'));

           // Act
           final result = await authService.getCurrentUserAppModel();

           // Assert
           expect(result, isNull);
        });

         test('should return null if profile data is null/empty', () async {
           // Arrange
           when(mockGoTrueClient.currentUser).thenReturn(mockSupabaseUser);
           // Setup mocks for the builder chain to return null
           // when(mockSupabaseClient.from(any)).thenReturn(mockQueryBuilder);
           // when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
           // when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
           // when(mockFilterBuilder.single()).thenAnswer((_) async => null);

           // Act
           final result = await authService.getCurrentUserAppModel();

           // Assert
           expect(result, isNull);
         });
   });
   */
} 