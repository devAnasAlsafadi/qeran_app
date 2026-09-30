import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The top bar's bell. The count is a state, not decoration: it shows only
/// while the server reports unread notifications, and reads "99+" past 99.
class ShellBellButton extends StatelessWidget {
  const ShellBellButton({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: LocaleKeys.notifications_bell_unread_a11y.t(
        context,
        namedArgs: {'count': '$count'},
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: 26,
              color: QeranColors.wine,
            ),
            if (count > 0)
              PositionedDirectional(
                top: -4,
                end: -4,
                child: QeranCountBadge(count: count),
              ),
          ],
        ),
      ),
    );
  }
}
