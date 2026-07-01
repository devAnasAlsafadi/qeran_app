import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_motion.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Ambient offline status strip: a compact wine bar with a gold wifi-off glyph
/// and the localized "no connection" label. Visibility (and the post-login
/// gate) is decided by the caller; this widget only animates itself in/out
/// based on [visible] — revealing from the top edge on [QeranMotion.standard]
/// and leaving symmetrically, with no toast on restore.
class QeranConnectivityBanner extends StatelessWidget {
  const QeranConnectivityBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: QeranMotion.standard,
      switchInCurve: QeranCurves.standard,
      switchOutCurve: QeranCurves.standard,
      // Pure slide from the top edge — the bar translates down into place and
      // back up on restore (no fade, so the motion reads as "slide", not
      // "appear").
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      child: visible ? const _BannerBar() : const SizedBox.shrink(),
    );
  }
}

class _BannerBar extends StatelessWidget {
  const _BannerBar();

  @override
  Widget build(BuildContext context) {
    // Material (not a bare ColoredBox) so the label inherits a proper
    // DefaultTextStyle — without it, an overlay Text outside any Scaffold
    // picks up Flutter's fallback style (the stray underline + washed colour
    // seen before). Colour + decoration are still set explicitly for a crisp,
    // opaque soft-white label.
    return Material(
      color: QeranColors.wine,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 16,
                color: QeranColors.gold,
              ),
              QeranSpacing.hs8,
              Flexible(
                child: Text(
                  LocaleKeys.errors_offline.t(context),
                  textAlign: TextAlign.center,
                  style: QeranTypography.label.copyWith(
                    color: QeranColors.creamCanvas,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
