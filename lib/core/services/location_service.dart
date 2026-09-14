import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DetectedLocation {
  final double lat;
  final double lng;
  final String address;
  final String line1;
  final String area;
  final String city;
  final String state;
  final String pincode;

  const DetectedLocation({
    required this.lat,
    required this.lng,
    required this.address,
    this.line1 = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });
}

enum LocationFail { denied, deniedForever, gpsOff, failed }

class LocationDetectResult {
  final DetectedLocation? location;
  final LocationFail? fail;

  const LocationDetectResult.ok(this.location) : fail = null;
  const LocationDetectResult.fail(this.fail) : location = null;
}

class LocationService {
  Future<LocationDetectResult> detect() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return const LocationDetectResult.fail(LocationFail.gpsOff);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationDetectResult.fail(LocationFail.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationDetectResult.fail(LocationFail.denied);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      var address = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      var line1 = '';
      var area = '';
      var city = '';
      var state = '';
      var pincode = '';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          final p = marks.first;
          line1 = [p.name, p.street].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).toSet().join(', ');
          area = (p.subLocality ?? '').trim();
          city = (p.locality ?? p.subAdministrativeArea ?? '').trim();
          state = (p.administrativeArea ?? '').trim();
          pincode = (p.postalCode ?? '').trim();
          address = [
            line1,
            area,
            city,
            state,
            pincode,
          ].where((e) => e.isNotEmpty).join(', ');
        }
      } catch (_) {}
      return LocationDetectResult.ok(DetectedLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        address: address,
        line1: line1,
        area: area,
        city: city,
        state: state,
        pincode: pincode,
      ));
    } catch (_) {
      return const LocationDetectResult.fail(LocationFail.failed);
    }
  }

  Future<DetectedLocation?> fromAddress(String query) async {
    try {
      final list = await locationFromAddress(query);
      if (list.isEmpty) return null;
      final loc = list.first;
      return DetectedLocation(lat: loc.latitude, lng: loc.longitude, address: query.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> openGpsSettings() => Geolocator.openLocationSettings();
}
