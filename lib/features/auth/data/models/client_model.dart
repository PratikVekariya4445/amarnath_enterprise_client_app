/// Data model representing a Client in Firebase Realtime Database.
class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.companyName,
    this.address,
    this.email,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String mobile;
  final String companyName;
  final String? address;
  final String? email;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  factory ClientModel.fromJson(Map<dynamic, dynamic> json, [String id = '']) {
    final rawId = json['id'] ?? json['uid'] ?? json['clientId'];
    final resolvedId = (rawId is String && rawId.trim().isNotEmpty)
        ? rawId.trim()
        : (id.trim().isNotEmpty
            ? id
            : 'client_${DateTime.now().millisecondsSinceEpoch}');

    final name = json['name']?.toString().trim() ??
        json['clientName']?.toString().trim() ??
        json['fullName']?.toString().trim() ??
        '';

    final mobile = json['mobile']?.toString().trim() ??
        json['phone']?.toString().trim() ??
        json['phoneNumber']?.toString().trim() ??
        json['mobileNumber']?.toString().trim() ??
        '';

    final companyName = json['companyName']?.toString().trim() ??
        json['shopName']?.toString().trim() ??
        json['businessName']?.toString().trim() ??
        '';

    final address = json['address']?.toString().trim();
    final email = json['email']?.toString().trim();

    bool isActive = false;
    final rawActive = json['isActive'] ?? json['active'] ?? json['status'];
    if (rawActive is bool) {
      isActive = rawActive;
    } else if (rawActive is String) {
      final lower = rawActive.toLowerCase();
      isActive = lower == 'true' || lower == 'approved' || lower == 'active';
    }

    String createdAt = DateTime.now().toIso8601String();
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is int) {
      createdAt =
          DateTime.fromMillisecondsSinceEpoch(rawCreatedAt).toIso8601String();
    } else if (rawCreatedAt is String && rawCreatedAt.trim().isNotEmpty) {
      createdAt = rawCreatedAt.trim();
    }

    String updatedAt = createdAt;
    final rawUpdatedAt = json['updatedAt'];
    if (rawUpdatedAt is int) {
      updatedAt =
          DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt).toIso8601String();
    } else if (rawUpdatedAt is String && rawUpdatedAt.trim().isNotEmpty) {
      updatedAt = rawUpdatedAt.trim();
    }

    return ClientModel(
      id: resolvedId,
      name: name,
      mobile: mobile,
      companyName: companyName,
      address: (address != null && address.isNotEmpty) ? address : null,
      email: (email != null && email.isNotEmpty) ? email : null,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'companyName': companyName,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (email != null && email!.isNotEmpty) 'email': email,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
