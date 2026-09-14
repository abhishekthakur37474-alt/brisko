import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/app_colors.dart';

class BriskoTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final bool circularBack;
  final VoidCallback? onBack;
  final IconData? trailingIcon;
  final List<List<dynamic>>? trailingHugeIcon;
  final VoidCallback? onTrailingTap;
  final int? badgeCount;
  final String? amountText;

  const BriskoTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.circularBack = false,
    this.onBack,
    this.trailingIcon,
    this.trailingHugeIcon,
    this.onTrailingTap,
    this.badgeCount,
    this.amountText,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hasAmount = amountText != null && amountText!.isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final hasBadge = badgeCount != null && badgeCount! > 0;
    final hasTrailing = trailingHugeIcon != null || trailingIcon != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 4, 16, 6),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (hasBadge) ...[
                        const SizedBox(width: 6),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${badgeCount!}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasAmount)
                    Text(
                      amountText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.25,
                      ),
                    )
                  else if (hasSubtitle)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                        height: 1.25,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                if (showBack)
                  circularBack
                      ? _CircleIconButton(
                          tooltip: 'Back',
                          onTap: () => _handleBack(context),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            color: AppColors.black,
                            size: 24,
                          ),
                        )
                      : _BareIconButton(
                          tooltip: 'Back',
                          onTap: () => _handleBack(context),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            color: AppColors.black,
                            size: 24,
                          ),
                        )
                else
                  const SizedBox(width: 32),
                const Spacer(),
                if (hasTrailing)
                  _BareIconButton(
                    onTap: onTrailingTap,
                    child: trailingHugeIcon != null
                        ? HugeIcon(
                            icon: trailingHugeIcon!,
                            color: AppColors.black,
                            size: 24,
                          )
                        : Icon(trailingIcon, size: 24, color: AppColors.black),
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  const _CircleIconButton({required this.child, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(child: child),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _BareIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  const _BareIconButton({required this.child, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final icon = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
    if (tooltip == null) return icon;
    return Tooltip(message: tooltip!, child: icon);
  }
}
