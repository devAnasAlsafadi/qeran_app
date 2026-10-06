import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_typography.dart';

/// Cream-aware app bar with wine title + icons and a branded back
/// button — or, for a screen that is a draft, a close × ([close]). Caller
/// owns navigation; this widget never pops on its own.
class QeranAppBar extends StatelessWidget implements PreferredSizeWidget {
  const QeranAppBar({
    super.key,
    this.title,
    this.onBack,
    this.actions = const [],
    this.background = QeranColors.creamCanvas,
    this.centerTitle = true,
    this.close = false,
  });

  final String? title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Color background;
  final bool centerTitle;

  /// A × where the back chevron would be: the screen closes rather than
  /// goes back (a composer).
  final bool close;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Asks THIS screen's route, not the navigator: `Navigator.canPop()` is
    // true for a shell tab whenever another screen sits on top of it, and a
    // tab rebuilt then (a language switch made from a pushed screen) kept a
    // chevron that went nowhere. `ModalRoute.of` also rebuilds the bar when
    // its route's standing changes. The same test Material's AppBar uses.
    final canPop =
        onBack != null ||
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      iconTheme: const IconThemeData(color: QeranColors.wine),
      actionsIconTheme: const IconThemeData(color: QeranColors.wine),
      leading: canPop ? _leading(context) : null,
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

  Widget _leading(BuildContext context) {
    final tap = onBack ?? () => Navigator.of(context).maybePop();
    if (!close) return QeranBackButton(onTap: tap);
    return IconButton(
      icon: const Icon(Icons.close_rounded, color: QeranColors.wine, size: 26),
      onPressed: tap,
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
    );
  }
}

/// The house back affordance — a wine chevron that mirrors with the locale.
///
/// Public because screens without an app bar need the same glyph: the user
/// shell's top bar is its own widget, not a [QeranAppBar], and carries the
/// back control for a tab reached from the inbox.
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
