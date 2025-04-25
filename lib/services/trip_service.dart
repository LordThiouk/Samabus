import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trip.dart';
// import '../models/bus.dart'; // Removed

class TripService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Trip>> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    // Convert date to start and end of day
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
    
    return response.map<Trip>((json) => Trip.fromJson(json)).toList();
  }

  Future<Trip> getTripDetails(String tripId) async {
    final response = await _supabase
        .from('trips')
        .select()
        .eq('id', tripId)
        .single();
    
    return Trip.fromJson(response);
  }

  Future<List<Trip>> getTransporteurTrips(String transporteurId) async {
    final response = await _supabase
        .from('trips')
        .select()
        .eq('transporteur_id', transporteurId)
        .order('departure_date_time');
    
    return response.map<Trip>((json) => Trip.fromJson(json)).toList();
  }

  Future<Trip> createTrip({
    required String transporteurId,
    required String busId,
    required String departureCity,
    required String arrivalCity,
    required DateTime departureDateTime,
    DateTime? arrivalDateTime,
    required double fare,
  }) async {
    // Get bus capacity
    final busResponse = await _supabase
        .from('buses')
        .select('capacity')
        .eq('id', busId)
        .single();
    
    final capacity = busResponse['capacity'] as int;
    
    // Generate trip ID
    final tripId = 'TRIP-${DateTime.now().millisecondsSinceEpoch}';
    
    // Create trip in database
    final tripData = {
      'id': tripId,
      'transporteur_id': transporteurId,
      'bus_id': busId,
      'departure_city': departureCity,
      'arrival_city': arrivalCity,
      'departure_date_time': departureDateTime.toIso8601String(),
      'arrival_date_time': arrivalDateTime?.toIso8601String(),
      'fare': fare,
      'total_seats': capacity,
      'available_seats': capacity,
      'is_active': true,
      'created_at': DateTime.now().toIso8601String(),
    };
    
    await _supabase.from('trips').insert(tripData);
    
    // Return Trip object matching the model constructor
    return Trip(
      id: tripId,
      busId: busId,
      departureCity: departureCity,
      destinationCity: arrivalCity,
      departureTimestamp: departureDateTime,
      arrivalTimestamp: arrivalDateTime,
      pricePerSeat: fare,
      status: 'scheduled',
      totalSeats: capacity,
      availableSeats: capacity,
    );
  }

  Future<bool> updateTrip({
    required String tripId,
    String? departureCity,
    String? arrivalCity,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    double? fare,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (departureCity != null) updates['departure_city'] = departureCity;
    if (arrivalCity != null) updates['arrival_city'] = arrivalCity;
    if (departureDateTime != null) updates['departure_date_time'] = departureDateTime.toIso8601String();
    if (arrivalDateTime != null) updates['arrival_date_time'] = arrivalDateTime.toIso8601String();
    if (fare != null) updates['fare'] = fare;
    if (isActive != null) updates['is_active'] = isActive;
    
    await _supabase.from('trips').update(updates).eq('id', tripId);
    
    return true;
  }

  Future<bool> deleteTrip(String tripId) async {
    // Check if there are any bookings for this trip
    final bookingsResponse = await _supabase
        .from('bookings')
        .select('id')
        .eq('trip_id', tripId)
        .limit(1);
    
    if (bookingsResponse.isNotEmpty) {
      // If there are bookings, just mark as inactive
      await _supabase.from('trips').update({
        'is_active': false,
      }).eq('id', tripId);
    } else {
      // If no bookings, delete the trip
      await _supabase.from('trips').delete().eq('id', tripId);
    }
    
    return true;
  }
}
