import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../location/location_controller.dart';
import 'address_controller.dart';
import 'address_model.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(addressesProvider).valueOrNull ?? [];
    final outlets = ref.watch(outletsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _edit(context, ref, null),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: list.isEmpty
          ? const EmptyState(title: 'No addresses', subtitle: 'Add a delivery address to get started.', icon: Icons.location_on_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = list[i];
                return AppCard(
                  onTap: () {
                    ref.read(locationControllerProvider.notifier).setFromSaved(a, outlets);
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.home_outlined, color: AppColors.black),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(a.label, style: Theme.of(context).textTheme.titleMedium),
                                if (a.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(10)),
                                    child: const Text('Default', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                            Text(a.fullAddress, style: const TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'default', child: Text('Set default')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (v) async {
                          if (v == 'edit') _edit(context, ref, a);
                          if (v == 'default') await ref.read(addressControllerProvider).setDefault(a.id);
                          if (v == 'delete') await ref.read(addressControllerProvider).delete(a.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, AddressModel? existing) async {
    final label = TextEditingController(text: existing?.label ?? 'Home');
    final address = TextEditingController(text: existing?.fullAddress ?? '');
    final lat = TextEditingController(text: '${existing?.lat ?? 28.6328}');
    final lng = TextEditingController(text: '${existing?.lng ?? 77.2197}');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(c).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Text(existing == null ? 'Add address' : 'Edit address', style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 8),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Full address')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: lat, decoration: const InputDecoration(labelText: 'Lat'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: lng, decoration: const InputDecoration(labelText: 'Lng'))),
              ]),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {
                  final la = double.tryParse(lat.text) ?? 0;
                  final ln = double.tryParse(lng.text) ?? 0;
                  final outlets = ref.read(outletsProvider).valueOrNull ?? [];
                  final outlet = ref.read(locationControllerProvider.notifier).matchOutlet(la, ln, outlets);
                  await ref.read(addressControllerProvider).save(AddressModel(
                        id: existing?.id ?? '',
                        label: label.text,
                        fullAddress: address.text,
                        lat: la,
                        lng: ln,
                        outletId: outlet?.id,
                        isDefault: existing?.isDefault ?? listEmptyDefault(ref),
                      ));
                  if (c.mounted) Navigator.pop(c);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool listEmptyDefault(WidgetRef ref) {
    return (ref.read(addressesProvider).valueOrNull ?? []).isEmpty;
  }
}
