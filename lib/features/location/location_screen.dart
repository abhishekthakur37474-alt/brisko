import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import 'location_controller.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _address = TextEditingController();
  final _lat = TextEditingController(text: '28.6328');
  final _lng = TextEditingController(text: '77.2197');

  @override
  void dispose() {
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _manual() async {
    final lat = double.tryParse(_lat.text);
    final lng = double.tryParse(_lng.text);
    if (lat == null || lng == null) return;
    await ref.read(locationControllerProvider.notifier).applyCoordinates(
          lat: lat,
          lng: lng,
          fullAddress: _address.text.trim().isEmpty ? 'Pinned location' : _address.text.trim(),
          label: 'Manual',
        );
    if (!mounted) return;
    final state = ref.read(locationControllerProvider);
    if (state.outlet != null) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(locationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Where should we deliver?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'We match you to the nearest Brisko outlet that serves your area.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Detect my location',
            icon: Icons.my_location,
            loading: loc.loading,
            onPressed: () async {
              await ref.read(locationControllerProvider.notifier).detect();
              if (!mounted) return;
              final state = ref.read(locationControllerProvider);
              if (state.outlet != null && mounted) context.go('/home');
            },
          ),
          const SizedBox(height: 24),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or enter manually')),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _lat, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Latitude'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _lng, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Longitude'))),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _manual, child: const Text('Use this location')),
                TextButton(
                  onPressed: () async {
                    _address.text = 'Connaught Place, New Delhi';
                    _lat.text = '28.6328';
                    _lng.text = '77.2197';
                    await _manual();
                  },
                  child: const Text('Use demo outlet (Delhi CP)'),
                ),
              ],
            ),
          ),
          if (loc.error != null) ...[
            const SizedBox(height: 16),
            Text(loc.error!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
          if (loc.noCoverage) ...[
            const SizedBox(height: 24),
            AppCard(
              color: AppColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sorry, Brisko doesn\'t deliver to your area yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Try a different address or notify us when we expand.'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
