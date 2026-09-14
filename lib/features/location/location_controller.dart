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

enum LocationUiStatus { idle, loading, detected, denied, deniedForever, gpsOff, failed, noCoverage }

class LocationState {
  final AddressModel? address;
  final OutletModel? outlet;
  final bool loading;
  final bool restoring;
  final String? error;
  final bool noCoverage;
  final LocationUiStatus status;

  const LocationState({
    this.address,
    this.outlet,
    this.loading = false,
    this.restoring = false,
    this.error,
    this.noCoverage = false,
    this.status = LocationUiStatus.idle,
  });

  LocationState copyWith({
    AddressModel? address,
    OutletModel? outlet,
    bool? loading,
    bool? restoring,
    String? error,
    bool? noCoverage,
    LocationUiStatus? status,
    bool clearError = false,
    bool clearOutlet = false,
  }) {
    return LocationState(
      address: address ?? this.address,
      outlet: clearOutlet ? null : (outlet ?? this.outlet),
      loading: loading ?? this.loading,
      restoring: restoring ?? this.restoring,
      error: clearError ? null : (error ?? this.error),
      noCoverage: noCoverage ?? this.noCoverage,
      status: status ?? this.status,
    );
  }
}

final locationControllerProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(ref)..restore();
});

class LocationController extends StateNotifier<LocationState> {
  LocationController(this.ref) : super(const LocationState(restoring: true));
  final Ref ref;
  final _location = LocationService();

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('loc_lat');
      final lng = prefs.getDouble('loc_lng');
      final address = prefs.getString('loc_address');
      if (lat == null || lng == null || address == null) {
        if (mounted) state = const LocationState(restoring: false);
        return;
      }
      await applyCoordinates(
        lat: lat,
        lng: lng,
        fullAddress: address,
        label: prefs.getString('loc_label') ?? 'Saved',
        savedOutletId: prefs.getString('loc_outlet'),
        savedOutletName: prefs.getString('loc_outlet_name'),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      if (mounted) state = state.copyWith(restoring: false, loading: false);
    } finally {
      if (mounted && state.restoring) {
        state = state.copyWith(restoring: false, loading: false);
      }
    }
  }

  Future<void> _persist(AddressModel address, OutletModel? outlet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('loc_lat', address.lat);
    await prefs.setDouble('loc_lng', address.lng);
    await prefs.setString('loc_address', address.fullAddress);
    await prefs.setString('loc_label', address.label);
    if (outlet != null) {
      await prefs.setString('loc_outlet', outlet.id);
      await prefs.setString('loc_outlet_name', outlet.name);
    }
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
    if (state.loading) return;
    state = state.copyWith(
      loading: true,
      clearError: true,
      noCoverage: false,
      status: LocationUiStatus.loading,
    );
    final result = await _location.detect();
    if (!mounted) return;
    if (result.fail != null) {
      final status = switch (result.fail!) {
        LocationFail.denied => LocationUiStatus.denied,
        LocationFail.deniedForever => LocationUiStatus.deniedForever,
        LocationFail.gpsOff => LocationUiStatus.gpsOff,
        LocationFail.failed => LocationUiStatus.failed,
      };
      state = state.copyWith(loading: false, restoring: false, status: status);
      return;
    }
    final loc = result.location!;
    await applyCoordinates(lat: loc.lat, lng: loc.lng, fullAddress: loc.address, label: 'Current');
  }

  Future<void> applyManualAddress(String query) async {
    if (state.loading) return;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true, noCoverage: false, status: LocationUiStatus.loading);
    final loc = await _location.fromAddress(trimmed);
    if (!mounted) return;
    if (loc == null) {
      state = state.copyWith(loading: false, restoring: false, status: LocationUiStatus.failed);
      return;
    }
    await applyCoordinates(lat: loc.lat, lng: loc.lng, fullAddress: loc.address, label: 'Manual');
  }

  void resetToIdle() {
    state = const LocationState(restoring: false, status: LocationUiStatus.idle);
  }

  void clearForNewLogin() {
    if (!mounted) return;
    state = const LocationState(restoring: false, status: LocationUiStatus.idle);
  }

  Future<void> openAppSettings() => _location.openSettings();

  Future<void> openGpsSettings() => _location.openGpsSettings();

  Future<void> applyCoordinates({
    required double lat,
    required double lng,
    required String fullAddress,
    String label = 'Home',
    String? id,
    String? savedOutletId,
    String? savedOutletName,
  }) async {
    List<OutletModel> outlets = const [];
    try {
      outlets = await ref.read(outletsProvider.future).timeout(const Duration(seconds: 8));
    } catch (_) {}
    var outlet = matchOutlet(lat, lng, outlets);
    if (outlet == null && savedOutletId != null && savedOutletId.isNotEmpty) {
      outlet = outlets.where((o) => o.id == savedOutletId).firstOrNull ??
          OutletModel(
            id: savedOutletId,
            name: savedOutletName ?? 'Outlet',
            address: fullAddress,
            lat: lat,
            lng: lng,
            serviceRadiusKm: 25,
            isActive: true,
            contactNumber: '',
            openTime: '11:00',
            closeTime: '23:30',
          );
    }
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
      state = LocationState(
        address: address,
        loading: false,
        restoring: false,
        noCoverage: true,
        status: LocationUiStatus.noCoverage,
      );
      return;
    }
    await _persist(address, outlet);
    state = LocationState(
      address: address,
      outlet: outlet,
      loading: false,
      restoring: false,
      status: LocationUiStatus.detected,
    );
  }

  void setFromSaved(AddressModel address, List<OutletModel> outlets) {
    final outlet = address.outletId == null
        ? matchOutlet(address.lat, address.lng, outlets)
        : outlets.where((o) => o.id == address.outletId).firstOrNull ??
            matchOutlet(address.lat, address.lng, outlets);
    _persist(address, outlet);
    state = LocationState(
      address: address,
      outlet: outlet,
      restoring: false,
      noCoverage: outlet == null,
      status: outlet == null ? LocationUiStatus.noCoverage : LocationUiStatus.detected,
    );
  }
}
