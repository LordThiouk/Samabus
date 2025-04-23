enum UserRole { traveler, bus_owner, admin }

class User {
  final String id; // Corresponds to Supabase Auth user ID (UUID)
  final UserRole role;
  final DateTime createdAt;
  // Email and phone are typically managed via Auth/Profile

  // Profile information (denormalized or fetched separately)
  final String? fullName;
  final String? phoneNumber; // Fetched from Profile
  final String? companyName; // Fetched from Profile (bus_owner only)
  final bool? isApproved;    // Fetched from Profile (bus_owner only)
  final bool isVerified;     // Derived from Supabase Auth state

  User({
    required this.id,
    required this.role,
    required this.createdAt,
    required this.isVerified,
    this.fullName,
    this.phoneNumber,
    this.companyName,
    this.isApproved,
  });

  // Placeholder fromJson - needs actual profile data integration
  factory User.fromJson(Map<String, dynamic> json, Map<String, dynamic>? profileJson) {
    // This needs careful implementation later. It should combine auth user data
    // with data fetched from the 'profiles' table.
    return User(
      id: json['id'], // Assuming 'id' comes from the joined auth user data
      role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last == json['role'], // Assuming 'role' comes from public.users table
            orElse: () => UserRole.traveler),
      createdAt: DateTime.parse(json['created_at']), // Assuming 'created_at' from public.users
      isVerified: json['email_confirmed_at'] != null || json['phone_confirmed_at'] != null, // Example from auth user data
      fullName: profileJson?['full_name'],
      phoneNumber: profileJson?['phone'],
      companyName: profileJson?['company_name'],
      isApproved: profileJson?['approved'],
    );
  }

  // toJson might not be needed if User is primarily read-only client-side
  // Or it might only serialize fields relevant for updates (e.g., profile updates)
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.toString().split('.').last,
    'created_at': createdAt.toIso8601String(),
    // Profile fields are usually updated via a separate Profile model/endpoint
  };

  // copyWith for immutability
  User copyWith({
    String? id,
    UserRole? role,
    DateTime? createdAt,
    bool? isVerified,
    String? fullName,
    String? phoneNumber,
    String? companyName,
    bool? isApproved,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      companyName: companyName ?? this.companyName,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
