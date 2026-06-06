import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_card_answer.dart';

/// The user's admin-flagged answers (max [_maxAnswers], in the admin-driven
/// order) followed by a standalone age line ("عندي {age} سنة"). Both are
/// dynamic — answers may be empty and age may be null — so the parent only
/// mounts this when at least one is present; any overflow beyond [_maxAnswers]
/// is reached via the full-profile (عرض) screen. Answer text is shown verbatim,
/// Figma-style (no question prefix); the `question` field stays on the entity
/// if context is ever needed. Shared by the matchmaker user-list card and the
/// interests-mirror cards (M3f).
class MatchmakerCardAnswersBlock extends StatelessWidget {
  const MatchmakerCardAnswersBlock({
    super.key,
    required this.answers,
    this.age,
  });

  final List<MatchmakerCardAnswer> answers;
  final int? age;

  static const int _maxAnswers = 3;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[
      for (final a in answers.take(_maxAnswers))
        Text(
          a.answer,
          style: QeranTypography.bodySm,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      if (age != null)
        Text(
          context.tr(
            LocaleKeys.matchmaker_users_age_years,
            namedArgs: {'age': '$age'},
          ),
          style: QeranTypography.bodySm,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) QeranSpacing.vs4,
          lines[i],
        ],
      ],
    );
  }
}
