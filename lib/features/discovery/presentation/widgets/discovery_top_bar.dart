import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Filter button (placeholder, non-functional this phase) on the leading
/// side; notifications/messages icon on the trailing side.
class DiscoveryTopBar extends StatelessWidget {
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onFilterTap; // null this phase

  const DiscoveryTopBar({
    super.key,
    this.onNotificationsTap,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.tune_rounded,
          onPressed: onFilterTap,
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          onPressed: onNotificationsTap,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
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
  }
}
