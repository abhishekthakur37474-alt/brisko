import '../../core/utils/store_hours.dart';

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
  final String googleMapsUrl;

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
    this.googleMapsUrl = '',
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
      googleMapsUrl: (map['googleMapsUrl'] ?? '') as String,
    );
  }

  String get mapsLink {
    final url = googleMapsUrl.trim();
    if (url.isNotEmpty) return url;
    if (lat != 0 || lng != 0) {
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }
    return '';
  }

  bool isOpenAt(DateTime now) => StoreHours.isOpenAt(now, openTime, closeTime);

  DateTime nextOpeningAt(DateTime now) => StoreHours.nextOpeningAt(now, openTime, closeTime);

  String get hoursLabel => '${StoreHours.format12h(openTime)} – ${StoreHours.format12h(closeTime)}';

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
        'googleMapsUrl': googleMapsUrl,
      };
}
