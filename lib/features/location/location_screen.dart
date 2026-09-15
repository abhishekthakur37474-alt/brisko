import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/primary_button.dart';
import 'location_controller.dart';
import 'store_status.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _manual = false;
  final _address = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _address.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _openManual() {
    setState(() => _manual = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeManual() {
    _focus.unfocus();
    _address.clear();
    setState(() => _manual = false);
  }

  Future<void> _submitManual() async {
    final value = _address.text.trim();
    if (value.isEmpty) return;
    _focus.unfocus();
    await ref.read(locationControllerProvider.notifier).applyManualAddress(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    final store = ref.watch(storeStatusProvider);
    final status = loc.loading ? LocationUiStatus.loading : loc.status;
    // When the resolved outlet is closed we lock the location entry controls
    // and surface the next opening time instead.
    final storeClosed = loc.outlet != null && store.isClosed;
    final showForm = _manual && status != LocationUiStatus.detected && !storeClosed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_manual) {
          _closeManual();
          return;
        }
        if (context.canPop()) {
          context.pop();
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 680;
              return AnimatedPadding(
                duration: AppMotion.page,
                curve: AppMotion.easeOut,
                padding: EdgeInsets.fromLTRB(20, showForm ? 16 : 28, 20, 24),
                child: Column(
                  children: [
                    AnimatedOpacity(
                      duration: AppMotion.page,
                      curve: AppMotion.easeOut,
                      opacity: showForm ? 0 : 1,
                      child: AnimatedSize(
                        duration: AppMotion.modal,
                        curve: AppMotion.easeOut,
                        alignment: Alignment.topCenter,
                        child: showForm
                            ? const SizedBox(width: double.infinity)
                            : Column(
                                children: [
                                  SizedBox(height: compact ? 8 : 16),
                                  _DeliveryAnimation(size: compact ? 220 : 280),
                                  SizedBox(height: compact ? 8 : 12),
                                ],
                              ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: AppMotion.page,
                          switchInCurve: AppMotion.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: showForm
                              ? _ManualForm(
                                  key: const ValueKey('manual'),
                                  controller: _address,
                                  focusNode: _focus,
                                  loading: loc.loading,
                                  onSubmit: _submitManual,
                                  onDetect: () {
                                    _closeManual();
                                    ref.read(locationControllerProvider.notifier).detect();
                                  },
                                )
                              : _StatusBody(
                                  key: const ValueKey('status'),
                                  status: status,
                                  loc: loc,
                                  storeClosed: storeClosed,
                                  nextOpenLabel: store.nextOpenLabel,
                                  hoursLabel: store.hoursLabel,
                                  onDetect: () => ref.read(locationControllerProvider.notifier).detect(),
                                  onManual: _openManual,
                                  onContinue: () {
                                    if (loc.outlet == null || storeClosed) return;
                                    ref.read(locationControllerProvider.notifier).setOrderMode(OrderMode.delivery);
                                    context.go('/home');
                                  },
                                  onTakeaway: () {
                                    if (loc.outlet == null || storeClosed) return;
                                    ref.read(locationControllerProvider.notifier).setOrderMode(OrderMode.takeaway);
                                    context.go('/home');
                                  },
                                  onDineIn: () {
                                    if (loc.outlet == null || storeClosed) return;
                                    ref.read(locationControllerProvider.notifier).setOrderMode(OrderMode.dineIn);
                                    context.go('/home');
                                  },
                                  onBrowse: () => context.go('/home'),
                                  onChange: () {
                                    _closeManual();
                                    ref.read(locationControllerProvider.notifier).resetToIdle();
                                  },
                                  onOpenSettings: () => ref.read(locationControllerProvider.notifier).openAppSettings(),
                                  onOpenGps: () => ref.read(locationControllerProvider.notifier).openGpsSettings(),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ManualForm extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onDetect;

  const _ManualForm({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onSubmit,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text(
          'Enter your address',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.black, height: 1.25),
        ),
        const SizedBox(height: 8),
        const Text(
          'Type your delivery area and we will check if Brisko Pizza delivers there.',
          style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(
            hintText: 'Area, street or landmark',
            prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.muted, size: 22),
            prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 22),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Check this address',
          loading: loading,
          onPressed: loading ? null : onSubmit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: loading ? null : onDetect,
          child: const Text(
            'Use my current location',
            style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _StatusBody extends StatelessWidget {
  final LocationUiStatus status;
  final LocationState loc;
  final bool storeClosed;
  final String? nextOpenLabel;
  final String hoursLabel;
  final VoidCallback onDetect;
  final VoidCallback onManual;
  final VoidCallback onContinue;
  final VoidCallback onTakeaway;
  final VoidCallback onDineIn;
  final VoidCallback onBrowse;
  final VoidCallback onChange;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGps;

  const _StatusBody({
    super.key,
    required this.status,
    required this.loc,
    required this.storeClosed,
    required this.nextOpenLabel,
    required this.hoursLabel,
    required this.onDetect,
    required this.onManual,
    required this.onContinue,
    required this.onTakeaway,
    required this.onDineIn,
    required this.onBrowse,
    required this.onChange,
    required this.onOpenSettings,
    required this.onOpenGps,
  });

  @override
  Widget build(BuildContext context) {
    if (storeClosed && loc.outlet != null) {
      return _ClosedCard(
        outletName: loc.outlet!.name,
        outletAddress: loc.outlet!.address,
        opensAt: nextOpenLabel ?? 'soon',
        hours: hoursLabel,
        onBrowse: onBrowse,
      );
    }
    switch (status) {
      case LocationUiStatus.loading:
        return const _CopyBlock(
          title: 'Detect your location',
          body: 'Find Brisko Pizza near you and check delivery availability.',
          cta: 'Checking your location...',
          loading: true,
        );
      case LocationUiStatus.detected:
        return _DetectedCard(
          address: loc.address?.fullAddress ?? '',
          delivers: loc.outlet != null,
          onContinue: onContinue,
          onChange: onChange,
        );
      case LocationUiStatus.noCoverage:
        if (loc.outlet == null) {
          // No outlets configured anywhere — genuinely nothing to offer.
          return _CopyBlock(
            title: "We're not delivering here yet",
            body: 'This location is currently outside our delivery area. Try another address.',
            cta: 'Choose another location',
            onCta: onChange,
            onManual: onManual,
          );
        }
        return _PickupCard(
          outletName: loc.outlet!.name,
          outletAddress: loc.outlet!.address,
          onTakeaway: onTakeaway,
          onDineIn: onDineIn,
          onChange: onChange,
        );
      case LocationUiStatus.denied:
        return _CopyBlock(
          title: 'Location access is off',
          body: "We couldn't access your location. You can enable location permission or enter your address manually.",
          cta: 'Try again',
          onCta: onDetect,
          onManual: onManual,
        );
      case LocationUiStatus.deniedForever:
        return _CopyBlock(
          title: 'Turn on location access',
          body: 'Location permission is disabled for Brisko Pizza. You can enable it from your device settings or enter your address manually.',
          cta: 'Open settings',
          onCta: onOpenSettings,
          onManual: onManual,
        );
      case LocationUiStatus.gpsOff:
        return _CopyBlock(
          title: 'Turn on your location',
          body: 'Your device location is currently turned off. Turn it on to find Brisko Pizza near you.',
          cta: 'Turn on location',
          onCta: onOpenGps,
          onManual: onManual,
        );
      case LocationUiStatus.failed:
        return _CopyBlock(
          title: "We couldn't find your location",
          body: 'Please check your location settings and try again.',
          cta: 'Try again',
          onCta: onDetect,
          onManual: onManual,
        );
      case LocationUiStatus.idle:
        return _CopyBlock(
          title: 'Detect your location',
          body: 'Find Brisko Pizza near you and check delivery availability.',
          cta: 'Use my current location',
          hugeIcon: HugeIcons.strokeRoundedLocation04,
          onCta: onDetect,
          privacy: true,
        );
    }
  }
}

class _CopyBlock extends StatelessWidget {
  final String title;
  final String body;
  final String cta;
  final VoidCallback? onCta;
  final VoidCallback? onManual;
  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  final bool loading;
  final bool privacy;

  const _CopyBlock({
    required this.title,
    required this.body,
    required this.cta,
    this.onManual,
    this.onCta,
    this.icon,
    this.hugeIcon,
    this.loading = false,
    this.privacy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.black, height: 1.25),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted, fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(height: 32),
        Semantics(
          button: true,
          label: cta,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: loading ? null : onCta,
                  borderRadius: BorderRadius.circular(999),
                  child: Center(
                    child: loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Checking your location...',
                                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hugeIcon != null) ...[
                                HugeIcon(icon: hugeIcon!, color: AppColors.white, size: 20),
                                const SizedBox(width: 8),
                              ] else if (icon != null) ...[
                                Icon(icon, color: AppColors.white, size: 20),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  cta,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onManual != null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: onManual,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter address manually',
                  style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w500, fontSize: 15),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.black),
              ],
            ),
          ),
        ],
        if (privacy) ...[
          const SizedBox(height: 20),
          const Text(
            'Your location is only used to check Brisko Pizza delivery availability.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _DetectedCard extends StatelessWidget {
  final String address;
  final bool delivers;
  final VoidCallback onContinue;
  final VoidCallback onChange;

  const _DetectedCard({
    required this.address,
    required this.delivers,
    required this.onContinue,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Location detected',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E5E2)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF16803C), size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                address.isEmpty ? 'Current location' : address,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.black, height: 1.45),
              ),
              const SizedBox(height: 10),
              Text(
                delivers ? 'Brisko Pizza delivers here' : "We're not delivering here yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: delivers ? const Color(0xFF16803C) : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (delivers)
          SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onContinue,
                  borderRadius: BorderRadius.circular(999),
                  child: const Center(
                    child: Text('Continue', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 56,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onChange,
                  borderRadius: BorderRadius.circular(999),
                  child: const Center(
                    child: Text('Choose another location', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onChange,
          child: const Text(
            'Change location',
            style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _PickupCard extends StatelessWidget {
  final String outletName;
  final String outletAddress;
  final VoidCallback onTakeaway;
  final VoidCallback onDineIn;
  final VoidCallback onChange;

  const _PickupCard({
    required this.outletName,
    required this.outletAddress,
    required this.onTakeaway,
    required this.onDineIn,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "We're not delivering here yet",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        const SizedBox(height: 8),
        const Text(
          "You're outside our delivery area, but you can still order from the outlet below.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E5E2)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFFFCEAE6), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                outletName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.black),
              ),
              const SizedBox(height: 4),
              Text(
                outletAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTakeaway,
                borderRadius: BorderRadius.circular(999),
                child: const Center(
                  child: Text('Order Takeaway', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary, width: 1.4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDineIn,
                borderRadius: BorderRadius.circular(999),
                child: const Center(
                  child: Text('Dine-In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onChange,
          child: const Text(
            'Choose another location',
            style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _ClosedCard extends StatelessWidget {
  final String outletName;
  final String outletAddress;
  final String opensAt;
  final String hours;
  final VoidCallback onBrowse;

  const _ClosedCard({
    required this.outletName,
    required this.outletAddress,
    required this.opensAt,
    required this.hours,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Outlet is closed',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        const SizedBox(height: 8),
        Text(
          'Ordering is paused right now. We open again $opensAt.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: const Icon(Icons.access_time, color: AppColors.warning, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                'Opens $opensAt',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.black),
              ),
              if (hours.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Open daily · $hours',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                outletName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
              ),
              const SizedBox(height: 2),
              Text(
                outletAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primary, width: 1.4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBrowse,
                borderRadius: BorderRadius.circular(999),
                child: const Center(
                  child: Text('Browse menu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliveryAnimation extends StatelessWidget {
  final double size;
  const _DeliveryAnimation({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/Delivery.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}