import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../auth/auth_controller.dart';
import 'reviews_controller.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  final String productId;
  const ReviewSheet({super.key, required this.productId});

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('Rate your order', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.warning, size: 32),
              ),
            ),
          ),
          TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Comment')),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Submit review',
            loading: _loading,
            onPressed: () async {
              setState(() => _loading = true);
              try {
                await ReviewsController().submit(
                  productId: widget.productId,
                  userName: user?.name ?? 'Customer',
                  rating: _rating,
                  comment: _comment.text,
                );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
