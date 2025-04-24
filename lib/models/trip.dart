class Trip {
  final String? id; // UUID - Nullable for creation
  final String busId; // UUID
  final String departureCity;
  final String destinationCity;
  final DateTime departureTimestamp; // Renamed from departureTime
  final DateTime? arrivalTimestamp;   // Renamed from arrivalTime
  final double pricePerSeat;       // Renamed from price
  // totalSeats and availableSeats are derived, not direct DB fields
  // final int totalSeats;
  // final int availableSeats;
  final String status; // 'scheduled', 'departed', 'arrived', 'cancelled'
  final DateTime? createdAt; // Nullable as set by DB
  final DateTime? updatedAt; // Added

  // Add derived fields if needed for display
  final int? totalSeats; // Example: fetched separately or via view
  final int? availableSeats; // Example: fetched separately or via view

  Trip({
    this.id,
    required this.busId,
    required this.departureCity,
    required this.destinationCity,
    required this.departureTimestamp, // Renamed
    this.arrivalTimestamp,       // Renamed
    required this.pricePerSeat,       // Renamed
    // required this.totalSeats,
    // required this.availableSeats,
    required this.status,
    this.createdAt,
    this.updatedAt, // Added
    // Pass derived fields if available
    this.totalSeats,
    this.availableSeats,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String?,
      busId: json['bus_id'] as String,
      departureCity: json['departure_city'] as String,
      destinationCity: json['destination_city'] as String,
      departureTimestamp: DateTime.parse(json['departure_timestamp'] as String), // Renamed key
      arrivalTimestamp: json['arrival_timestamp'] != null
          ? DateTime.parse(json['arrival_timestamp'] as String)
          : null, // Renamed key
      pricePerSeat: (json['price_per_seat'] as num).toDouble(), // Renamed key
      status: json['status'] as String, // Ensure 'arrived' is handled if needed
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null, // Added
      // Populate derived fields if they come from the JSON (e.g., from a view)
      totalSeats: json['total_seats'] as int?, // Example
      availableSeats: json['available_seats'] as int?, // Example
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id' usually not sent for creation
        'bus_id': busId,
        'departure_city': departureCity,
        'destination_city': destinationCity,
        'departure_timestamp': departureTimestamp.toIso8601String(), // Renamed
        'arrival_timestamp': arrivalTimestamp?.toIso8601String(), // Renamed
        'price_per_seat': pricePerSeat, // Renamed
        'status': status,
        // createdAt and updatedAt handled by DB
        // totalSeats and availableSeats are not sent back
      };

  Trip copyWith({
    String? id,
    String? busId,
    String? departureCity,
    String? destinationCity,
    DateTime? departureTimestamp, // Renamed
    DateTime? arrivalTimestamp,   // Renamed
    double? pricePerSeat,       // Renamed
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt, // Added
    int? totalSeats,
    int? availableSeats,
  }) {
    return Trip(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      departureTimestamp: departureTimestamp ?? this.departureTimestamp, // Renamed
      arrivalTimestamp: arrivalTimestamp ?? this.arrivalTimestamp,    // Renamed
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,              // Renamed
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // Added
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
    );
  }
}
