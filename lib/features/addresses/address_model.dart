class AddressModel {
  final String id;
  final String label;
  final String receiverName;
  final String receiverPhone;
  final String fullAddress;
  final double lat;
  final double lng;
  final String? outletId;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.label,
    this.receiverName = '',
    this.receiverPhone = '',
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.outletId,
    this.isDefault = false,
  });

  factory AddressModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return AddressModel(
      id: id,
      label: (map['label'] ?? 'Home') as String,
      receiverName: (map['receiverName'] ?? '') as String,
      receiverPhone: (map['receiverPhone'] ?? '') as String,
      fullAddress: (map['fullAddress'] ?? '') as String,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      outletId: map['outletId'] as String?,
      isDefault: map['isDefault'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'fullAddress': fullAddress,
        'lat': lat,
        'lng': lng,
        'outletId': outletId,
        'isDefault': isDefault,
      };

  AddressModel copyWith({
    String? outletId,
    bool? isDefault,
    String? label,
    String? receiverName,
    String? receiverPhone,
    String? fullAddress,
  }) {
    return AddressModel(
      id: id,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      fullAddress: fullAddress ?? this.fullAddress,
      lat: lat,
      lng: lng,
      outletId: outletId ?? this.outletId,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
