enum TransporteurStatus {
  pending,
  approved,
  rejected,
}

class Transporteur {
  final String id;
  final String userId;
  final String companyName;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final TransporteurStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final List<String>? documentUrls;

  Transporteur({
    required this.id,
    required this.userId,
    required this.companyName,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.address,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.documentUrls,
  });

  factory Transporteur.fromJson(Map<String, dynamic> json) {
    return Transporteur(
      id: json['id'],
      userId: json['user_id'],
      companyName: json['company_name'],
      contactPerson: json['contact_person'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      address: json['address'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      approvedBy: json['approved_by'],
      documentUrls: json['document_urls'] != null 
          ? List<String>.from(json['document_urls']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'contact_person': contactPerson,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'document_urls': documentUrls,
    };
  }

  static TransporteurStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return TransporteurStatus.pending;
      case 'approved':
        return TransporteurStatus.approved;
      case 'rejected':
        return TransporteurStatus.rejected;
      default:
        return TransporteurStatus.pending;
    }
  }
}
