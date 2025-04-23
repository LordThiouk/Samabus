class Bus {
  final String id; // UUID
  final String ownerId; // UUID
  final String name;
  final int capacity;
  final String? type;
  final DateTime createdAt;

  Bus({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.capacity,
    this.type,
    required this.createdAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      capacity: json['capacity'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'capacity': capacity,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };

  Bus copyWith({
    String? id,
    String? ownerId,
    String? name,
    int? capacity,
    String? type,
    DateTime? createdAt,
  }) {
    return Bus(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
