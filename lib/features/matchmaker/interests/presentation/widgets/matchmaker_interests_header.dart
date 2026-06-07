import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_interest_user.dart';

/// The viewed user's identity strip, rendered once above the interests tabs —
/// the same [user] applies to all three tabs. Avatar + name + optional age.
class MatchmakerInterestsHeader extends StatelessWidget {
  const MatchmakerInterestsHeader({super.key, required this.user});

  final MatchmakerInterestUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s4,
      ),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: user.profileImageUrl, size: 48),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.fullName,
                  style: QeranTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.age != null) ...[
                  QeranSpacing.vs4,
                  Text(
                    context.tr(
                      LocaleKeys.matchmaker_interests_header_age,
                      namedArgs: {'age': '${user.age}'},
                    ),
                    style: QeranTypography.caption.copyWith(
                      color: QeranColors.inkMuted,
                    ),
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
