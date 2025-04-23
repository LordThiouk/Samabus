class Trip {
  final String id; // UUID
  final String busId; // UUID
  final String departureCity;
  final String destinationCity;
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String status; // 'scheduled', 'departed', 'completed', 'cancelled'
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.busId,
    required this.departureCity,
    required this.destinationCity,
    required this.departureTime,
    this.arrivalTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      busId: json['bus_id'],
      departureCity: json['departure_city'],
      destinationCity: json['destination_city'],
      departureTime: DateTime.parse(json['departure_time']),
      arrivalTime: json['arrival_time'] != null
          ? DateTime.parse(json['arrival_time'])
          : null,
      // Ensure price is parsed correctly (numeric from DB might be int or double)
      price: (json['price'] as num).toDouble(),
      totalSeats: json['total_seats'],
      availableSeats: json['available_seats'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bus_id': busId,
        'departure_city': departureCity,
        'destination_city': destinationCity,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime?.toIso8601String(),
        'price': price,
        'total_seats': totalSeats,
        'available_seats': availableSeats,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  Trip copyWith({
    String? id,
    String? busId,
    String? departureCity,
    String? destinationCity,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? price,
    int? totalSeats,
    int? availableSeats,
    String? status,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      price: price ?? this.price,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
