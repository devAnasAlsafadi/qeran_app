import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/my_profile.dart';
import '../../domain/entities/profile_entry_source.dart';
import '../../domain/entities/profile_status.dart';
import '../blocs/my_profile/my_profile_cubit.dart';
import '../blocs/my_profile/my_profile_state.dart';
import '../blocs/photo_manager/photo_manager_state.dart';
import '../blocs/profile_gate/profile_gate_cubit.dart';
import 'photo_manager/photo_manager_screen.dart';
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
          MyProfileLoading(previous: null) => const ProfileDetailsSkeleton(),
          MyProfileLoading(:final previous?) => _Loaded(
            profile: previous,
            onRefresh: cubit.refresh,
            onManagePhotos: () => _openPhotos(context, cubit),
          ),
          MyProfileLoaded(:final profile) => _Loaded(
            profile: profile,
            onRefresh: cubit.refresh,
            onManagePhotos: () => _openPhotos(context, cubit),
          ),
          MyProfileFailure(:final previous?) => _Loaded(
            profile: previous,
            onRefresh: cubit.refresh,
            onManagePhotos: () => _openPhotos(context, cubit),
          ),
          MyProfileFailure(:final message) => ProfileDetailsErrorView(
            message: message,
            onRetry: cubit.refresh,
          ),
        };
      },
    );
  }

  Future<void> _openPhotos(BuildContext context, MyProfileCubit cubit) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const PhotoManagerScreen(mode: PhotoManagerMode.profileEdit),
      ),
    );
    if (!context.mounted) return;
    await Future.wait([cubit.refresh(), sl<ProfileGateCubit>().refresh()]);
  }
}

class _Loaded extends StatelessWidget {
  final MyProfile profile;
  final Future<void> Function() onRefresh;
  final VoidCallback onManagePhotos;
  const _Loaded({
    required this.profile,
    required this.onRefresh,
    required this.onManagePhotos,
  });

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
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                QeranSpacing.s20,
                0,
                QeranSpacing.s20,
                QeranSpacing.s12,
              ),
              child: QeranButton(
                label: LocaleKeys.profile_photos_manage.t(context),
                leadingIcon: Icons.photo_library_outlined,
                onPressed: onManagePhotos,
                variant: QeranButtonVariant.secondary,
                fullWidth: true,
              ),
            ),
            FullProfileBody(profile: adapted, entry: ProfileEntrySource.mine),
          ],
        ),
      ),
    );
  }
}
