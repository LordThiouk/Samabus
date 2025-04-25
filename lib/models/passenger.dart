/// Represents a passenger associated with a booking.
class Passenger {
  final String id; // Could be UUID generated locally or by backend
  final String bookingId; // Foreign key to the Booking
  final String fullName;
  final String cni; // Carte Nationale d'Identité (National ID Card number)
  final String? qrCodeData; // Data embedded in the QR code for this passenger

  Passenger({
    required this.id,
    required this.bookingId,
    required this.fullName,
    required this.cni,
    this.qrCodeData,
  });

  // Factory constructor for creating a new Passenger instance from a map (e.g., from JSON).
  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      fullName: json['full_name'] as String,
      cni: json['cni'] as String,
      qrCodeData: json['qr_code_data'] as String?,
    );
  }

  // Method for converting a Passenger instance into a map (e.g., for JSON serialization).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'full_name': fullName,
      'cni': cni,
      'qr_code_data': qrCodeData,
    };
  }

  @override
  String toString() {
    return 'Passenger{id: $id, bookingId: $bookingId, fullName: $fullName, cni: $cni, qrCodeData: $qrCodeData}';
  }

  // Optional: Implement equality operator and hashCode if needed for comparisons or use in Sets/Maps.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Passenger &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bookingId == other.bookingId &&
          fullName == other.fullName &&
          cni == other.cni;

  @override
  int get hashCode =>
      id.hashCode ^ bookingId.hashCode ^ fullName.hashCode ^ cni.hashCode;
} 