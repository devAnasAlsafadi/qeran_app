import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/shared_profile.dart';

/// Mini-profile card rendered inside a chat bubble for shared-profile
/// messages: image + name + age + compatibility chip + a "view profile"
/// CTA. Adapts to the bubble it sits in — light treatment on my wine
/// bubble, ink treatment on the incoming paper bubble. Direction-aware
/// via `AlignmentDirectional`.
class SharedProfileMessageCard extends StatelessWidget {
  final SharedProfile profile;
  final bool isMine;

  /// Opens the reusable full-profile screen with this profile as a seed.
  final VoidCallback? onTap;

  const SharedProfileMessageCard({
    super.key,
    required this.profile,
    required this.isMine,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = profile.primaryImage;
    final hasScore = profile.matchingScore > 0;
    // `isMine` → card sits on the wine bubble (light treatment);
    // incoming → card sits on the paper bubble (ink treatment).
    final onWine = isMine;
    final titleColor = onWine ? QeranColors.paper : QeranColors.inkStrong;
    final mutedColor =
        onWine ? QeranColors.paper.withValues(alpha: 0.85) : QeranColors.inkMuted;
    final accent = onWine ? QeranColors.gold : QeranColors.wine;
    final innerBg =
        onWine ? QeranColors.paper.withValues(alpha: 0.10) : QeranColors.creamSurface;
    final borderColor =
        onWine ? QeranColors.paper.withValues(alpha: 0.18) : QeranColors.wine12;

    final body = Container(
      width: 240,
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: innerBg,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              LikeBlurredImage(
                url: image?.url,
                blur: image?.isBlurred ?? true,
                size: 56,
              ),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nameAndAge(),
                      textAlign: TextAlign.start,
                      style: QeranTypography.subtitle.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasScore) ...[
                      const SizedBox(height: QeranSpacing.s6),
                      _ScoreChip(
                        percent: profile.matchingScore,
                        accent: accent,
                        textColor: titleColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs8,
          Text(
            _sharedByLabel(context),
            textAlign: TextAlign.start,
            style: QeranTypography.caption.copyWith(color: mutedColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          QeranSpacing.vs12,
          _ViewButton(onWine: onWine),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.controlR,
        child: body,
      ),
    );
  }

  String _nameAndAge() {
    final age = profile.age;
    if (age == null) return profile.name;
    return '${profile.name} · $age';
  }

  String _sharedByLabel(BuildContext context) {
    if (isMine) {
      return LocaleKeys.chat_shared_profile_shared_by_me.t(context);
    }
    return LocaleKeys.chat_shared_profile_shared_by_matchmaker.t(context);
  }
}

/// Bottom CTA bar — wine fill on the incoming paper card, light fill on
/// my wine card; paper text on both.
class _ViewButton extends StatelessWidget {
  final bool onWine;
  const _ViewButton({required this.onWine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      decoration: BoxDecoration(
        color: onWine ? QeranColors.paper.withValues(alpha: 0.15) : QeranColors.wine,
        borderRadius: QeranRadii.controlR,
      ),
      child: Text(
        LocaleKeys.chat_shared_profile_view_cta.t(context),
        textAlign: TextAlign.center,
        style: QeranTypography.label.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final double percent;
  final Color accent;
  final Color textColor;
  const _ScoreChip({
    required this.percent,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = context.tr(
      LocaleKeys.chat_shared_profile_score_label,
      namedArgs: {'percent': '${percent.round()}'},
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: QeranRadii.pill,
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: QeranTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
