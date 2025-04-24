import 'passenger.dart'; // Import Passenger model
import 'enums/booking_status.dart'; // Import enum
import 'enums/payment_method.dart'; // Import enum

class Booking {
  final String? id;
  final String tripId;
  final String userId;
  final List<Passenger> passengers;
  final double totalAmount;
  final BookingStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentId;
  final DateTime? bookedAt;
  final DateTime? updatedAt;
  final DateTime? validatedDateTime;
  final String? validatedBy;
  final String? qrCode;
  final double? platformFee;

  Booking({
    this.id,
    required this.tripId,
    required this.userId,
    required this.passengers,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentId,
    this.bookedAt,
    this.updatedAt,
    this.validatedDateTime,
    this.validatedBy,
    this.qrCode,
    this.platformFee,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Helper to parse enum safely
    T? _parseEnum<T>(List<T> values, String? value) {
      if (value == null) return null;
      try {
        return values.firstWhere((e) => e.toString().split('.').last == value);
      } catch (e) {
        return null; // Or throw error / return default
      }
    }

    return Booking(
      id: json['id'] as String?,
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String,
      passengers: (json['passengers'] as List<dynamic>? ?? [])
          .map((pJson) => Passenger.fromJson(pJson as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: _parseEnum(BookingStatus.values, json['status'] as String?) ?? BookingStatus.pending,
      paymentMethod: _parseEnum(PaymentMethod.values, json['payment_method'] as String?),
      paymentId: json['payment_id'] as String?,
      platformFee: (json['platform_fee'] as num?)?.toDouble(),
      bookedAt: json['booking_date_time'] != null
          ? DateTime.parse(json['booking_date_time'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      validatedDateTime: json['validated_date_time'] != null
          ? DateTime.parse(json['validated_date_time'] as String)
          : null,
      validatedBy: json['validated_by'] as String?,
      qrCode: json['qr_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'user_id': userId,
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'total_amount': totalAmount,
        'status': status.toString().split('.').last,
        'payment_method': paymentMethod?.toString().split('.').last,
        'payment_id': paymentId,
        'platform_fee': platformFee,
        'booking_date_time': bookedAt?.toIso8601String(),
        'validated_date_time': validatedDateTime?.toIso8601String(),
        'validated_by': validatedBy,
        'qr_code': qrCode,
      };

  Booking copyWith({
    String? id,
    String? tripId,
    String? userId,
    List<Passenger>? passengers,
    double? totalAmount,
    BookingStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentId,
    DateTime? bookedAt,
    DateTime? updatedAt,
    DateTime? validatedDateTime,
    String? validatedBy,
    String? qrCode,
    double? platformFee,
  }) {
    return Booking(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      passengers: passengers ?? this.passengers,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      bookedAt: bookedAt ?? this.bookedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validatedDateTime: validatedDateTime ?? this.validatedDateTime,
      validatedBy: validatedBy ?? this.validatedBy,
      qrCode: qrCode ?? this.qrCode,
      platformFee: platformFee ?? this.platformFee,
    );
  }
}
