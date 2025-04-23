class ScanLog {
  final String id; // UUID
  final String tripId; // UUID
  final String validatorId; // UUID
  final String scannedDataType; // 'qr_code', 'cni'
  final String scannedValue;
  final bool validationStatus;
  final DateTime scannedAt; // Device timestamp
  final bool synced;
  final DateTime? syncedAt; // Server timestamp when synced

  ScanLog({
    required this.id,
    required this.tripId,
    required this.validatorId,
    required this.scannedDataType,
    required this.scannedValue,
    required this.validationStatus,
    required this.scannedAt,
    required this.synced,
    this.syncedAt,
  });

   factory ScanLog.fromJson(Map<String, dynamic> json) {
    return ScanLog(
      id: json['id'],
      tripId: json['trip_id'],
      validatorId: json['validator_id'],
      scannedDataType: json['scanned_data_type'],
      scannedValue: json['scanned_value'],
      validationStatus: json['validation_status'],
      scannedAt: DateTime.parse(json['scanned_at']),
      synced: json['synced'] ?? false,
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at']) : null,
    );
  }

   Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'validator_id': validatorId,
        'scanned_data_type': scannedDataType,
        'scanned_value': scannedValue,
        'validation_status': validationStatus,
        'scanned_at': scannedAt.toIso8601String(),
        'synced': synced,
        'synced_at': syncedAt?.toIso8601String(),
      };

  ScanLog copyWith({
    String? id,
    String? tripId,
    String? validatorId,
    String? scannedDataType,
    String? scannedValue,
    bool? validationStatus,
    DateTime? scannedAt,
    bool? synced,
    DateTime? syncedAt,
  }) {
    return ScanLog(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      validatorId: validatorId ?? this.validatorId,
      scannedDataType: scannedDataType ?? this.scannedDataType,
      scannedValue: scannedValue ?? this.scannedValue,
      validationStatus: validationStatus ?? this.validationStatus,
      scannedAt: scannedAt ?? this.scannedAt,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
} 