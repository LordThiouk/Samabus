enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  refunded,
}

enum PaymentMethod {
  orangeMoney,
  wave,
  card,
}

class Passenger {
  final String fullName;
  final String cniNumber;
  final String? seatNumber;

  Passenger({
    required this.fullName,
    required this.cniNumber,
    this.seatNumber,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      fullName: json['full_name'],
      cniNumber: json['cni_number'],
      seatNumber: json['seat_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'cni_number': cniNumber,
      'seat_number': seatNumber,
    };
  }
}

class Booking {
  final String id;
  final String tripId;
  final String travelerId;
  final int numSeats;
  final double totalAmount;
  final String status;
  final DateTime bookedAt;

  Booking({
    required this.id,
    required this.tripId,
    required this.travelerId,
    required this.numSeats,
    required this.totalAmount,
    required this.status,
    required this.bookedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      tripId: json['trip_id'],
      travelerId: json['traveler_id'],
      numSeats: json['num_seats'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      bookedAt: DateTime.parse(json['booked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'traveler_id': travelerId,
        'num_seats': numSeats,
        'total_amount': totalAmount,
        'status': status,
        'booked_at': bookedAt.toIso8601String(),
      };

  Booking copyWith({
    String? id,
    String? tripId,
    String? travelerId,
    int? numSeats,
    double? totalAmount,
    String? status,
    DateTime? bookedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      travelerId: travelerId ?? this.travelerId,
      numSeats: numSeats ?? this.numSeats,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      bookedAt: bookedAt ?? this.bookedAt,
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'refunded':
        return BookingStatus.refunded;
      default:
        return BookingStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'orangeMoney':
        return PaymentMethod.orangeMoney;
      case 'wave':
        return PaymentMethod.wave;
      case 'card':
        return PaymentMethod.card;
      default:
        return PaymentMethod.orangeMoney;
    }
  }
}
