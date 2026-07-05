import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Frame 0 — the brand splash. A full-bleed wine canvas with the gold ring
/// motif, the QERAN monogram, the wordmark, and the value tagline.
///
/// It auto-advances to the first content frame after [_holdMs] and can be
/// dismissed early with a tap. [onAdvance] is fired exactly once (timer or tap,
/// whichever comes first).
class OnboardingSplashFrame extends StatefulWidget {
  final VoidCallback onAdvance;

  const OnboardingSplashFrame({super.key, required this.onAdvance});

  @override
  State<OnboardingSplashFrame> createState() => _OnboardingSplashFrameState();
}

class _OnboardingSplashFrameState extends State<OnboardingSplashFrame> {
  static const int _holdMs = 2300;
  Timer? _timer;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: _holdMs), _advance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() {
    if (_advanced) return;
    _advanced = true;
    _timer?.cancel();
    widget.onAdvance();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _advance,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: QeranColors.wine,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const RingMotif(
                color: QeranColors.gold,
                opacity: 0.12,
                size: 320,
                ringCount: 3,
                spacing: 26,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppAssets.splashSymbol, width: 132),
                  QeranSpacing.vs24,
                  // Brand wordmark — a fixed brand mark, not localized copy.
                  Text(
                    'QERAN',
                    style: QeranTypography.displaySm.copyWith(
                      color: QeranColors.gold,
                      letterSpacing: 8,
                    ),
                  ),
                  QeranSpacing.vs16,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QeranSpacing.s32,
                    ),
                    child: Text(
                      LocaleKeys.onboarding_splash_tagline.t(context),
                      textAlign: TextAlign.center,
                      style: QeranTypography.body.copyWith(
                        color: QeranColors.gold60,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
