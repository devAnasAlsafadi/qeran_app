import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_typography.dart';

/// Cream-aware app bar with wine title + icons and a branded back
/// button. Caller owns navigation; this widget never pops on its own.
class QeranAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QeranAppBar({
    super.key,
    this.title,
    this.onBack,
    this.actions = const [],
    this.background = QeranColors.creamCanvas,
    this.centerTitle = true,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Color background;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      iconTheme: const IconThemeData(color: QeranColors.wine),
      actionsIconTheme: const IconThemeData(color: QeranColors.wine),
      leading: canPop
          ? QeranBackButton(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title == null
          ? null
          : Text(
              title!,
              style: QeranTypography.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      actions: actions,
    );
  }
}

/// The house back affordance — a wine chevron that mirrors with the locale.
///
/// Public because screens without an app bar need the same glyph: the user-app
/// bottom-nav tabs carry their own in-body header, so a back control there
/// cannot come through [QeranAppBar].
class QeranBackButton extends StatelessWidget {
  const QeranBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `chevron_left_rounded` auto-mirrors under the ambient Directionality
    // (matchTextDirection): points left in LTR, right in RTL. No manual
    // isRtl swap — that plus the framework's auto-mirror double-flips.
    return IconButton(
      icon: const Icon(
        Icons.chevron_left_rounded,
        color: QeranColors.wine,
        size: 26,
      ),
      onPressed: onTap,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
