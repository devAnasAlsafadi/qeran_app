import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_confirm_dialog.dart';
import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../auth/presentation/screens/upload_image/widgets/photo_picker_bottom_sheet.dart';
import '../../../likes/presentation/widgets/like_blurred_image.dart';
import '../../domain/entities/profile_image.dart';
import '../blocs/profile_photos/profile_photos_cubit.dart';
import '../blocs/profile_photos/profile_photos_state.dart';

class ProfilePhotosScreen extends StatelessWidget {
  const ProfilePhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfilePhotosCubit>()..load(),
      child: const _ProfilePhotosView(),
    );
  }
}

class _ProfilePhotosView extends StatelessWidget {
  const _ProfilePhotosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: AppBar(
        backgroundColor: QeranColors.creamCanvas,
        foregroundColor: QeranColors.wine,
        elevation: 0,
        title: Text(LocaleKeys.profile_photos_title.t(context)),
      ),
      body: BlocConsumer<ProfilePhotosCubit, ProfilePhotosState>(
        listenWhen: (previous, current) =>
            previous.eventVersion != current.eventVersion,
        listener: _onEvent,
        builder: (context, state) {
          if (state.status == ProfilePhotosStatus.loading &&
              state.images.isEmpty) {
            return const Center(child: QeranLoader());
          }
          if (state.status == ProfilePhotosStatus.failure &&
              state.images.isEmpty) {
            return QeranErrorState(
              title: LocaleKeys.profile_photos_load_failed.t(context),
              message: (state.errorMessage ?? LocaleKeys.errors_generic).t(
                context,
              ),
              retryLabel: LocaleKeys.profile_retry.t(context),
              onRetry: context.read<ProfilePhotosCubit>().load,
            );
          }
          return _PhotosGrid(state: state);
        },
      ),
    );
  }

  void _onEvent(BuildContext context, ProfilePhotosState state) {
    final (message, type) = switch (state.event) {
      ProfilePhotoEvent.uploaded => (
        LocaleKeys.profile_photos_uploaded_pending.t(context),
        SnackBarType.success,
      ),
      ProfilePhotoEvent.deleted => (
        LocaleKeys.profile_photos_deleted.t(context),
        SnackBarType.success,
      ),
      ProfilePhotoEvent.mainChanged => (
        LocaleKeys.profile_photos_main_changed.t(context),
        SnackBarType.success,
      ),
      ProfilePhotoEvent.maxReached => (
        LocaleKeys.profile_photos_max_reached.t(context),
        SnackBarType.info,
      ),
      ProfilePhotoEvent.validationFailure ||
      ProfilePhotoEvent.actionFailure => (
        (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
        SnackBarType.error,
      ),
      ProfilePhotoEvent.none => ('', SnackBarType.info),
    };
    if (message.isEmpty) return;
    AppSnackBar.show(context, message: message, type: type);
  }
}

class _PhotosGrid extends StatelessWidget {
  const _PhotosGrid({required this.state});

  final ProfilePhotosState state;

  @override
  Widget build(BuildContext context) {
    final showAdd = state.canAddMore;
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: context.read<ProfilePhotosCubit>().load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(QeranSpacing.s16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: QeranSpacing.s12,
          mainAxisSpacing: QeranSpacing.s12,
          childAspectRatio: 0.76,
        ),
        itemCount: state.images.length + (showAdd ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.images.length) {
            return _AddPhotoTile(enabled: !state.isBusy);
          }
          final image = state.images[index];
          return _PhotoTile(
            key: ValueKey('managed-photo-${image.id}'),
            image: image,
            busy: state.inFlightImageId == image.id,
            actionsEnabled: !state.isBusy,
          );
        },
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.creamSurface,
      borderRadius: QeranRadii.cardR,
      child: InkWell(
        borderRadius: QeranRadii.cardR,
        onTap: enabled
            ? () => PhotoPickerBottomSheet.show(
                context,
                onImagePicked: context.read<ProfilePhotosCubit>().addImage,
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: QeranRadii.cardR,
            border: Border.all(color: QeranColors.wine12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_a_photo_outlined,
                color: QeranColors.wine,
                size: 34,
              ),
              QeranSpacing.vs8,
              Text(
                LocaleKeys.profile_photos_add.t(context),
                style: QeranTypography.label.copyWith(color: QeranColors.wine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.image,
    required this.busy,
    required this.actionsEnabled,
  });

  final OwnerImage image;
  final bool busy;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: QeranRadii.cardR,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LikeBlurredImage(
            url: image.url,
            blur: false,
            size: null,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.zero,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, QeranColors.wine80],
              ),
            ),
          ),
          PositionedDirectional(
            top: QeranSpacing.s8,
            start: QeranSpacing.s8,
            child: _PhotoBadge(
              label: image.isApproved
                  ? (image.isProfile
                        ? LocaleKeys.profile_photos_main.t(context)
                        : null)
                  : LocaleKeys.profile_photos_pending.t(context),
              pending: !image.isApproved,
            ),
          ),
          PositionedDirectional(
            start: QeranSpacing.s8,
            end: QeranSpacing.s8,
            bottom: QeranSpacing.s8,
            child: Row(
              children: [
                if (!image.isProfile)
                  Expanded(
                    child: _TileAction(
                      icon: Icons.star_outline_rounded,
                      label: LocaleKeys.profile_photos_make_main.t(context),
                      onTap: actionsEnabled
                          ? () => context.read<ProfilePhotosCubit>().setMain(
                              image.id,
                            )
                          : null,
                    ),
                  ),
                if (!image.isProfile) QeranSpacing.hs8,
                _TileAction(
                  icon: Icons.delete_outline_rounded,
                  label: LocaleKeys.common_delete.t(context),
                  danger: true,
                  onTap: actionsEnabled ? () => _delete(context) : null,
                ),
              ],
            ),
          ),
          if (busy)
            const ColoredBox(
              color: QeranColors.overlayTintDark,
              child: Center(
                child: QeranLoader.inline(color: QeranColors.paper),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await QeranConfirmDialog.show(
      context,
      title: LocaleKeys.profile_photos_delete_title.t(context),
      message: LocaleKeys.profile_photos_delete_message.t(context),
      confirmLabel: LocaleKeys.common_delete.t(context),
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await context.read<ProfilePhotosCubit>().deleteImage(image.id);
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label, required this.pending});

  final String? label;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: pending ? QeranColors.goldDeep : QeranColors.wine,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        label!,
        style: QeranTypography.caption.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger ? QeranColors.danger : QeranColors.paper,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: danger ? QeranColors.paper : QeranColors.wine,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QeranTypography.caption.copyWith(
                    color: danger ? QeranColors.paper : QeranColors.wine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
