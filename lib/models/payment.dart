class Payment {
  final String id; // UUID
  final String bookingId; // UUID
  final String provider;
  final String? providerRef; // Nullable if not immediately available
  final double amount;
  final double commissionAmount;
  final String status; // 'initiated','success','failed', 'refunded'
  final DateTime transactionDate;
  final DateTime? processedAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.provider,
    this.providerRef,
    required this.amount,
    required this.commissionAmount,
    required this.status,
    required this.transactionDate,
    this.processedAt,
  });

   factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      bookingId: json['booking_id'],
      provider: json['provider'],
      providerRef: json['provider_ref'],
      amount: (json['amount'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      status: json['status'],
      transactionDate: DateTime.parse(json['transaction_date']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'booking_id': bookingId,
      'provider': provider,
      'provider_ref': providerRef,
      'amount': amount,
      'commission_amount': commissionAmount,
      'status': status,
      'transaction_date': transactionDate.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
  };

  Payment copyWith({
    String? id,
    String? bookingId,
    String? provider,
    String? providerRef,
    double? amount,
    double? commissionAmount,
    String? status,
    DateTime? transactionDate,
    DateTime? processedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      provider: provider ?? this.provider,
      providerRef: providerRef ?? this.providerRef,
      amount: amount ?? this.amount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      status: status ?? this.status,
      transactionDate: transactionDate ?? this.transactionDate,
      processedAt: processedAt ?? this.processedAt,
    );
  }
} 