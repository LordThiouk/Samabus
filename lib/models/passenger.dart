class Passenger {
  final String id; // UUID
  final String bookingId; // UUID
  final String name;
  final String cni;
  final String? qrCode; // Nullable as it might be generated after booking

  Passenger({
    required this.id,
    required this.bookingId,
    required this.name,
    required this.cni,
    this.qrCode,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      bookingId: json['booking_id'],
      name: json['name'],
      cni: json['cni'],
      qrCode: json['qr_code'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'name': name,
        'cni': cni,
        'qr_code': qrCode,
      };

  Passenger copyWith({
    String? id,
    String? bookingId,
    String? name,
    String? cni,
    String? qrCode,
  }) {
    return Passenger(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      name: name ?? this.name,
      cni: cni ?? this.cni,
      qrCode: qrCode ?? this.qrCode,
    );
  }
} 