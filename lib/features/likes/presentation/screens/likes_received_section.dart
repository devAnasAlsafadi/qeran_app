import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
import '../widgets/likes_locked_banner.dart';

/// Received tab — incoming likes. Each pending row exposes the
/// accept/reject circular buttons (wired to `LikesCubit`).
class LikesReceivedSection extends StatelessWidget {
  final LikesState state;
  const LikesReceivedSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    switch (state.incomingStatus) {
      case LikesAsyncStatus.initial:
      case LikesAsyncStatus.loading:
        return const Center(child: QeranLoader());
      case LikesAsyncStatus.failure:
        return LikesErrorView(onRetry: cubit.loadIncoming);
      case LikesAsyncStatus.loaded:
        final data = state.incoming;
        if (data == null || data.isEmpty) {
          return LikesEmptyState(
            icon: Icons.favorite_outline_rounded,
            titleKey: LocaleKeys.likes_empty_received_title,
            subtitleKey: LocaleKeys.likes_empty_received_subtitle,
          );
        }
        return _ReceivedList(
          data: data,
          state: state,
          onRefresh: cubit.loadIncoming,
        );
    }
  }
}

class _ReceivedList extends StatelessWidget {
  final LikeRequestsData data;
  final LikesState state;
  final Future<void> Function() onRefresh;
  const _ReceivedList({
    required this.data,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LikesCubit>();
    final showLockedBanner = data.requiresSubscription;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const navReserve = 96.0;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => onRefresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimens.p20,
          AppDimens.p12,
          AppDimens.p20,
          bottomInset + navReserve,
        ),
        children: [
          if (showLockedBanner) _LockedBanner(),
          for (final card in data.pending)
            LikeUserCard(
              card: card,
              onAccept: card.canAccept
                  ? () => cubit.acceptLike(card.likeRequestId)
                  : null,
              onReject: card.canReject
                  ? () => cubit.rejectLike(card.likeRequestId)
                  : null,
              onUnlock: card.isLocked ? () => _openPackages(context) : null,
              onOpenProfile: card.isLocked
                  ? null
                  : () => _openProfile(context, card),
              isAccepting: state.isAccepting(card.likeRequestId),
              isRejecting: state.isRejecting(card.likeRequestId),
            ),
          if (data.archived.isNotEmpty) ...[
            const SizedBox(height: AppDimens.p16),
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

class _LockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LikesLockedBanner(
      onSubscribe: () => NavigationManager.navigateTo(
        context,
        RouteNames.packagesScreen,
      ),
    );
  }
}
