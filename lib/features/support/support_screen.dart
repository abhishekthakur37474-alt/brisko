import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_strings.dart';
import '../../core/services/firebase_service.dart';
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
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('WhatsApp'),
            onTap: () => launchUrl(Uri.parse('https://wa.me/${AppStrings.whatsappNumber}')),
          ),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Call us'),
            onTap: () => launchUrl(Uri.parse('tel:${AppStrings.supportPhone}')),
          ),
          const SizedBox(height: 12),
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
    );
  }
}
