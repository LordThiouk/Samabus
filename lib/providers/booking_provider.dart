import 'package:flutter/material.dart';
import '../models/booking.dart';
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
      
      // Generate QR code
      final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
      final qrCode = await QRGenerator.generateQRCode(bookingId);
      
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

      final response = await _supabaseService.createBooking(bookingData: bookingData);
      _currentBooking = Booking.fromJson(response);
      
      // Decrease available seats
      await _supabaseService.decreaseAvailableSeats(
        tripId: tripId,
        seatsCount: passengers.length,
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
    required PaymentMethod paymentMethod,
  }) async {
    if (_currentBooking == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, this would integrate with PayDunya or CinetPay
      // For now, we'll simulate a successful payment
      final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabaseService.updateBookingStatus(
        bookingId: bookingId,
        status: BookingStatus.confirmed.toString().split('.').last,
        paymentMethod: paymentMethod.toString().split('.').last,
        paymentId: paymentId,
      );
      
      // Update current booking
      if (_currentBooking?.id == bookingId) {
        _currentBooking = _currentBooking!.copyWith(
          status: BookingStatus.confirmed,
          paymentMethod: paymentMethod,
          paymentId: paymentId,
        );
      }
      
      // Refresh user bookings
      await getUserBookings(_currentBooking!.userId);
      
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
      // Get booking details
      final booking = _userBookings.firstWhere((b) => b.id == bookingId);
      
      // Update booking status
      await _supabaseService.updateBookingStatus(
        bookingId: bookingId,
        status: BookingStatus.cancelled.toString().split('.').last,
      );
      
      // Increase available seats
      await _supabaseService.increaseAvailableSeats(
        tripId: booking.tripId,
        seatsCount: booking.passengers.length,
      );
      
      // Update booking in the list
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          status: BookingStatus.cancelled,
        );
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

extension BookingExtension on Booking {
  Booking copyWith({
    String? id,
    String? userId,
    String? tripId,
    List<Passenger>? passengers,
    double? totalAmount,
    double? platformFee,
    BookingStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentId,
    DateTime? bookingDateTime,
    DateTime? validatedDateTime,
    String? validatedBy,
    String? qrCode,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      passengers: passengers ?? this.passengers,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      bookingDateTime: bookingDateTime ?? this.bookingDateTime,
      validatedDateTime: validatedDateTime ?? this.validatedDateTime,
      validatedBy: validatedBy ?? this.validatedBy,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
