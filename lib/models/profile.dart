// Represents data stored in the public.profiles table
class Profile {
  final String userId; // Foreign key to users.id
  final String? fullName;
  final String? phone;
  final String? companyName;
  final bool approved; // Defaults to false in DB
  final DateTime? approvalDate;

  Profile({
    required this.userId,
    this.fullName,
    this.phone,
    this.companyName,
    required this.approved,
    this.approvalDate,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      companyName: json['company_name'],
      approved: json['approved'] ?? false, // Ensure default
      approvalDate: json['approval_date'] != null
          ? DateTime.parse(json['approval_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'company_name': companyName,
        'approved': approved,
        'approval_date': approvalDate?.toIso8601String(),
      };

  Profile copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? companyName,
    bool? approved,
    DateTime? approvalDate,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      companyName: companyName ?? this.companyName,
      approved: approved ?? this.approved,
      approvalDate: approvalDate ?? this.approvalDate,
    );
  }
} 