import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/other_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import '../blocs/profile_details/profile_details_cubit.dart';
import '../blocs/profile_details/profile_details_state.dart';
import '../full_profile_details_args.dart';
import '../widgets/full_profile_body.dart';
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
    return BlocProvider<ProfileDetailsCubit>(
      create: (_) => sl<ProfileDetailsCubit>()
        ..init(userId: args.userId, seed: args.initialData),
      child: _ProfileDetailsView(args: args),
    );
  }
}

class _ProfileDetailsView extends StatelessWidget {
  final FullProfileDetailsArgs args;
  const _ProfileDetailsView({required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ProfileDetailsCubit, ProfileDetailsState>(
          listenWhen: (prev, curr) =>
              curr is ProfileDetailsNotFound &&
              (prev is! ProfileDetailsNotFound ||
                  prev.eventVersion != curr.eventVersion),
          listener: _onState,
          builder: (context, state) => _Body(state: state, args: args),
        ),
      ),
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
}

class _Body extends StatelessWidget {
  final ProfileDetailsState state;
  final FullProfileDetailsArgs args;
  const _Body({required this.state, required this.args});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileDetailsCubit>();
    return Stack(
      children: [
        Positioned.fill(
          child: switch (state) {
            ProfileDetailsInitial() ||
            ProfileDetailsLoading(seed: null) =>
              const ProfileDetailsSkeleton(),
            ProfileDetailsSeeded(:final seed) =>
              _Scrollable(
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
            ProfileDetailsNotFound() =>
              const ProfileDetailsNotAvailableView(),
          },
        ),
        const PositionedDirectional(
          top: QeranSpacing.s8,
          start: QeranSpacing.s8,
          child: _BackButton(),
        ),
      ],
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
      shape: const CircleBorder(
        side: BorderSide(color: QeranColors.wine08),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => NavigationManager.pop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          // arrow_back_ios_new auto-mirrors under the ambient Directionality
          // (matchTextDirection): points right in Arabic/RTL, left in EN/LTR.
          child: Icon(
            Icons.arrow_back_ios_new,
            color: QeranColors.wine,
            size: 20,
          ),
        ),
      ),
    );
  }
}
