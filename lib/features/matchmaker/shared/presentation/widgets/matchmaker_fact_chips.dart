import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../generated/locale_keys.g.dart';

/// A person's admin-flagged facts as compact cream meta-chips (≤3), followed
/// by the age line "عندي {age} سنة". Each chip ellipsizes at ~60% of the row
/// width so a long fact never overflows or dominates. Shared by the matchmaker
/// user cards (and later Cases / Explore). The parent should only mount this
/// when at least one fact or the age is present.
class MatchmakerFactChips extends StatelessWidget {
  const MatchmakerFactChips({
    super.key,
    required this.facts,
    this.age,
  });

  /// Verbatim flagged-answer strings (already ordered by the backend).
  final List<String> facts;

  /// Age in years, or null when the user has no birthdate answer.
  final int? age;

  static const int _maxFacts = 3;

  @override
  Widget build(BuildContext context) {
    final shown = facts.take(_maxFacts).toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipMaxWidth = constraints.maxWidth * 0.6;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shown.isNotEmpty)
              Wrap(
                spacing: QeranSpacing.s6,
                runSpacing: QeranSpacing.s6,
                children: [
                  for (final f in shown)
                    QeranChip(
                      label: f,
                      variant: QeranChipVariant.meta,
                      compact: true,
                      maxWidth: chipMaxWidth,
                    ),
                ],
              ),
            if (age != null) ...[
              if (shown.isNotEmpty) const SizedBox(height: QeranSpacing.s6),
              Text(
                context.tr(
                  LocaleKeys.matchmaker_users_age_years,
                  namedArgs: {'age': '$age'},
                ),
                style: QeranTypography.bodySm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }
}
