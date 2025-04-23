import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/bus.dart';
import '../services/supabase_service.dart';

class TripProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Trip> _searchResults = [];
  Trip? _selectedTrip;
  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Trip> get searchResults => _searchResults;
  Trip? get selectedTrip => _selectedTrip;
  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> searchTrips({
    required String departureCity,
    required String arrivalCity,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.getTrips(
        departureCity: departureCity,
        arrivalCity: arrivalCity,
        date: date,
      );
      
      _searchResults = response.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTrip(Trip trip) {
    _selectedTrip = trip;
    notifyListeners();
  }

  Future<void> loadBuses(String transporteurId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.getBuses(transporteurId);
      _buses = response.map((json) => Bus.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      _buses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBus({
    required String transporteurId,
    required String name,
    required int capacity,
    String? busType,
    String? registrationNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final busData = {
        'transporteur_id': transporteurId,
        'name': name,
        'capacity': capacity,
        'bus_type': busType,
        'registration_number': registrationNumber,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseService.createBus(busData: busData);
      final newBus = Bus.fromJson(response);
      
      _buses.add(newBus);
      
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

  Future<bool> createTrip({
    required String transporteurId,
    required String busId,
    required String departureCity,
    required String arrivalCity,
    required DateTime departureDateTime,
    DateTime? arrivalDateTime,
    required double fare,
    required int totalSeats,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tripData = {
        'transporteur_id': transporteurId,
        'bus_id': busId,
        'departure_city': departureCity,
        'arrival_city': arrivalCity,
        'departure_date_time': departureDateTime.toIso8601String(),
        'arrival_date_time': arrivalDateTime?.toIso8601String(),
        'fare': fare,
        'total_seats': totalSeats,
        'available_seats': totalSeats,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabaseService.createTrip(tripData: tripData);
      
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
