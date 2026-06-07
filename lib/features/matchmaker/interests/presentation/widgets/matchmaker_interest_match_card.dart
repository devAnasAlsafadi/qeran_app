import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../likes/presentation/widgets/like_blurred_image.dart';
import '../../../../likes/presentation/widgets/match_card_scaffold.dart';
import '../../../users/presentation/widgets/matchmaker_card_answers_block.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_formal_request.dart';
import '../../domain/entities/matchmaker_interest_match.dart';

/// Read-only active-match card — the gold-accented tier. Reuses
/// [MatchCardScaffold] for the avatar + name + stage line, with the flagged
/// answers and the backend formal-status (verbatim) in the footer. No CTAs, no
/// countdown ([MatchCardScaffold.topChip] stays null). When [MatchmakerInterest
/// Match.isLocked] the other party is redacted (blurred image, hidden name /
/// answers / formal status), the stage line is kept, and the card isn't
/// tappable — never a subscription CTA.
class MatchmakerInterestMatchCard extends StatelessWidget {
  const MatchmakerInterestMatchCard({super.key, required this.match});

  final MatchmakerInterestMatch match;

  @override
  Widget build(BuildContext context) {
    final locked = match.isLocked;
    final spec = _stageSpec(match.stage);
    return QeranCard(
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      accentBar: true,
      onTap: locked
          ? null
          : () => NavigationManager.navigateTo(
                context,
                RouteNames.matchmakerUserProfile,
                arguments: match.otherUserId,
              ),
      child: MatchCardScaffold(
        avatar: LikeBlurredImage(
          url: match.primaryImage?.url,
          blur: locked,
          size: 56,
        ),
        name: locked
            ? LocaleKeys.matchmaker_interests_locked_name.t(context)
            : match.name,
        statusIcon: spec.icon,
        statusText: spec.labelKey.t(context),
        statusColor: spec.color,
        footer: _footer(context, locked),
      ),
    );
  }

  Widget? _footer(BuildContext context, bool locked) {
    if (locked) return null;
    final children = <Widget>[];
    if (match.answers.isNotEmpty) {
      children.add(MatchmakerCardAnswersBlock(answers: match.answers));
    }
    final formalLabel = _formalLabel(context, match.formalRequest);
    if (formalLabel != null) {
      if (children.isNotEmpty) children.add(QeranSpacing.vs8);
      children.add(
        QeranChip(
          label: formalLabel,
          variant: QeranChipVariant.interest,
          icon: Icons.verified_outlined,
          compact: true,
        ),
      );
    }
    if (children.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Backend formal-status text, locale-aware (Arabic default, English when the
/// app is in English and a value is provided). `null` when there's no formal
/// request yet.
String? _formalLabel(
  BuildContext context,
  MatchmakerInterestFormalRequest? formal,
) {
  if (formal == null) return null;
  final ar = formal.statusNameAr;
  final en = formal.statusNameEn;
  final isArabic = context.locale.languageCode == 'ar';
  final label = isArabic ? ar : (en.isNotEmpty ? en : ar);
  return label.isEmpty ? null : label;
}

({String labelKey, IconData icon, Color color}) _stageSpec(
  MatchmakerInterestMatchStage stage,
) {
  return switch (stage) {
    MatchmakerInterestMatchStage.waitingForPhotoExchange => (
        labelKey: LocaleKeys.matchmaker_interests_match_stage_waiting,
        icon: Icons.photo_camera_outlined,
        color: QeranColors.wine,
      ),
    MatchmakerInterestMatchStage.photosExchanged => (
        labelKey: LocaleKeys.matchmaker_interests_match_stage_exchanged,
        icon: Icons.photo_library_outlined,
        color: QeranColors.gold,
      ),
    MatchmakerInterestMatchStage.matchmakerEngaged => (
        labelKey: LocaleKeys.matchmaker_interests_match_stage_engaged,
        icon: Icons.handshake_outlined,
        color: QeranColors.gold,
      ),
    MatchmakerInterestMatchStage.unknown => (
        labelKey: LocaleKeys.matchmaker_interests_match_stage_waiting,
        icon: Icons.favorite_border_rounded,
        color: QeranColors.inkMuted,
      ),
  };
}
