import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../../domain/entities/my_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import '../../domain/entities/profile_status.dart';
import '../blocs/my_profile/my_profile_cubit.dart';
import '../blocs/my_profile/my_profile_state.dart';
import '../mappers/my_profile_to_other_profile.dart';
import '../widgets/full_profile_body.dart';
import '../widgets/profile_status_chip.dart';
import '../widgets/states/profile_details_error_view.dart';
import '../widgets/states/profile_details_skeleton.dart';

/// View tab of the profile hub — renders MY OWN profile through the shared
/// detailed-profile surface ([FullProfileBody]). The
/// [myProfileToOtherProfile] adapter zeroes the match score and clears the
/// blur, so the compatibility pill and the photo-lock never paint without
/// any change to the shared hero. A compact status chip on the cream canvas
/// above the hero echoes the owner's review state.
class ProfileSelfView extends StatelessWidget {
  const ProfileSelfView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyProfileCubit>(
      create: (_) => sl<MyProfileCubit>()..load(),
      child: const _SelfViewBody(),
    );
  }
}

class _SelfViewBody extends StatelessWidget {
  const _SelfViewBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyProfileCubit, MyProfileState>(
      builder: (context, state) {
        final cubit = context.read<MyProfileCubit>();
        return switch (state) {
          MyProfileInitial() ||
          MyProfileLoading(previous: null) =>
            const ProfileDetailsSkeleton(),
          MyProfileLoading(:final previous?) =>
            _Loaded(profile: previous, onRefresh: cubit.refresh),
          MyProfileLoaded(:final profile) =>
            _Loaded(profile: profile, onRefresh: cubit.refresh),
          MyProfileFailure(:final previous?) =>
            _Loaded(profile: previous, onRefresh: cubit.refresh),
          MyProfileFailure(:final message) => ProfileDetailsErrorView(
              message: message,
              onRetry: cubit.refresh,
            ),
        };
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  final MyProfile profile;
  final Future<void> Function() onRefresh;
  const _Loaded({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final adapted = myProfileToOtherProfile(profile);
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile.profileStatus != ProfileStatus.unknown)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QeranSpacing.s20,
                  QeranSpacing.s12,
                  QeranSpacing.s20,
                  QeranSpacing.s12,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ProfileStatusChip(status: profile.profileStatus),
                ),
              ),
            FullProfileBody(
              profile: adapted,
              entry: ProfileEntrySource.mine,
            ),
          ],
        ),
      ),
    );
  }
}
