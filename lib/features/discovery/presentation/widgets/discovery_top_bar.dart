import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/notifications/presentation/blocs/notification_badge_cubit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Discovery top bar: the screen title ("استكشاف") on the leading side,
/// with the filter and notifications (unread dot) buttons trailing.
/// Bidirectional — the title sits at the start and the actions at the end
/// in both AR (RTL) and EN (LTR).
class DiscoveryTopBar extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onFilterTap;

  const DiscoveryTopBar({
    super.key,
    this.onNotificationsTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.discovery_title.t(context),
            style: QeranTypography.headline.copyWith(color: QeranColors.wine),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _CircleIconButton(
          icon: Icons.tune_rounded,
          onPressed: onFilterTap,
        ),
        const SizedBox(width: QeranSpacing.s8),
        BlocBuilder<NotificationBadgeCubit, bool>(
          builder: (context, hasUnread) => _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            onPressed: onNotificationsTap,
            badge: hasUnread ? const _BellUnreadDot() : null,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  /// Small unread marker drawn at the top-trailing corner (directional).
  final Widget? badge;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final button = Material(
      color: QeranColors.paper,
      shape: const CircleBorder(
        side: BorderSide(color: QeranColors.wine08),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: disabled ? QeranColors.inkMuted : QeranColors.wine,
          ),
        ),
      ),
    );
    if (badge == null) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        PositionedDirectional(top: 1, end: 1, child: badge!),
      ],
    );
  }
}

/// Subtle on-brand unread dot for the discovery bell — wine with a paper ring
/// so it reads cleanly on the white bell.
class _BellUnreadDot extends StatelessWidget {
  const _BellUnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.wine,
        border: Border.all(color: QeranColors.paper, width: 1.5),
      ),
    );
  }
}
