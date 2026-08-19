import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/exit_app_dialog.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import 'package:qeran/core/widgets/question_progress_bar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/photo_slot.dart';
import '../../blocs/photo_manager/photo_manager_cubit.dart';
import '../../blocs/photo_manager/photo_manager_state.dart';
import 'widgets/empty_photo_slot.dart';
import 'widgets/filled_photo_slot.dart';
import 'widgets/photo_picker_bottom_sheet.dart';
import 'widgets/privacy_info_box.dart';

/// The one photo screen. Registration and profile edit share this shell —
/// [PhotoManagerMode] only decides which chrome shows and whether the
/// success path navigates on.
class PhotoManagerScreen extends StatelessWidget {
  const PhotoManagerScreen({super.key, required this.mode});

  final PhotoManagerMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhotoManagerCubit>(
      create: (_) => sl<PhotoManagerCubit>(param1: mode)..load(),
      child: _PhotoManagerView(mode: mode),
    );
  }
}

class _PhotoManagerView extends StatelessWidget {
  const _PhotoManagerView({required this.mode});

  final PhotoManagerMode mode;

  bool get _isOnboarding => mode == PhotoManagerMode.onboarding;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhotoManagerCubit, PhotoManagerState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion,
      listener: _onEvent,
      builder: (context, state) {
        final body = SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return Padding(
                padding: const EdgeInsets.all(QeranSpacing.s16),
                child: isLandscape
                    ? _LandscapeBody(mode: mode, state: state)
                    : _PortraitBody(mode: mode, state: state),
              );
            },
          ),
        );

        final scaffold = Scaffold(
          backgroundColor: QeranColors.creamCanvas,
          // Profile edit is pushed onto a stack and needs a way back; the
          // onboarding step owns the whole screen and uses its own header.
          appBar: _isOnboarding
              ? null
              : AppBar(
                  backgroundColor: QeranColors.creamCanvas,
                  foregroundColor: QeranColors.wine,
                  elevation: 0,
                  title: Text(LocaleKeys.profile_photos_title.t(context)),
                ),
          body: body,
        );

        return _isOnboarding
            ? OnboardingPopScope(child: scaffold)
            : scaffold;
      },
    );
  }

  void _onEvent(BuildContext context, PhotoManagerState state) {
    if (state.event == PhotoManagerEvent.finished) {
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
      return;
    }
    final (message, type) = switch (state.event) {
      PhotoManagerEvent.uploaded => (
        LocaleKeys.profile_photos_uploaded.t(context),
        SnackBarType.success,
      ),
      PhotoManagerEvent.deleted => (
        LocaleKeys.profile_photos_deleted.t(context),
        SnackBarType.success,
      ),
      PhotoManagerEvent.mainChanged => (
        LocaleKeys.profile_photos_main_changed.t(context),
        SnackBarType.success,
      ),
      PhotoManagerEvent.maxReached => (
        LocaleKeys.profile_photos_max_reached.t(context),
        SnackBarType.info,
      ),
      PhotoManagerEvent.validationFailure ||
      PhotoManagerEvent.actionFailure => (
        (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
        SnackBarType.error,
      ),
      PhotoManagerEvent.none || PhotoManagerEvent.finished => (
        '',
        SnackBarType.info,
      ),
    };
    if (message.isEmpty) return;
    AppSnackBar.show(context, message: message, type: type);
  }
}

class _PortraitBody extends StatelessWidget {
  const _PortraitBody({required this.mode, required this.state});

  final PhotoManagerMode mode;
  final PhotoManagerState state;

  @override
  Widget build(BuildContext context) {
    final isOnboarding = mode == PhotoManagerMode.onboarding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOnboarding) ...[
          const QuestionProgressBar(progress: 1.0),
          QeranSpacing.vs16,
          _OnboardingHeader(state: state),
          QeranSpacing.vs8,
          const _TitleArea(),
          QeranSpacing.vs16,
          const PrivacyInfoBox(),
          QeranSpacing.vs24,
        ],
        _PhotoGrid(state: state, crossAxisCount: 2),
        if (state.hasStaged) ...[
          QeranSpacing.vs12,
          _UploadButton(state: state),
        ],
        QeranSpacing.vs12,
      ],
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  const _LandscapeBody({required this.mode, required this.state});

  final PhotoManagerMode mode;
  final PhotoManagerState state;

  @override
  Widget build(BuildContext context) {
    final isOnboarding = mode == PhotoManagerMode.onboarding;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOnboarding)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const QuestionProgressBar(progress: 1.0),
                  QeranSpacing.vs8,
                  _OnboardingHeader(state: state),
                  QeranSpacing.vs8,
                  const _TitleArea(),
                  QeranSpacing.vs12,
                  const PrivacyInfoBox(),
                ],
              ),
            ),
          ),
        if (isOnboarding) QeranSpacing.hs16,
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoGrid(state: state, crossAxisCount: 3),
              if (state.hasStaged) ...[
                QeranSpacing.vs8,
                _UploadButton(state: state),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.state});

  final PhotoManagerState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: state.isBusy ? null : () => ExitAppDialog.show(context),
          child: const Icon(
            Icons.chevron_left_rounded,
            color: QeranColors.wine,
          ),
        ),
        TextButton(
          onPressed: state.isBusy
              ? null
              : context.read<PhotoManagerCubit>().skip,
          child: Text(
            LocaleKeys.common_skip.t(context),
            style: QeranTypography.body.copyWith(color: QeranColors.gold),
          ),
        ),
      ],
    );
  }
}

class _TitleArea extends StatelessWidget {
  const _TitleArea();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.auth_photo_upload_title.t(context),
          style: QeranTypography.displaySm,
        ),
        QeranSpacing.vs8,
        Text(
          LocaleKeys.auth_photo_upload_subtitle.t(context),
          style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.state, required this.crossAxisCount});

  final PhotoManagerState state;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PhotoManagerCubit>();
    final slots = state.slots;
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: QeranSpacing.s16,
          mainAxisSpacing: QeranSpacing.s16,
          childAspectRatio: 0.9,
        ),
        itemCount: kMaxProfilePhotos,
        itemBuilder: (context, index) {
          if (index >= slots.length) {
            return EmptyPhotoSlot(
              // Only a real upload occupies the add tile; a set-main or
              // delete elsewhere has nothing to do with it.
              isUploading: state.inFlight == PhotoManagerAction.upload,
              index: index,
              onAddTap: () => PhotoPickerBottomSheet.show(
                context,
                onImagePicked: cubit.addImage,
              ),
            );
          }
          final slot = slots[index];
          return FilledPhotoSlot(
            key: ValueKey(_slotKey(slot)),
            slot: slot,
            isLoading: state.isSlotLoading(slot),
            isLocked: state.isBusy,
            onRemove: () => _remove(context, cubit, slot),
            onSetPrimary: () => cubit.setMain(slot),
          );
        },
      ),
    );
  }

  static String _slotKey(PhotoSlot slot) => switch (slot) {
    ServerPhotoSlot(:final id) => 'server-$id',
    StagedPhotoSlot(:final path) => 'staged-$path',
  };

  Future<void> _remove(
    BuildContext context,
    PhotoManagerCubit cubit,
    PhotoSlot slot,
  ) async {
    // A staged file was never sent anywhere, so dropping it needs no
    // confirmation. Deleting a server photo is destructive and does.
    if (slot case StagedPhotoSlot(:final path)) {
      cubit.removeStaged(path);
      return;
    }
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.profile_photos_delete_title.t(context),
      message: LocaleKeys.profile_photos_delete_message.t(context),
      confirmLabel: LocaleKeys.common_delete.t(context),
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await cubit.deleteServerImage((slot as ServerPhotoSlot).id);
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.state});

  final PhotoManagerState state;

  @override
  Widget build(BuildContext context) {
    return QeranButton(
      label: LocaleKeys.auth_photo_upload_button.t(context),
      variant: QeranButtonVariant.primaryWine,
      loading: state.inFlight == PhotoManagerAction.upload,
      onPressed: state.isBusy
          ? null
          : context.read<PhotoManagerCubit>().upload,
    );
  }
}
