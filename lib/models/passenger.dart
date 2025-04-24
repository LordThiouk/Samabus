class Passenger {
  final String? id; // UUID - Nullable for creation
  final String bookingId; // UUID
  final String? seatNumber; // Added
  final String fullName; // Renamed from name
  final String cni; // Needs secure handling
  final String? qrCodeData; // Renamed from qrCode
  final DateTime? createdAt; // Added

  Passenger({
    this.id,
    required this.bookingId,
    this.seatNumber, // Added
    required this.fullName, // Renamed
    required this.cni,
    this.qrCodeData, // Renamed
    this.createdAt, // Added
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] as String?,
      bookingId: json['booking_id'] as String,
      seatNumber: json['seat_number'] as String?, // Added
      fullName: json['full_name'] as String, // Renamed key
      cni: json['cni'] as String,
      qrCodeData: json['qr_code_data'] as String?, // Renamed key
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null, // Added
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id' usually not sent for creation
        'booking_id': bookingId,
        'seat_number': seatNumber, // Added
        'full_name': fullName, // Renamed
        'cni': cni,
        'qr_code_data': qrCodeData, // Renamed
        // createdAt handled by DB
      };

  Passenger copyWith({
    String? id,
    String? bookingId,
    String? seatNumber, // Added
    String? fullName, // Renamed
    String? cni,
    String? qrCodeData, // Renamed
    DateTime? createdAt, // Added
  }) {
    return Passenger(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      seatNumber: seatNumber ?? this.seatNumber, // Added
      fullName: fullName ?? this.fullName, // Renamed
      cni: cni ?? this.cni,
      qrCodeData: qrCodeData ?? this.qrCodeData, // Renamed
      createdAt: createdAt ?? this.createdAt, // Added
    );
  }
} 