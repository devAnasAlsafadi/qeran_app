import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// The three circular action buttons that sit below the profile card:
/// pass (✕), like (♥), and dislike (👎).
///
/// All three callbacks are optional so this widget renders as a pure
/// preview when the parent has not yet wired the actions to a cubit.
class SwipeActionBar extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const SwipeActionBar({
    super.key,
    this.onPass,
    this.onLike,
    this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleAction(
          icon: Icons.close,
          iconColor: AppColors.textSecondary,
          background: AppColors.white,
          size: 48,
          onTap: onPass,
        ),
        const SizedBox(width: AppDimens.p24),
        _CircleAction(
          icon: Icons.favorite,
          iconColor: AppColors.white,
          background: AppColors.primary,
          size: 64,
          onTap: onLike,
          elevated: true,
        ),
        const SizedBox(width: AppDimens.p24),
        _CircleAction(
          icon: Icons.thumb_down_alt_outlined,
          iconColor: AppColors.textSecondary,
          background: AppColors.white,
          size: 48,
          onTap: onDislike,
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final double size;
  final bool elevated;
  final VoidCallback? onTap;

  const _CircleAction({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.size,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = elevated
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];

    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: shadow,
          ),
          child: Icon(icon, color: iconColor, size: size * 0.42),
        ),
      ),
    );
  }
}
