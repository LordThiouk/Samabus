import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../utils/qr_generator.dart';

class BookingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Booking> createBooking({
    required String userId,
    required String tripId,
    required List<Passenger> passengers,
    required double totalAmount,
    required double platformFee,
  }) async {
    // Generate a unique booking ID
    final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Generate QR code
    final qrCode = await QRGenerator.generateQRCode(bookingId);
    
    // Create booking in database
    final bookingData = {
      'id': bookingId,
      'user_id': userId,
      'trip_id': tripId,
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'total_amount': totalAmount,
      'platform_fee': platformFee,
      'status': BookingStatus.pending.toString().split('.').last,
      'booking_date_time': DateTime.now().toIso8601String(),
      'qr_code': qrCode,
    };
    
    await _supabase.from('bookings').insert(bookingData);
    
    // Update available seats on the trip
    await _supabase.rpc(
      'decrease_available_seats', 
      params: {
        'trip_id': tripId,
        'seats_count': passengers.length,
      }
    );
    
    return Booking(
      id: bookingId,
      userId: userId,
      tripId: tripId,
      passengers: passengers,
      totalAmount: totalAmount,
      platformFee: platformFee,
      status: BookingStatus.pending,
      bookingDateTime: DateTime.now(),
      qrCode: qrCode,
    );
  }

  Future<Booking> processPayment({
    required String bookingId,
    required PaymentMethod paymentMethod,
  }) async {
    // In a real app, this would integrate with PayDunya or CinetPay
    // For now, we'll simulate a successful payment
    
    final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    
    // Update booking with payment info
    await _supabase.from('bookings').update({
      'status': BookingStatus.confirmed.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last,
      'payment_id': paymentId,
    }).eq('id', bookingId);
    
    // Get updated booking
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .single();
    
    return Booking.fromJson(response);
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('booking_date_time', ascending: false);
    
    return response.map<Booking>((json) => Booking.fromJson(json)).toList();
  }

  Future<bool> cancelBooking(String bookingId) async {
    // Get booking details to check if it can be cancelled
    final bookingResponse = await _supabase
        .from('bookings')
        .select('trip_id, status, passengers')
        .eq('id', bookingId)
        .single();
    
    final status = BookingStatus.values.firstWhere(
      (e) => e.toString().split('.').last == bookingResponse['status'],
      orElse: () => BookingStatus.pending,
    );
    
    // Only pending or confirmed bookings can be cancelled
    if (status != BookingStatus.pending && status != BookingStatus.confirmed) {
      return false;
    }
    
    // Update booking status
    await _supabase.from('bookings').update({
      'status': BookingStatus.cancelled.toString().split('.').last,
    }).eq('id', bookingId);
    
    // Increase available seats on the trip
    final tripId = bookingResponse['trip_id'];
    final passengersCount = (bookingResponse['passengers'] as List).length;
    
    await _supabase.rpc(
      'increase_available_seats', 
      params: {
        'trip_id': tripId,
        'seats_count': passengersCount,
      }
    );
    
    return true;
  }

  Future<Booking?> getBookingDetails(String bookingId) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('id', bookingId)
        .single();
    
    return Booking.fromJson(response);
  }

  Future<List<Booking>> getUpcomingBookingsForTransporteur({
    required String transporteurId,
    required int hoursAhead,
  }) async {
    final now = DateTime.now();
    final endTime = now.add(Duration(hours: hoursAhead));
    
    // Get trips for this transporteur
    final tripsResponse = await _supabase
        .from('trips')
        .select('id')
        .eq('transporteur_id', transporteurId)
        .gte('departure_date_time', now.toIso8601String())
        .lte('departure_date_time', endTime.toIso8601String());
    
    final tripIds = tripsResponse.map<String>((trip) => trip['id']).toList();
    
    if (tripIds.isEmpty) {
      return [];
    }
    
    // Get bookings for these trips
    final bookingsResponse = await _supabase
        .from('bookings')
        .select()
        .in_('trip_id', tripIds)
        .in_('status', [
          BookingStatus.confirmed.toString().split('.').last,
          BookingStatus.pending.toString().split('.').last,
        ]);
    
    return bookingsResponse
        .map<Booking>((json) => Booking.fromJson(json))
        .toList();
  }

  Future<bool> validateTicket({
    required String bookingId,
    required String validatedBy,
    required DateTime validatedDateTime,
  }) async {
    await _supabase.from('bookings').update({
      'status': BookingStatus.completed.toString().split('.').last,
      'validated_by': validatedBy,
      'validated_date_time': validatedDateTime.toIso8601String(),
    }).eq('id', bookingId);
    
    return true;
  }
}
