import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class OfflineSyncProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final Box _offlineBookingsBox = Hive.box('offlineBookings');
  final Box _validatedTicketsBox = Hive.box('validatedTickets');
  
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  bool _isOffline = false;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  OfflineSyncProvider() {
    // Initialize connectivity listener
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOffline = result == ConnectivityResult.none;
    notifyListeners();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isOffline = result == ConnectivityResult.none;
    notifyListeners();
    
    // If we're back online, try to sync
    if (!_isOffline) {
      syncOfflineData();
    }
  }

  Future<void> downloadUpcomingBookings(String transporteurId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get upcoming bookings for the next 24 hours
      final bookings = await _bookingService.getUpcomingBookingsForTransporteur(
        transporteurId: transporteurId,
        hoursAhead: 24,
      );
      
      // Store in Hive for offline access
      await _offlineBookingsBox.clear();
      for (var booking in bookings) {
        await _offlineBookingsBox.put(booking.id, booking.toJson());
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateTicketOffline({
    required String bookingId,
    required String validatedBy,
  }) async {
    try {
      // Check if booking exists in offline storage
      final bookingJson = _offlineBookingsBox.get(bookingId);
      if (bookingJson == null) {
        _errorMessage = 'Booking not found in offline storage';
        notifyListeners();
        return false;
      }
      
      // Check if already validated
      if (_validatedTicketsBox.containsKey(bookingId)) {
        _errorMessage = 'Ticket already validated';
        notifyListeners();
        return false;
      }
      
      // Mark as validated locally
      final booking = Booking.fromJson(bookingJson);
      final validatedBooking = booking.copyWith(
        validatedDateTime: DateTime.now(),
        validatedBy: validatedBy,
        status: BookingStatus.completed,
      );
      
      // Store in validated tickets box
      await _validatedTicketsBox.put(bookingId, validatedBooking.toJson());
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> syncOfflineData() async {
    if (_isSyncing || _isOffline) return;
    
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get all validated tickets that need to be synced
      final validatedTickets = _validatedTicketsBox.values.toList();
      
      if (validatedTickets.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return;
      }
      
      // Sync each validated ticket
      for (var ticketJson in validatedTickets) {
        final ticket = Booking.fromJson(Map<String, dynamic>.from(ticketJson));
        
        // Update on server
        await _bookingService.validateTicket(
          bookingId: ticket.id,
          validatedBy: ticket.validatedBy!,
          validatedDateTime: ticket.validatedDateTime!,
        );
        
        // Remove from local storage after successful sync
        await _validatedTicketsBox.delete(ticket.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<List<Booking>> getOfflineBookings() async {
    try {
      return _offlineBookingsBox.values
          .map((json) => Booking.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Booking>> getValidatedTickets() async {
    try {
      return _validatedTicketsBox.values
          .map((json) => Booking.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  int get pendingSyncCount => _validatedTicketsBox.length;
}
