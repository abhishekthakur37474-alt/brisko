class OutletModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double serviceRadiusKm;
  final bool isActive;
  final String contactNumber;
  final String openTime;
  final String closeTime;

  const OutletModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.serviceRadiusKm,
    required this.isActive,
    required this.contactNumber,
    required this.openTime,
    required this.closeTime,
  });

  factory OutletModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return OutletModel(
      id: id,
      name: (map['name'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      serviceRadiusKm: (map['serviceRadiusKm'] as num?)?.toDouble() ?? 5,
      isActive: map['isActive'] != false,
      contactNumber: (map['contactNumber'] ?? '') as String,
      openTime: (map['openTime'] ?? '11:00') as String,
      closeTime: (map['closeTime'] ?? '23:00') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'serviceRadiusKm': serviceRadiusKm,
        'isActive': isActive,
        'contactNumber': contactNumber,
        'openTime': openTime,
        'closeTime': closeTime,
      };
}
