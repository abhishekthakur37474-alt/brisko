import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DetectedLocation {
  final double lat;
  final double lng;
  final String address;

  const DetectedLocation({required this.lat, required this.lng, required this.address});
}

class LocationService {
  Future<DetectedLocation?> detect() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    var address = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        address = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (_) {}
    return DetectedLocation(lat: pos.latitude, lng: pos.longitude, address: address);
  }
}
