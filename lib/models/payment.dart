class Payment {
  final String id; // UUID
  final String bookingId; // UUID
  final String paymentProvider; // Updated from provider
  final String? providerTransactionId; // Updated from providerRef
  final double amount;
  final double? commissionAmount; // Nullable as it's generated in DB
  final String status; // 'initiated','success','failed', 'refunded'
  final DateTime transactionTimestamp; // Updated from transactionDate
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.paymentProvider, // Updated
    this.providerTransactionId, // Updated
    required this.amount,
    this.commissionAmount,
    required this.status,
    required this.transactionTimestamp, // Updated
    this.updatedAt,
  });

   factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      paymentProvider: json['payment_provider'] as String, // Updated key
      providerTransactionId: json['provider_transaction_id'] as String?, // Updated key
      amount: (json['amount'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num?)?.toDouble(), // Updated key, handle null
      status: json['status'] as String,
      transactionTimestamp: DateTime.parse(json['transaction_timestamp'] as String), // Updated key
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null, // Changed from processedAt
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'booking_id': bookingId,
      'payment_provider': paymentProvider, // Updated key
      'provider_transaction_id': providerTransactionId, // Updated key
      'amount': amount,
      // commissionAmount is generated in DB, not sent
      'status': status,
      'transaction_timestamp': transactionTimestamp.toIso8601String(), // Updated key
      // updatedAt is handled by the database
  };

  Payment copyWith({
    String? id,
    String? bookingId,
    String? paymentProvider, // Updated
    String? providerTransactionId, // Updated
    double? amount,
    double? commissionAmount,
    String? status,
    DateTime? transactionTimestamp, // Updated
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      paymentProvider: paymentProvider ?? this.paymentProvider, // Updated
      providerTransactionId: providerTransactionId ?? this.providerTransactionId, // Updated
      amount: amount ?? this.amount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      status: status ?? this.status,
      transactionTimestamp: transactionTimestamp ?? this.transactionTimestamp, // Updated
      updatedAt: updatedAt ?? this.updatedAt, // Changed from processedAt
    );
  }
} 