import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/editable_category.dart';
import '../blocs/profile_edit/profile_edit_cubit.dart';
import '../blocs/profile_edit/profile_edit_state.dart';
import 'profile_edit_category.dart';

/// Edit tab of the profile hub — loads `GET /api/questions/edit-form`,
/// groups the questions into horizontally-scrollable category tabs, and
/// renders each question prefilled with the current answer.
class ProfileEditView extends StatelessWidget {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileEditCubit>(
      create: (_) => sl<ProfileEditCubit>()..load(),
      child: const _EditBody(),
    );
  }
}

class _EditBody extends StatelessWidget {
  const _EditBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileEditCubit, ProfileEditState>(
      // Fire snackbars on one-shot outcomes (validation / save), keyed on the
      // event version so an edit never re-triggers a stale event.
      listenWhen: (prev, curr) =>
          curr is ProfileEditLoaded &&
          curr.event != ProfileEditEvent.none &&
          (prev is! ProfileEditLoaded ||
              prev.eventVersion != curr.eventVersion),
      listener: _onEvent,
      // Only rebuild the shell on structural transitions; per-field edits
      // (Loaded → Loaded) are handled by each field's BlocSelector so a
      // keystroke or drum scroll never rebuilds the whole form.
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      builder: (context, state) {
        final cubit = context.read<ProfileEditCubit>();
        return switch (state) {
          ProfileEditInitial() ||
          ProfileEditLoading() =>
            const Center(child: QeranLoader()),
          ProfileEditFailure(:final message) => QeranErrorState(
              title: message.t(context),
              retryLabel: LocaleKeys.profile_retry.t(context),
              onRetry: cubit.load,
            ),
          ProfileEditLoaded(:final categories) => categories.isEmpty
              ? const SizedBox.shrink()
              : _CategoryTabs(categories: categories),
        };
      },
    );
  }

  void _onEvent(BuildContext context, ProfileEditState state) {
    if (state is! ProfileEditLoaded) return;
    switch (state.event) {
      case ProfileEditEvent.validationError:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_edit_validation_required.t(context),
          type: SnackBarType.error,
        );
      case ProfileEditEvent.saveFailure:
        AppSnackBar.show(
          context,
          message: state.eventMessage ??
              LocaleKeys.profile_edit_save_failed.t(context),
          type: SnackBarType.error,
        );
      case ProfileEditEvent.saveSuccess:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_edit_save_success.t(context),
          type: SnackBarType.success,
        );
      case ProfileEditEvent.none:
        break;
    }
  }
}

class _CategoryTabs extends StatelessWidget {
  final List<EditableCategory> categories;

  const _CategoryTabs({required this.categories});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          _CategoryTabBar(categories: categories),
          Expanded(
            child: TabBarView(
              children: categories
                  .map((c) => ProfileEditCategory(category: c))
                  .toList(growable: false),
            ),
          ),
          const _SaveBar(),
        ],
      ),
    );
  }
}

/// Full-width wine save pill pinned below the category tabs. Validates
/// required fields, then replays every question to `submit` (send-all). Shows
/// a loader while submitting.
class _SaveBar extends StatelessWidget {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileEditCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s16,
      ),
      child: BlocSelector<ProfileEditCubit, ProfileEditState, bool>(
        selector: (state) =>
            state is ProfileEditLoaded && state.submitting,
        builder: (context, submitting) => QeranButton(
          label: LocaleKeys.profile_edit_save.t(context),
          onPressed: submitting ? null : cubit.save,
          variant: QeranButtonVariant.primaryWine,
          fullWidth: true,
          loading: submitting,
        ),
      ),
    );
  }
}

class _CategoryTabBar extends StatelessWidget {
  final List<EditableCategory> categories;
  const _CategoryTabBar({required this.categories});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: QeranColors.wine,
      indicatorWeight: 2.5,
      dividerColor: QeranColors.wine12,
      labelColor: QeranColors.wine,
      unselectedLabelColor: QeranColors.inkMuted,
      labelStyle: QeranTypography.label.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: QeranTypography.label,
      tabs: categories
          .map((c) => Tab(text: c.categoryName))
          .toList(growable: false),
    );
  }
}
