class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int createdAt;
  final String? defaultAddressId;
  final int loyaltyPoints;
  final String role;
  final bool isBlocked;
  final String? managedOutletId;
  final Map<String, dynamic> fcmTokens;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    this.defaultAddressId,
    this.loyaltyPoints = 0,
    this.role = 'customer',
    this.isBlocked = false,
    this.managedOutletId,
    this.fcmTokens = const {},
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      name: (map['name'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      defaultAddressId: map['defaultAddressId'] as String?,
      loyaltyPoints: (map['loyaltyPoints'] as num?)?.toInt() ?? 0,
      role: (map['role'] ?? 'customer') as String,
      isBlocked: map['isBlocked'] == true,
      managedOutletId: map['managedOutletId'] as String?,
      fcmTokens: Map<String, dynamic>.from(map['fcmTokens'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': createdAt,
        'defaultAddressId': defaultAddressId,
        'loyaltyPoints': loyaltyPoints,
        'role': role,
        'isBlocked': isBlocked,
        'managedOutletId': managedOutletId,
        'fcmTokens': fcmTokens,
      };

  UserModel copyWith({String? name, String? phone, String? defaultAddressId}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      loyaltyPoints: loyaltyPoints,
      role: role,
      isBlocked: isBlocked,
      managedOutletId: managedOutletId,
      fcmTokens: fcmTokens,
    );
  }
}
