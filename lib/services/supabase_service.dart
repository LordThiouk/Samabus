import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseClient get client => _supabase;

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }

  // Database methods
  Future<List<Map<String, dynamic>>> getTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final response = await _supabase
        .from('trips')
        .select()
        .eq('departure_city', departureCity)
        .eq('arrival_city', arrivalCity)
        .gte('departure_date_time', startOfDay.toIso8601String())
        .lte('departure_date_time', endOfDay.toIso8601String())
        .eq('is_active', true)
        .gt('available_seats', 0)
        .order('departure_date_time');
    
    return response;
  }

  Future<Map<String, dynamic>> createBooking({
    required Map<String, dynamic> bookingData,
  }) async {
    final response = await _supabase
        .from('bookings')
        .insert(bookingData)
        .select()
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('booking_date_time', ascending: false);
    
    return response;
  }

  Future<Map<String, dynamic>> createUser({
    required Map<String, dynamic> userData,
  }) async {
    final response = await _supabase
        .from('users')
        .insert(userData)
        .select()
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> createTransporteur({
    required Map<String, dynamic> transporteurData,
  }) async {
    final response = await _supabase
        .from('transporteurs')
        .insert(transporteurData)
        .select()
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getBuses(String transporteurId) async {
    final response = await _supabase
        .from('buses')
        .select()
        .eq('transporteur_id', transporteurId)
        .eq('is_active', true);
    
    return response;
  }

  Future<Map<String, dynamic>> createBus({
    required Map<String, dynamic> busData,
  }) async {
    final response = await _supabase
        .from('buses')
        .insert(busData)
        .select()
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> createTrip({
    required Map<String, dynamic> tripData,
  }) async {
    final response = await _supabase
        .from('trips')
        .insert(tripData)
        .select()
        .single();
    
    return response;
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    String? paymentMethod,
    String? paymentId,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };
    
    if (paymentMethod != null) {
      updates['payment_method'] = paymentMethod;
    }
    
    if (paymentId != null) {
      updates['payment_id'] = paymentId;
    }
    
    await _supabase
        .from('bookings')
        .update(updates)
        .eq('id', bookingId);
  }

  Future<void> validateTicket({
    required String bookingId,
    required String validatedBy,
  }) async {
    await _supabase
        .from('bookings')
        .update({
          'status': 'completed',
          'validated_by': validatedBy,
          'validated_date_time': DateTime.now().toIso8601String(),
        })
        .eq('id', bookingId);
  }

  Future<void> decreaseAvailableSeats({
    required String tripId,
    required int seatsCount,
  }) async {
    await _supabase.rpc(
      'decrease_available_seats',
      params: {
        'trip_id': tripId,
        'seats_count': seatsCount,
      },
    );
  }

  Future<void> increaseAvailableSeats({
    required String tripId,
    required int seatsCount,
  }) async {
    await _supabase.rpc(
      'increase_available_seats',
      params: {
        'trip_id': tripId,
        'seats_count': seatsCount,
      },
    );
  }
}
