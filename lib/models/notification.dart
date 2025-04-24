class Notification {
  final String? id; // UUID - Nullable for creation
  final String userId; // UUID
  final String type; // e.g., 'booking_confirmation', 'trip_reminder'
  final String channel; // 'email', 'sms', 'push'
  final String? content;
  final DateTime? sentAt; // Nullable as set by DB
  final DateTime? readAt; // Nullable

  Notification({
    this.id,
    required this.userId,
    required this.type,
    required this.channel,
    this.content,
    this.sentAt,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      channel: json['channel'] as String,
      content: json['content'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        // 'id' usually not sent for creation
        'user_id': userId,
        'type': type,
        'channel': channel,
        'content': content,
        // sentAt handled by DB
        'read_at': readAt?.toIso8601String(), // Only send readAt if updating
      };

  Notification copyWith({
    String? id,
    String? userId,
    String? type,
    String? channel,
    String? content,
    DateTime? sentAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
    );
  }
} 