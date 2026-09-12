import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_motion.dart';

class SectionHeader extends StatefulWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader> {
  bool _nudge = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        children: [
          Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
          if (widget.actionLabel != null && widget.onAction != null)
            TextButton(
              onPressed: () async {
                setState(() => _nudge = true);
                widget.onAction!();
                await Future<void>.delayed(AppMotion.fast);
                if (mounted) setState(() => _nudge = false);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.actionLabel!, style: const TextStyle(color: AppColors.primary)),
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    transform: Matrix4.translationValues(_nudge ? 4 : 0, 0, 0),
                    child: const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}