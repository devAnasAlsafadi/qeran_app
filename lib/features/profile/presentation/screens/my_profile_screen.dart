import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/my_profile/my_profile_cubit.dart';
import '../blocs/my_profile/my_profile_state.dart';
import '../widgets/my_profile_body.dart';
import '../widgets/states/profile_details_error_view.dart';
import '../widgets/states/profile_details_skeleton.dart';

/// Owner-facing read of `GET /api/profile`. Surfaces the status banner
/// + full body. Edit affordance is wired to a future Edit Answers
/// flow — Batch 1 only shows the placeholder route key.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyProfileCubit>(
      create: (_) => sl<MyProfileCubit>()..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.profile_my_title.t(context),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.primary),
          onPressed: () => NavigationManager.pop(context),
        ),
      ),
      body: BlocBuilder<MyProfileCubit, MyProfileState>(
        builder: (context, state) {
          final cubit = context.read<MyProfileCubit>();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: cubit.refresh,
            child: _content(state, cubit),
          );
        },
      ),
    );
  }

  Widget _content(MyProfileState state, MyProfileCubit cubit) {
    return switch (state) {
      MyProfileInitial() ||
      MyProfileLoading(previous: null) => const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 600,
            child: ProfileDetailsSkeleton(),
          ),
        ),
      MyProfileLoading(:final previous?) ||
      MyProfileLoaded(profile: final previous) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: AppDimens.p32),
          child: MyProfileBody(profile: previous),
        ),
      MyProfileFailure(:final previous?) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: AppDimens.p32),
          child: MyProfileBody(profile: previous),
        ),
      MyProfileFailure(:final message) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 600,
              child: ProfileDetailsErrorView(
                message: message,
                onRetry: cubit.refresh,
              ),
            ),
          ],
        ),
    };
  }
}
