import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../tokens/qeran_colors.dart';
import 'qeran_count_badge.dart';

/// The notifications bell, for both shells: the user's top bar and the
/// matchmaker's app bar. One widget so the two apps cannot drift apart.
///
/// The count is a state, not decoration: it shows only while the server
/// reports unread notifications, and reads "99+" past 99. What a tap opens is
/// the caller's.
class QeranBellButton extends StatelessWidget {
  const QeranBellButton({super.key, required this.count, required this.onTap});

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
              Icons.notifications_none_rounded,
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
