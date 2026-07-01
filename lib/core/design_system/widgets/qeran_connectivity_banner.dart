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
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1, // reveal/collapse from the top edge
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: visible ? const _BannerBar() : const SizedBox.shrink(),
    );
  }
}

class _BannerBar extends StatelessWidget {
  const _BannerBar();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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
                  style:
                      QeranTypography.label.copyWith(color: QeranColors.creamCanvas),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
