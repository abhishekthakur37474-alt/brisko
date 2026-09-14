import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brisko_top_bar.dart';
import '../../core/widgets/primary_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _message = TextEditingController();
  String _type = 'complaint';
  bool _loading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const BriskoTopBar(
            title: 'Support',
            subtitle: 'We are here to help',
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.successSoft, child: Icon(Icons.chat, color: AppColors.success)),
                  title: const Text('WhatsApp'),
                  subtitle: const Text('Chat with us instantly'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => launchUrl(Uri.parse('https://wa.me/${AppStrings.whatsappNumber}')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.primarySoft, child: Icon(Icons.call, color: AppColors.primary)),
                  title: const Text('Call us'),
                  subtitle: const Text('Talk to the Brisko team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => launchUrl(Uri.parse('tel:${AppStrings.supportPhone}')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Raise a ticket', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  items: const [
                    DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                    DropdownMenuItem(value: 'query', child: Text('Query')),
                    DropdownMenuItem(value: 'feedback', child: Text('Feedback')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'complaint'),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 12),
                TextField(controller: _message, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Submit ticket',
                  loading: _loading,
                  onPressed: () async {
                    final uid = FirebaseService.instance.auth.currentUser?.uid;
                    if (uid == null || _message.text.trim().isEmpty) return;
                    setState(() => _loading = true);
                    final id = const Uuid().v4();
                    await FirebaseService.instance.ref('supportTickets/$id').set({
                      'userId': uid,
                      'type': _type,
                      'message': _message.text.trim(),
                      'status': 'open',
                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                    });
                    if (!mounted) return;
                    setState(() => _loading = false);
                    _message.clear();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted')));
                  },
                ),
              ],
            ),
          ),
        ],
            ),
          ),
        ],
      ),
    );
  }
}
