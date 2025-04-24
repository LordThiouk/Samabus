import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/passenger.dart';
import '../models/enums/booking_status.dart';
import '../models/enums/payment_method.dart';
import '../services/supabase_service.dart';
import '../config/app_config.dart';
import '../utils/qr_generator.dart';

class BookingProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Booking> _userBookings = [];
  Booking? _currentBooking;
  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get userBookings => _userBookings;
  Booking? get currentBooking => _currentBooking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createBooking({
    required String userId,
    required String tripId,
    required List<Passenger> passengers,
    required double farePerSeat,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final totalAmount = farePerSeat * passengers.length;
      final platformFee = totalAmount * AppConfig.platformCommissionRate;
      
      // Generate unique booking ID (consider UUID package for production)
      final bookingId = '${DateTime.now().millisecondsSinceEpoch}-${userId.substring(0, 4)}';
      final qrCode = await QRGenerator.generateQRCode(bookingId);
      
      final bookingData = {
        'id': bookingId,
        'user_id': userId,
        'trip_id': tripId,
        // Assuming Supabase handles passenger insertion separately or via JSONB
        // We need to ensure the 'passengers' field in Supabase matches this structure
        // or adjust the data sent.
        // Let's assume for now Supabase expects a list of passenger JSON objects.
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'total_amount': totalAmount,
        'platform_fee': platformFee,
        // Send enum value as string to Supabase
        'status': BookingStatus.pending.toString().split('.').last,
        'booking_date_time': DateTime.now().toIso8601String(),
        'qr_code': qrCode,
      };

      final response = await _supabaseService.createBooking(bookingData: bookingData);
      // Ensure the response from createBooking matches the Booking model structure
      _currentBooking = Booking.fromJson(response);
      
      // Decrease available seats (make sure Trip model has this)
      await _supabaseService.decreaseAvailableSeats(
        tripId: tripId,
        seatsCount: passengers.length, // Use passengers length
      );
      
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

  Future<bool> processPayment({
    required String bookingId,
    required PaymentMethod paymentMethod, // Use imported PaymentMethod type
  }) async {
    if (_currentBooking == null || _currentBooking!.id != bookingId) {
       _errorMessage = "Current booking mismatch or null.";
       notifyListeners();
       return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabaseService.updateBookingStatus(
        bookingId: bookingId,
        // Send enum value as string
        status: BookingStatus.confirmed.toString().split('.').last,
        paymentMethod: paymentMethod.toString().split('.').last,
        paymentId: paymentId,
      );
      
      // Update current booking state locally using the enum
        _currentBooking = _currentBooking!.copyWith(
        status: BookingStatus.confirmed, // Use enum directly
        paymentMethod: paymentMethod, // Use enum directly
          paymentId: paymentId,
        );
      
      // Refresh user bookings to reflect the change
      await getUserBookings(_currentBooking!.userId); // Use userId
      
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

  Future<void> getUserBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.getUserBookings(userId);
      _userBookings = response.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      _userBookings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex == -1) {
        throw Exception('Booking not found in local list.');
      }
      final booking = _userBookings[bookingIndex];
      
      await _supabaseService.updateBookingStatus(
        bookingId: bookingId,
        // Send enum value as string
        status: BookingStatus.cancelled.toString().split('.').last,
      );
      
      // Increase available seats
      await _supabaseService.increaseAvailableSeats(
        tripId: booking.tripId,
        seatsCount: booking.passengers.length, // Use passengers length
      );
      
      // Update booking in the list locally using the enum
       _userBookings[bookingIndex] = booking.copyWith(
         status: BookingStatus.cancelled, // Use enum directly
        );
      
       // If the cancelled booking was the current one, clear it
       if (_currentBooking?.id == bookingId) {
         _currentBooking = null;
      }
      
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

  Future<bool> validateTicket({
    required String bookingId,
    required String validatedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.validateTicket(
        bookingId: bookingId,
        validatedBy: validatedBy,
      );
      
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
