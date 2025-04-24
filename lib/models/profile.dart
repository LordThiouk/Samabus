// Represents data stored in the public.profiles table
class Profile {
  final String userId; // Foreign key to auth.users.id
  final String? fullName;
  final String? phone;
  final String? companyName;
  final bool isApproved; // Renamed from approved
  final DateTime? approvalDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.userId,
    this.fullName,
    this.phone,
    this.companyName,
    required this.isApproved, // Renamed
    this.approvalDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      companyName: json['company_name'] as String?,
      isApproved: json['is_approved'] as bool? ?? false, // Updated key & ensure default
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null, // Added
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null, // Added
    );
  }

  Map<String, dynamic> toJson() => {
        // userId is the PK and typically not included directly in updates unless necessary
        'full_name': fullName,
        'phone': phone,
        'company_name': companyName,
        'is_approved': isApproved, // Updated key
        'approval_date': approvalDate?.toIso8601String(),
        // createdAt and updatedAt are usually handled by the database
      };

  Profile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? companyName,
    bool? isApproved, // Renamed
    DateTime? approvalDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      isApproved: isApproved ?? this.isApproved, // Renamed
      approvalDate: approvalDate ?? this.approvalDate,
      createdAt: createdAt ?? this.createdAt, // Added
      updatedAt: updatedAt ?? this.updatedAt, // Added
    );
  }
} 