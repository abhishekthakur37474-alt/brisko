import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/geo.dart';
import '../addresses/address_model.dart';
import 'outlet_model.dart';

final outletsProvider = StreamProvider<List<OutletModel>>((ref) {
  return FirebaseService.instance.ref('outlets').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <OutletModel>[];
    return val.entries
        .map((e) => OutletModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .where((o) => o.isActive)
        .toList();
  });
});

class LocationState {
  final AddressModel? address;
  final OutletModel? outlet;
  final bool loading;
  final String? error;
  final bool noCoverage;

  const LocationState({
    this.address,
    this.outlet,
    this.loading = false,
    this.error,
    this.noCoverage = false,
  });

  LocationState copyWith({
    AddressModel? address,
    OutletModel? outlet,
    bool? loading,
    String? error,
    bool? noCoverage,
    bool clearError = false,
    bool clearOutlet = false,
  }) {
    return LocationState(
      address: address ?? this.address,
      outlet: clearOutlet ? null : (outlet ?? this.outlet),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      noCoverage: noCoverage ?? this.noCoverage,
    );
  }
}

final locationControllerProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(ref)..restore();
});

class LocationController extends StateNotifier<LocationState> {
  LocationController(this.ref) : super(const LocationState());
  final Ref ref;
  final _location = LocationService();

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('loc_lat');
    final lng = prefs.getDouble('loc_lng');
    final address = prefs.getString('loc_address');
    if (lat == null || lng == null || address == null) return;
    await applyCoordinates(lat: lat, lng: lng, fullAddress: address, label: prefs.getString('loc_label') ?? 'Saved');
  }

  Future<void> _persist(AddressModel address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('loc_lat', address.lat);
    await prefs.setDouble('loc_lng', address.lng);
    await prefs.setString('loc_address', address.fullAddress);
    await prefs.setString('loc_label', address.label);
  }

  OutletModel? matchOutlet(double lat, double lng, List<OutletModel> outlets) {
    final matches = <(OutletModel, double)>[];
    for (final o in outlets) {
      final d = haversineKm(lat, lng, o.lat, o.lng);
      if (d <= o.serviceRadiusKm) matches.add((o, d));
    }
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.$2.compareTo(b.$2));
    return matches.first.$1;
  }

  Future<void> detect() async {
    state = state.copyWith(loading: true, clearError: true, noCoverage: false);
    final loc = await _location.detect();
    if (loc == null) {
      state = state.copyWith(loading: false, error: 'Location permission denied. Enter address manually.');
      return;
    }
    await applyCoordinates(lat: loc.lat, lng: loc.lng, fullAddress: loc.address, label: 'Current');
  }

  Future<void> applyCoordinates({
    required double lat,
    required double lng,
    required String fullAddress,
    String label = 'Home',
    String? id,
  }) async {
    final outlets = await ref.read(outletsProvider.future);
    final outlet = matchOutlet(lat, lng, outlets);
    final address = AddressModel(
      id: id ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      fullAddress: fullAddress,
      lat: lat,
      lng: lng,
      outletId: outlet?.id,
      isDefault: true,
    );
    if (outlet == null) {
      state = LocationState(address: address, loading: false, noCoverage: true, outlet: null);
      return;
    }
    await _persist(address);
    state = LocationState(address: address, outlet: outlet, loading: false);
  }

  void setFromSaved(AddressModel address, List<OutletModel> outlets) {
    final outlet = address.outletId == null
        ? matchOutlet(address.lat, address.lng, outlets)
        : outlets.where((o) => o.id == address.outletId).firstOrNull ??
            matchOutlet(address.lat, address.lng, outlets);
    _persist(address);
    state = LocationState(
      address: address,
      outlet: outlet,
      noCoverage: outlet == null,
    );
  }
}
