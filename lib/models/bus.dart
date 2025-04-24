class Bus {
  final String? id; // UUID - Nullable for creation
  final String ownerId; // UUID
  final String name;
  final int capacity;
  final String? type;
  final String? licensePlate; // Added
  final DateTime? createdAt; // Nullable as set by DB
  final DateTime? updatedAt; // Added

  Bus({
    this.id,
    required this.ownerId,
    required this.name,
    required this.capacity,
    this.type,
    this.licensePlate, // Added
    this.createdAt,
    this.updatedAt, // Added
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String?,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int,
      type: json['type'] as String?,
      licensePlate: json['license_plate'] as String?, // Added
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null, // Added
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id' is usually not sent for creation
        'owner_id': ownerId,
        'name': name,
        'capacity': capacity,
        'type': type,
        'license_plate': licensePlate, // Added
        // createdAt and updatedAt are handled by the DB
      };

  Bus copyWith({
    String? id,
    String? ownerId,
    String? name,
    int? capacity,
    String? type,
    String? licensePlate, // Added
    DateTime? createdAt,
    DateTime? updatedAt, // Added
  }) {
    return Bus(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      licensePlate: licensePlate ?? this.licensePlate, // Added
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // Added
    );
  }
}
