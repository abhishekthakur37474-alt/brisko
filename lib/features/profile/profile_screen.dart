import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: AppColors.black, child: Text('B', style: TextStyle(color: AppColors.white))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Guest', style: Theme.of(context).textTheme.titleLarge),
                      Text(user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => _edit(context, ref, user?.name ?? '', user?.phone ?? ''), icon: const Icon(Icons.edit_outlined)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tile(context, Icons.location_on_outlined, 'Addresses', () => context.push('/addresses')),
          _tile(context, Icons.favorite_border, 'Wishlist', () => context.push('/wishlist')),
          _tile(context, Icons.card_giftcard, 'Loyalty points', () => context.push('/loyalty')),
          _tile(context, Icons.local_offer_outlined, 'Offers', () => context.push('/offers')),
          _tile(context, Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
          _tile(context, Icons.support_agent, 'Support', () => context.push('/support')),
          _tile(context, Icons.description_outlined, 'Policies', () => context.push('/policies')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      tileColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String name, String phone) async {
    final n = TextEditingController(text: name);
    final p = TextEditingController(text: phone);
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: p, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider).updateProfile(name: n.text, phone: p.text);
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
