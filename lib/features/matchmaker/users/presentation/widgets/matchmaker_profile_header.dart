import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/effects/ring_motif.dart';
import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Hero title card for the matchmaker profile detail — name + age headline,
/// a gender chip, and the user's email (a matchmaker-only field). Mirrors
/// the user-side hero card's layered look (overlaps the gallery, faint gold
/// ring motif) minus the verified mark and match score, which don't apply
/// to a profile under review.
class MatchmakerProfileHeader extends StatelessWidget {
  const MatchmakerProfileHeader({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.email,
  });

  final String name;
  final int? age;
  final String gender;
  final String email;

  @override
  Widget build(BuildContext context) {
    final title = age == null
        ? name
        : context.tr(
            LocaleKeys.profile_name_age_format,
            namedArgs: {'name': name, 'age': '$age'},
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: IgnorePointer(
              child: const RingMotif(
                color: QeranColors.gold,
                opacity: 0.08,
                size: 120,
                ringCount: 2,
                spacing: 12,
              ),
            ),
          ),
          QeranCard.hero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: QeranTypography.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (gender.isNotEmpty) ...[
                  QeranSpacing.vs12,
                  QeranChip(
                    label: gender,
                    variant: QeranChipVariant.meta,
                    compact: true,
                  ),
                ],
                if (email.isNotEmpty) ...[
                  QeranSpacing.vs12,
                  Row(
                    children: [
                      const Icon(
                        Icons.alternate_email_rounded,
                        size: 18,
                        color: QeranColors.wine,
                      ),
                      QeranSpacing.hs8,
                      Expanded(
                        child: Text(
                          email,
                          style: QeranTypography.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
