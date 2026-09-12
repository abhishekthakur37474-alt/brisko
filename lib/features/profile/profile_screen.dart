import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.black,
                  child: Text(
                    (user?.name.isNotEmpty == true ? user!.name[0] : 'B').toUpperCase(),
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name.isNotEmpty == true ? user!.name : 'Guest', style: Theme.of(context).textTheme.titleLarge),
                      if ((user?.email ?? '').isNotEmpty)
                        Text(user!.email, style: const TextStyle(color: AppColors.muted)),
                      if ((user?.phone ?? '').isNotEmpty)
                        Text(user!.phone, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      if ((user?.loyaltyPoints ?? 0) > 0)
                        Text('${user!.loyaltyPoints} loyalty pts', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => _edit(context, ref, user?.name ?? '', user?.email ?? '', user?.phone ?? ''),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(context, Icons.location_on_outlined, 'Addresses', () => context.push('/addresses')),
                _tile(context, Icons.favorite_border, 'Wishlist', () => context.push('/wishlist')),
                _tile(context, Icons.card_giftcard, 'Loyalty points', () => context.push('/loyalty')),
                _tile(context, Icons.local_offer_outlined, 'Offers', () => context.push('/offers')),
                _tile(context, Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
                _tile(context, Icons.support_agent, 'Support', () => context.push('/support')),
                _tile(context, Icons.description_outlined, 'Policies', () => context.push('/policies'), last: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('You can sign back in anytime with the same Google account.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Logout')),
                  ],
                ),
              );
              if (ok == true) await ref.read(authControllerProvider).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool last = false}) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.black),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1, indent: 68),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String name, String email, String phone) async {
    final n = TextEditingController(text: name);
    final e = TextEditingController(text: email);
    final p = TextEditingController(text: phone);
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: e, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(
              controller: p,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider).updateProfile(name: n.text, email: e.text, phone: p.text);
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
