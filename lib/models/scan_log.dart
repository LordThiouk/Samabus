// Represents an offline scan event, stored locally and synced later
class ScanLog {
  final String? id; // UUID - Nullable for creation, assigned by client?
  final String tripId; // UUID
  final String scannerUserId; // Renamed from validatorId
  // scannedDataType and scannedValue are client-side representations
  // final String scannedDataType; // 'qr_code', 'cni' - Not in DB schema
  // final String scannedValue; // Not in DB schema
  final String scannedData; // Added - Represents qr_code_data or cni from DB
  final String validationStatus; // Renamed from bool, values: 'valid', 'invalid', 'duplicate'
  final String? deviceId; // Added
  final DateTime scannedAt; // Device timestamp
  final bool isSynced; // Renamed from synced
  final DateTime? syncedAt; // Server timestamp when synced

  ScanLog({
    this.id,
    required this.tripId,
    required this.scannerUserId, // Renamed
    required this.scannedData, // Added
    required this.validationStatus, // Renamed
    this.deviceId, // Added
    required this.scannedAt,
    required this.isSynced, // Renamed
    this.syncedAt,
    // Remove client-side only fields from constructor if not needed
    // required this.scannedDataType,
    // required this.scannedValue,
  });

   factory ScanLog.fromJson(Map<String, dynamic> json) {
    return ScanLog(
      id: json['id'] as String?,
      tripId: json['trip_id'] as String,
      scannerUserId: json['scanner_user_id'] as String, // Renamed key
      scannedData: json['scanned_data'] as String, // Added key
      validationStatus: json['validation_status'] as String, // Renamed key, expect TEXT
      deviceId: json['device_id'] as String?, // Added key
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      isSynced: json['is_synced'] as bool? ?? false, // Renamed key
      syncedAt: json['synced_at'] != null ? DateTime.parse(json['synced_at'] as String) : null,
      // Parse scanned_data into type/value if needed client-side
      // scannedDataType: ..., 
      // scannedValue: ..., 
    );
  }

   Map<String, dynamic> toJson() => {
        'id': id, // Send client-generated ID
        'trip_id': tripId,
        'scanner_user_id': scannerUserId, // Renamed
        'scanned_data': scannedData, // Added
        'validation_status': validationStatus, // Renamed
        'device_id': deviceId, // Added
        'scanned_at': scannedAt.toIso8601String(),
        'is_synced': isSynced, // Renamed
        'synced_at': syncedAt?.toIso8601String(),
      };

  ScanLog copyWith({
    String? id,
    String? tripId,
    String? scannerUserId, // Renamed
    String? scannedData, // Added
    String? validationStatus, // Renamed
    String? deviceId, // Added
    DateTime? scannedAt,
    bool? isSynced, // Renamed
    DateTime? syncedAt,
  }) {
    return ScanLog(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      scannerUserId: scannerUserId ?? this.scannerUserId, // Renamed
      scannedData: scannedData ?? this.scannedData, // Added
      validationStatus: validationStatus ?? this.validationStatus, // Renamed
      deviceId: deviceId ?? this.deviceId, // Added
      scannedAt: scannedAt ?? this.scannedAt,
      isSynced: isSynced ?? this.isSynced, // Renamed
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
} 