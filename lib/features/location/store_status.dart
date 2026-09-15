import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/store_hours.dart';
import 'location_controller.dart';
import 'outlet_model.dart';

/// Emits immediately and then every 30 seconds so open/closed UI re-evaluates
/// without needing a manual refresh when the clock crosses the boundary.
Stream<DateTime> _clockTick() async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
}

final clockProvider = StreamProvider<DateTime>((ref) => _clockTick());

/// Resolved open/closed state for the outlet the user is ordering from.
class StoreStatus {
  final OutletModel? outlet;
  final bool isOpen;
  final String? nextOpenLabel;

  const StoreStatus({this.outlet, required this.isOpen, this.nextOpenLabel});

  bool get hasOutlet => outlet != null;

  bool get isClosed => outlet != null && !isOpen;

  String get hoursLabel => outlet?.hoursLabel ?? '';

  bool isOpenAt(DateTime now) => outlet?.isOpenAt(now) ?? true;
}

final storeStatusProvider = Provider<StoreStatus>((ref) {
  final outlet = ref.watch(locationControllerProvider).outlet;
  final now = ref.watch(clockProvider).valueOrNull ?? DateTime.now();
  if (outlet == null) return const StoreStatus(isOpen: true);
  final open = outlet.isOpenAt(now);
  return StoreStatus(
    outlet: outlet,
    isOpen: open,
    nextOpenLabel: open ? null : StoreHours.nextOpeningLabel(now, outlet.openTime, outlet.closeTime),
  );
});
