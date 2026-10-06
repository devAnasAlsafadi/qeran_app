import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../badges/domain/entities/badge_counts.dart';
import '../../../../badges/presentation/blocs/badges_cubit.dart';
import '../screens/matchmaker_community_screen.dart';

/// Her way into Community from every tab's header (A1, D26): before the
/// bell, with a gold dot while a comment on her posts is new or a report
/// waits for her decision (A3). Both counts arrive live (`BadgeUpdated`).
class CommunityHeaderAction extends StatelessWidget {
  const CommunityHeaderAction({super.key});

  static bool _active(BadgeCounts counts) =>
      counts.communityComments > 0 || counts.communityReports > 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesCubit, BadgeCounts>(
      bloc: sl<BadgesCubit>(),
      buildWhen: (previous, current) => _active(previous) != _active(current),
      builder: (context, counts) => IconButton(
        tooltip: LocaleKeys.matchmaker_community_title.t(context),
        onPressed: () => openMatchmakerCommunity(context),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            // The size of the bell and the gear beside it.
            const Icon(
              Icons.dynamic_feed_rounded,
              size: 24,
              color: QeranColors.wine,
            ),
            if (_active(counts))
              const PositionedDirectional(top: -3, end: -3, child: _Dot()),
          ],
        ),
      ),
    );
  }
}

/// The board's dot: gold, ringed in the bar's own canvas.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: QeranColors.gold,
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.creamCanvas, width: 1.5),
      ),
    );
  }
}
