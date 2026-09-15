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

/// How the user will get their order once an outlet is resolved.
/// `delivery` only valid when the detected point falls inside the
/// outlet's serviceRadiusKm; otherwise user must pick takeaway/dineIn.
enum OrderMode { delivery, takeaway, dineIn }

class LocationState {
  final AddressModel? address;
  final OutletModel? outlet;
  final bool loading;
  final bool restoring;
  final String? error;
  // true when the detected point is OUTSIDE every outlet's serviceRadiusKm.
  // `outlet` may still be set (nearest outlet) so takeaway/dineIn can proceed.
  final bool noCoverage;
  final LocationUiStatus status;
  final OrderMode orderMode;

  const LocationState({
    this.address,
    this.outlet,
    this.loading = false,
    this.restoring = false,
    this.error,
    this.noCoverage = false,
    this.status = LocationUiStatus.idle,
    this.orderMode = OrderMode.delivery,
  });

  // Delivery is only offered when an outlet was matched WITHIN its radius.
  bool get deliveryAvailable => outlet != null && !noCoverage;

  LocationState copyWith({
    AddressModel? address,
    OutletModel? outlet,
    bool? loading,
    bool? restoring,
    String? error,
    bool? noCoverage,
    LocationUiStatus? status,
    OrderMode? orderMode,
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
      orderMode: orderMode ?? this.orderMode,
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
        savedWithinRadius: prefs.getBool('loc_within'),
        savedOrderMode: prefs.getString('loc_mode'),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      if (mounted) state = state.copyWith(restoring: false, loading: false);
    } finally {
      if (mounted && state.restoring) {
        state = state.copyWith(restoring: false, loading: false);
      }
    }
  }

  Future<void> _persist(
    AddressModel address,
    OutletModel? outlet,
    bool withinRadius,
    OrderMode orderMode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('loc_lat', address.lat);
    await prefs.setDouble('loc_lng', address.lng);
    await prefs.setString('loc_address', address.fullAddress);
    await prefs.setString('loc_label', address.label);
    await prefs.setBool('loc_within', withinRadius);
    await prefs.setString('loc_mode', orderMode.name);
    if (outlet != null) {
      await prefs.setString('loc_outlet', outlet.id);
      await prefs.setString('loc_outlet_name', outlet.name);
    } else {
      await prefs.remove('loc_outlet');
      await prefs.remove('loc_outlet_name');
    }
  }

  OrderMode? _parseOrderMode(String? raw) {
    if (raw == null) return null;
    for (final mode in OrderMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }

  /// Outlet whose serviceRadiusKm covers (lat, lng). Used for delivery.
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

  /// Closest outlet by distance, radius ignored. Used to offer
  /// takeaway/dineIn when nobody's serviceRadiusKm covers the user.
  OutletModel? nearestOutlet(double lat, double lng, List<OutletModel> outlets) {
    if (outlets.isEmpty) return null;
    OutletModel best = outlets.first;
    double bestD = haversineKm(lat, lng, best.lat, best.lng);
    for (final o in outlets.skip(1)) {
      final d = haversineKm(lat, lng, o.lat, o.lng);
      if (d < bestD) {
        best = o;
        bestD = d;
      }
    }
    return best;
  }

  /// User explicitly picks how they'll get the order. Only meaningful
  /// after an outlet (in or out of radius) has been resolved. Delivery is
  /// rejected when the user sits outside every outlet's service radius.
  void setOrderMode(OrderMode mode) {
    if (!mounted || state.outlet == null) return;
    if (mode == OrderMode.delivery && !state.deliveryAvailable) return;
    state = state.copyWith(orderMode: mode);
    final address = state.address;
    if (address != null) {
      _persist(address, state.outlet, state.deliveryAvailable, mode);
    }
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
    bool? savedWithinRadius,
    String? savedOrderMode,
  }) async {
    List<OutletModel> outlets = const [];
    try {
      outlets = await ref.read(outletsProvider.future).timeout(const Duration(seconds: 8));
    } catch (_) {}
    // Step 1: strict match — outlet's serviceRadiusKm actually covers this point.
    var outlet = matchOutlet(lat, lng, outlets);
    var withinRadius = outlet != null;

    if (outlet == null && savedOutletId != null && savedOutletId.isNotEmpty) {
      final known = outlets.where((o) => o.id == savedOutletId).firstOrNull;
      if (known != null) {
        // The outlet still exists but no longer covers this point, so the
        // previously-saved coverage must not be trusted.
        outlet = known;
        withinRadius = false;
      } else {
        outlet = OutletModel(
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
        // Outlet list is unavailable right now, so fall back to the coverage
        // we recorded when this address was last saved.
        withinRadius = savedWithinRadius ?? true;
      }
    }

    // Step 2: nothing within radius — resolve nearest outlet anyway (ignoring
    // radius) so the user can still order Takeaway / Dine-In there.
    if (outlet == null) {
      outlet = nearestOutlet(lat, lng, outlets);
      withinRadius = false;
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

    final savedMode = _parseOrderMode(savedOrderMode);
    final resolvedMode = withinRadius
        ? (savedMode ?? OrderMode.delivery)
        : (savedMode == OrderMode.dineIn ? OrderMode.dineIn : OrderMode.takeaway);

    if (outlet == null) {
      // No outlets configured at all — genuinely nothing we can offer.
      await _persist(address, null, false, OrderMode.takeaway);
      state = LocationState(
        address: address,
        loading: false,
        restoring: false,
        noCoverage: true,
        orderMode: OrderMode.takeaway,
        status: LocationUiStatus.noCoverage,
      );
      return;
    }

    await _persist(address, outlet, withinRadius, resolvedMode);
    state = LocationState(
      address: address,
      outlet: outlet,
      loading: false,
      restoring: false,
      noCoverage: !withinRadius,
      orderMode: resolvedMode,
      status: withinRadius ? LocationUiStatus.detected : LocationUiStatus.noCoverage,
    );
  }

  void setFromSaved(AddressModel address, List<OutletModel> outlets) {
    var outlet = address.outletId == null
        ? matchOutlet(address.lat, address.lng, outlets)
        : outlets.where((o) => o.id == address.outletId).firstOrNull ??
            matchOutlet(address.lat, address.lng, outlets);
    final withinRadius = outlet != null;
    outlet ??= nearestOutlet(address.lat, address.lng, outlets);
    final mode = withinRadius ? OrderMode.delivery : OrderMode.takeaway;
    _persist(address, outlet, withinRadius, mode);
    state = LocationState(
      address: address,
      outlet: outlet,
      restoring: false,
      noCoverage: !withinRadius,
      orderMode: mode,
      status: outlet == null
          ? LocationUiStatus.noCoverage
          : (withinRadius ? LocationUiStatus.detected : LocationUiStatus.noCoverage),
    );
  }
}