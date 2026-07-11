import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/shared_profile.dart';
import 'shared_profile_score_chip.dart';

/// The signature in-thread "shared profile" element — a distinct cream card
/// (not a text bubble): a "shared by …" caption, a [QeranMonogram] + name·age
/// + facts line, an optional compatibility-score chip (kept — real backend
/// data), and a full-width gold "view profile" button. Direction-aware.
class SharedProfileMessageCard extends StatelessWidget {
  final SharedProfile profile;
  final bool isMine;

  /// Display name of whoever shared this profile — fills the "shared by …"
  /// caption on incoming cards. Ignored when [isMine] (the label is name-less).
  final String sharerName;

  /// Opens the reusable full-profile screen with this profile as a seed.
  final VoidCallback? onTap;

  const SharedProfileMessageCard({
    super.key,
    required this.profile,
    required this.isMine,
    this.sharerName = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = profile.matchingScore > 0;
    final facts = _factsLine();

    final body = Container(
      width: 260,
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.ios_share_rounded,
                  size: 13, color: QeranColors.goldDeep),
              QeranSpacing.hs4,
              Flexible(
                child: Text(
                  _sharedByLabel(context),
                  style: QeranTypography.caption
                      .copyWith(color: QeranColors.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          QeranSpacing.vs8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QeranMonogram(name: profile.name, size: 48),
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
                        color: QeranColors.inkStrong,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (facts.isNotEmpty) ...[
                      QeranSpacing.vs4,
                      Text(
                        facts,
                        textAlign: TextAlign.start,
                        style: QeranTypography.bodySm
                            .copyWith(color: QeranColors.inkMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasScore) ...[
                      const SizedBox(height: QeranSpacing.s6),
                      SharedProfileScoreChip(
                        percent: profile.matchingScore,
                        accent: QeranColors.wine,
                        textColor: QeranColors.inkStrong,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs12,
          _ViewButton(),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.cardR,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.cardR,
        child: body,
      ),
    );
  }

  String _nameAndAge() {
    final age = profile.age;
    if (age == null) return profile.name;
    return '${profile.name} · $age';
  }

  /// Nationality / profession etc. joined into one muted line. Empty when the
  /// backend ships no `answers`.
  String _factsLine() {
    return profile.answers
        .map((a) => a.answer.trim())
        .where((a) => a.isNotEmpty)
        .join(' · ');
  }

  String _sharedByLabel(BuildContext context) {
    if (isMine) {
      return LocaleKeys.chat_shared_profile_shared_by_me.t(context);
    }
    return context.tr(
      LocaleKeys.chat_shared_profile_shared_by_matchmaker,
      namedArgs: {'name': sharerName},
    );
  }
}

/// Full-width gold CTA — wine label on gold, the brand's primary affordance.
class _ViewButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
      decoration: const BoxDecoration(
        color: QeranColors.gold,
        borderRadius: QeranRadii.controlR,
      ),
      child: Text(
        LocaleKeys.chat_shared_profile_view_cta.t(context),
        textAlign: TextAlign.center,
        style: QeranTypography.label.copyWith(color: QeranColors.wine),
      ),
    );
  }
}
