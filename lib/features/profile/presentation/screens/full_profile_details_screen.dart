import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/block/presentation/widgets/safety_menu_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import '../blocs/profile_details/profile_details_cubit.dart';
import '../blocs/profile_details/profile_details_state.dart';
import '../blocs/profile_reaction/profile_reaction_cubit.dart';
import '../blocs/profile_reaction/profile_reaction_state.dart';
import '../full_profile_details_args.dart';
import '../widgets/full_profile_body.dart';
import '../widgets/share_with_matchmaker_button.dart';
import '../widgets/states/profile_details_error_view.dart';
import '../widgets/states/profile_details_not_available_view.dart';
import '../widgets/states/profile_details_skeleton.dart';

/// Reusable full-profile read surface. Entry points (Discovery card,
/// chat shared bubble, like row, match card, settings) all push to
/// this single route with [FullProfileDetailsArgs]; the entry source
/// gates affordances (share button, action bar) inside the body.
class FullProfileDetailsScreen extends StatelessWidget {
  final FullProfileDetailsArgs args;
  const FullProfileDetailsScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    // Resolved once, here: this is the only place where both inputs to the
    // policy are in hand — the entry source off the route args, and who is
    // looking off the session. Everything below reads the one boolean, so the
    // three gates cannot drift apart.
    final canReact = canReactFromEntry(
      args.entry,
      isMatchmaker: sl<UserSessionCubit>().currentUser?.isMatchmaker ?? false,
    );
    final view = _ProfileDetailsView(args: args, canReact: canReact);
    // No PhotoViewCubit here any more. This screen never reveals a photo —
    // peer photos render blurred whatever the exchange status — so mounting
    // the one-time viewing permission would be dead wiring, and worse, a
    // second surface able to spend a window that belongs to the
    // compatibility tab.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileDetailsCubit>(
          create: (_) =>
              sl<ProfileDetailsCubit>()
                ..init(userId: args.userId, seed: args.initialData),
        ),
        // Not mounted when the viewer may not react: the matchmaker was
        // carrying a live like/pass cubit on a profile she only reviews.
        if (canReact) BlocProvider<ProfileReactionCubit>(create: (_) => sl()),
      ],
      child: view,
    );
  }
}

class _ProfileDetailsView extends StatelessWidget {
  final FullProfileDetailsArgs args;
  final bool canReact;
  const _ProfileDetailsView({required this.args, required this.canReact});

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ProfileDetailsCubit, ProfileDetailsState>(
          listenWhen: (prev, curr) =>
              curr is ProfileDetailsNotFound &&
              (prev is! ProfileDetailsNotFound ||
                  prev.eventVersion != curr.eventVersion),
          listener: _onState,
          builder: (context, state) =>
              _Body(state: state, args: args, canReact: canReact),
        ),
      ),
    );
    if (!canReact) return scaffold;
    return BlocListener<ProfileReactionCubit, ProfileReactionState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion,
      listener: _onReaction,
      child: scaffold,
    );
  }

  void _onState(BuildContext context, ProfileDetailsState state) {
    if (state is! ProfileDetailsNotFound) return;
    AppSnackBar.show(
      context,
      message: LocaleKeys.profile_not_available.t(context),
      type: SnackBarType.info,
    );
  }

  void _onReaction(BuildContext context, ProfileReactionState state) {
    switch (state.event) {
      case ProfileReactionEvent.none:
        break;
      case ProfileReactionEvent.likeSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_reaction_like_success.t(context),
          type: SnackBarType.success,
        );
        NavigationManager.pop(context, args.userId);
      case ProfileReactionEvent.passSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_reaction_pass_success.t(context),
          type: SnackBarType.success,
        );
        NavigationManager.pop(context, args.userId);
      case ProfileReactionEvent.paywall:
        showPaywall(context, intent: PaywallIntent.like);
      case ProfileReactionEvent.alreadyPending:
        AppSnackBar.show(
          context,
          message: LocaleKeys.discovery_like_already_pending.t(context),
          type: SnackBarType.info,
        );
        NavigationManager.pop(context, args.userId);
      case ProfileReactionEvent.genderMismatch:
        AppSnackBar.show(
          context,
          message: LocaleKeys.discovery_like_gender_mismatch.t(context),
          type: SnackBarType.error,
        );
        NavigationManager.pop(context, args.userId);
      case ProfileReactionEvent.userUnavailable:
        AppSnackBar.show(
          context,
          message: LocaleKeys.discovery_like_user_unavailable.t(context),
          type: SnackBarType.info,
        );
        NavigationManager.pop(context, args.userId);
      case ProfileReactionEvent.underReview:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_status_pending_review_like.t(context),
          type: SnackBarType.info,
        );
      case ProfileReactionEvent.failure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.errors_generic.t(context),
          type: SnackBarType.error,
        );
    }
  }
}

class _Body extends StatelessWidget {
  final ProfileDetailsState state;
  final FullProfileDetailsArgs args;
  final bool canReact;
  const _Body({
    required this.state,
    required this.args,
    required this.canReact,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileDetailsCubit>();
    return Stack(
      children: [
        Positioned.fill(
          child: switch (state) {
            ProfileDetailsInitial() ||
            ProfileDetailsLoading(seed: null) => const ProfileDetailsSkeleton(),
            ProfileDetailsSeeded(:final seed) => _Scrollable(
              profile: seed,
              entry: args.entry,
              isLoading: true,
              onRefresh: () => cubit.refresh(args.userId),
            ),
            ProfileDetailsLoading(:final seed?) => _Scrollable(
              profile: seed,
              entry: args.entry,
              isLoading: true,
              onRefresh: () => cubit.refresh(args.userId),
            ),
            ProfileDetailsLoaded(:final profile) => _Scrollable(
              profile: profile,
              entry: args.entry,
              onRefresh: () => cubit.refresh(args.userId),
            ),
            ProfileDetailsFailure(:final seed?) => _Scrollable(
              profile: seed,
              entry: args.entry,
              onRefresh: () => cubit.refresh(args.userId),
            ),
            ProfileDetailsFailure(:final message) => ProfileDetailsErrorView(
              message: message,
              onRetry: () => cubit.refresh(args.userId),
            ),
            ProfileDetailsNotFound() => const ProfileDetailsNotAvailableView(),
          },
        ),
        const PositionedDirectional(
          top: QeranSpacing.s8,
          start: QeranSpacing.s8,
          child: _BackButton(),
        ),
        // Report / Block this candidate (UGC safety, Apple 1.2). Popping with
        // the blocked userId lets the originating deck/list tear the user down.
        PositionedDirectional(
          top: QeranSpacing.s8,
          end: QeranSpacing.s8,
          child: SafetyMenuButton(targetUserId: args.userId),
        ),
        // Pinned share CTA — visible from first paint (no scrolling to the
        // end); content scrolls behind a soft paper scrim so it stays
        // readable. Same entry gate + share flow as before.
        if (showShareForEntry(args.entry) && _hasProfile(state))
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _PinnedShareCta(userId: args.userId),
          ),
        if (canReact && _hasProfile(state))
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _PinnedReactionCta(userId: args.userId),
          ),
      ],
    );
  }
}

/// True while a profile (or its seed) is on screen — the pinned share CTA is
/// meaningless during the skeleton / error / not-found states.
bool _hasProfile(ProfileDetailsState state) => switch (state) {
  ProfileDetailsSeeded() => true,
  ProfileDetailsLoading(seed: final s) => s != null,
  ProfileDetailsLoaded() => true,
  ProfileDetailsFailure(seed: final s) => s != null,
  _ => false,
};

/// Bottom-pinned share CTA with a soft paper scrim so scrolling content behind
/// it fades to the paper surface and stays legible.
class _PinnedShareCta extends StatelessWidget {
  final String userId;
  const _PinnedShareCta({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QeranColors.paper.withValues(alpha: 0.0), QeranColors.paper],
          stops: const [0.0, 0.55],
        ),
      ),
      child: SafeArea(
        top: false,
        child: ShareWithMatchmakerButton(userId: userId),
      ),
    );
  }
}

class _PinnedReactionCta extends StatelessWidget {
  final String userId;
  const _PinnedReactionCta({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [QeranColors.paper.withValues(alpha: 0), QeranColors.paper],
          stops: const [0, 0.45],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s20,
          QeranSpacing.s20,
          QeranSpacing.s12,
        ),
        child: BlocBuilder<ProfileReactionCubit, ProfileReactionState>(
          builder: (context, state) => Row(
            children: [
              Expanded(
                child: QeranButton(
                  label: LocaleKeys.discovery_action_like_label.t(context),
                  leadingIcon: Icons.favorite_rounded,
                  variant: QeranButtonVariant.primaryWine,
                  size: QeranButtonSize.md,
                  loading: state.isLiking,
                  onPressed: state.isBusy
                      ? null
                      : () => context.read<ProfileReactionCubit>().like(userId),
                ),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: QeranButton(
                  label: LocaleKeys.discovery_action_pass_label.t(context),
                  leadingIcon: Icons.close_rounded,
                  variant: QeranButtonVariant.secondary,
                  size: QeranButtonSize.md,
                  loading: state.isPassing,
                  onPressed: state.isBusy
                      ? null
                      : () => context.read<ProfileReactionCubit>().pass(userId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Scrollable extends StatelessWidget {
  final OtherProfile profile;
  final ProfileEntrySource entry;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  const _Scrollable({
    required this.profile,
    required this.entry,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: FullProfileBody(
          profile: profile,
          entry: entry,
          isLoading: isLoading,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(side: BorderSide(color: QeranColors.wine08)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => NavigationManager.pop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          // chevron_left_rounded auto-mirrors under the ambient Directionality
          // (matchTextDirection): points right in Arabic/RTL, left in EN/LTR.
          child: Icon(
            Icons.chevron_left_rounded,
            color: QeranColors.wine,
            size: 20,
          ),
        ),
      ),
    );
  }
}
