import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/matchmaker_colleague.dart';

/// One colleague-directory row: unblurred avatar + name, tappable to start (or
/// reopen) a chat. While this row's open-chat is resolving ([isResolving]) the
/// trailing chevron is swapped for an inline loader and taps are suppressed.
class MatchmakerColleagueCard extends StatelessWidget {
  const MatchmakerColleagueCard({
    super.key,
    required this.colleague,
    required this.isResolving,
    this.onTap,
  });

  final MatchmakerColleague colleague;
  final bool isResolving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      onTap: isResolving ? null : onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: colleague.profileImageUrl, size: 52),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              colleague.name,
              style: QeranTypography.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          QeranSpacing.hs8,
          _trailing(),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (isResolving) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: QeranLoader.inline(),
      );
    }
    return const Icon(
      Icons.chat_bubble_outline_rounded,
      size: 20,
      color: QeranColors.wine,
    );
  }
}
