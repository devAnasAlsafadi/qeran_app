import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../core/design_system/widgets/qeran_own_text.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/community_author.dart';

/// Who wrote it, by name (A18): the display name in its own direction and
/// script (D13), cut at its own end when it's long (B2) — and after a
/// matchmaker's name the «خطّابة» chip, always whole.
class CommunityAuthorName extends StatelessWidget {
  const CommunityAuthorName({super.key, required this.author});

  final CommunityAuthor author;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: QeranOwnText(
            author.displayName,
            style: QeranTypography.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
        if (author.isMatchmaker) ...[
          const SizedBox(width: QeranSpacing.s6),
          QeranChip(
            label: LocaleKeys.community_matchmaker_badge.t(context),
            variant: QeranChipVariant.plan,
            icon: Icons.verified_rounded,
            compact: true,
          ),
        ],
      ],
    );
  }
}
