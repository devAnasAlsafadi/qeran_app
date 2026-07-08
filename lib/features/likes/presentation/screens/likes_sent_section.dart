import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/other_profile_seed.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_requests_data.dart';
import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../widgets/like_user_card.dart';
import '../widgets/likes_empty_state.dart';
import '../widgets/likes_error_view.dart';
import '../widgets/likes_loading_view.dart';

/// Sent tab — outgoing likes. Read-only (no accept/reject actions).
class LikesSentSection extends StatelessWidget {
  final LikesState state;
  const LikesSentSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    switch (state.outgoingStatus) {
      case LikesAsyncStatus.initial:
      case LikesAsyncStatus.loading:
        return const LikesLoadingView();
      case LikesAsyncStatus.failure:
        return LikesErrorView(onRetry: cubit.loadOutgoing);
      case LikesAsyncStatus.loaded:
        final data = state.outgoing;
        if (data == null || data.isEmpty) {
          return LikesEmptyState(
            icon: Icons.send_outlined,
            titleKey: LocaleKeys.likes_empty_sent_title,
            subtitleKey: LocaleKeys.likes_empty_sent_subtitle,
          );
        }
        return _SentList(data: data, onRefresh: cubit.loadOutgoing);
    }
  }
}

class _SentList extends StatelessWidget {
  final LikeRequestsData data;
  final Future<void> Function() onRefresh;
  const _SentList({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navReserve = 96.0;
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: () => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s12,
          QeranSpacing.s20,
          bottomInset + navReserve,
        ),
        children: [
          for (final card in data.pending)
            LikeUserCard(
              card: card,
              onUnlock: card.isLocked ? () => _openPackages(context) : null,
              onOpenProfile: card.isLocked
                  ? null
                  : () => _openProfile(context, card),
            ),
          if (data.archived.isNotEmpty) ...[
            const SizedBox(height: QeranSpacing.s16),
            for (final card in data.archived)
              LikeUserCard(
                card: card,
                onUnlock: card.isLocked ? () => _openPackages(context) : null,
                onOpenProfile: card.isLocked
                    ? null
                    : () => _openProfile(context, card),
              ),
          ],
        ],
      ),
    );
  }

  void _openPackages(BuildContext context) {
    NavigationManager.navigateTo(context, RouteNames.packagesScreen);
  }

  void _openProfile(BuildContext context, LikeRequestCard card) {
    NavigationManager.navigateTo(
      context,
      RouteNames.fullProfileDetails,
      arguments: FullProfileDetailsArgs(
        userId: card.profileId,
        initialData: OtherProfileSeed.fromLikeRequestCard(card),
        entry: ProfileEntrySource.likes,
      ),
    );
  }
}
