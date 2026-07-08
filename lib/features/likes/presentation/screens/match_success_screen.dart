import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/motion/soft_scale_in.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Optional context passed to [MatchSuccessScreen]. When the upstream
/// state can supply the just-matched user's name/photo, pass them
/// here; otherwise the screen renders a generic brand celebration.
class MatchSuccessArgs {
  final String? otherName;
  final String? otherPhotoUrl;
  final String? conversationId;

  const MatchSuccessArgs({
    this.otherName,
    this.otherPhotoUrl,
    this.conversationId,
  });
}

/// Full-screen wine-deep celebration that fires when a like becomes a
/// match. Pure visual surface — does not call the cubit or hit the
/// network. The caller is responsible for the underlying state change.
class MatchSuccessScreen extends StatelessWidget {
  final MatchSuccessArgs? args;
  const MatchSuccessScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final hasName = (args?.otherName ?? '').trim().isNotEmpty;
    return Scaffold(
      backgroundColor: QeranColors.wine,
      body: SafeArea(
        child: Stack(
          children: [
            // Quiet ring flourishes at top-end and bottom-start corners.
            const Positioned(
              top: -60,
              right: -60,
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.10,
                size: 260,
                ringCount: 2,
                spacing: 18,
              ),
            ),
            const Positioned(
              bottom: -80,
              left: -80,
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.06,
                size: 300,
                ringCount: 2,
                spacing: 20,
              ),
            ),
            PositionedDirectional(
              top: QeranSpacing.s8,
              end: QeranSpacing.s8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: QeranColors.gold,
                ),
                onPressed: () => NavigationManager.pop(context),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SoftScaleIn(
                        beginScale: 0.88,
                        child: _PortraitOrMark(args: args),
                      ),
                      QeranSpacing.vs32,
                      SoftScaleIn(
                        delay: const Duration(milliseconds: 160),
                        duration: QeranMotion.gentle,
                        child: Text(
                          LocaleKeys.likes_action_accepted_success.t(context),
                          textAlign: TextAlign.center,
                          style: QeranTypography.displaySm
                              .copyWith(color: QeranColors.paper),
                        ),
                      ),
                      if (hasName) ...[
                        QeranSpacing.vs12,
                        SoftScaleIn(
                          delay: const Duration(milliseconds: 240),
                          duration: QeranMotion.gentle,
                          child: Text(
                            args!.otherName!,
                            textAlign: TextAlign.center,
                            style: QeranTypography.title
                                .copyWith(color: QeranColors.gold),
                          ),
                        ),
                      ],
                      QeranSpacing.vs16,
                      SoftScaleIn(
                        delay: const Duration(milliseconds: 320),
                        duration: QeranMotion.gentle,
                        child: Text(
                          LocaleKeys.likes_match_success_subtitle.t(context),
                          textAlign: TextAlign.center,
                          style: QeranTypography.bodySm.copyWith(
                            color: QeranColors.paper.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Continue is pinned full-width to the bottom (inside the outer
            // SafeArea). The forward affordance uses chevron_right_rounded so
            // it mirrors with the locale (points left in AR, right in EN).
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  QeranSpacing.s24,
                  0,
                  QeranSpacing.s24,
                  QeranSpacing.s24,
                ),
                child: SoftScaleIn(
                  delay: const Duration(milliseconds: 400),
                  duration: QeranMotion.gentle,
                  child: QeranButton(
                    label: LocaleKeys.common_next.t(context),
                    onPressed: () => NavigationManager.pop(context),
                    variant: QeranButtonVariant.primary,
                    trailingIcon: Icons.chevron_right_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// If a photo URL is supplied, show it inside a gold-ringed disc;
/// otherwise render the two-circle brand mark.
class _PortraitOrMark extends StatelessWidget {
  final MatchSuccessArgs? args;
  const _PortraitOrMark({required this.args});

  static const double _portraitSize = 132;
  static const double _markDisc = 72;
  static const double _markOverlap = 26;

  @override
  Widget build(BuildContext context) {
    final url = args?.otherPhotoUrl;
    if (url != null && url.isNotEmpty) {
      return _Portrait(url: url);
    }
    return SizedBox(
      width: _markDisc * 2 - _markOverlap,
      height: _markDisc,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _Disc(
              color: QeranColors.gold,
              heart: Icons.favorite_rounded,
            ),
          ),
          Positioned(
            left: _markDisc - _markOverlap,
            top: 0,
            child: _Disc(
              color: QeranColors.paper,
              heart: Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.color, required this.heart});
  final Color color;
  final IconData heart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PortraitOrMark._markDisc,
      height: _PortraitOrMark._markDisc,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.wine, width: 2),
      ),
      child: Icon(heart, color: QeranColors.wine, size: 32),
    );
  }
}

class _Portrait extends StatelessWidget {
  final String url;
  const _Portrait({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PortraitOrMark._portraitSize,
      height: _PortraitOrMark._portraitSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 2),
        boxShadow: const [
          BoxShadow(
            color: QeranColors.gold20,
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: QeranColors.creamSurface,
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: QeranColors.wine,
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const ColoredBox(color: QeranColors.creamSurface);
          },
        ),
      ),
    );
  }
}
