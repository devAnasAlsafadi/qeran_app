import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/widgets/exit_app_dialog.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import 'package:qeran/core/widgets/question_progress_bar.dart';

import '../../blocs/photo_upload/photo_upload_cubit.dart';
import '../../blocs/photo_upload/photo_upload_state.dart';
import 'widgets/empty_photo_slot.dart';
import 'widgets/filled_photo_slot.dart';
import 'widgets/photo_picker_bottom_sheet.dart';
import 'widgets/privacy_info_box.dart';

class UploadImageProfileScreen extends StatefulWidget {
  const UploadImageProfileScreen({super.key});

  @override
  State<UploadImageProfileScreen> createState() =>
      _UploadImageProfileScreenState();
}

class _UploadImageProfileScreenState extends State<UploadImageProfileScreen> {
  late final PhotoUploadCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PhotoUploadCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PhotoUploadCubit, PhotoUploadState>(
      bloc: _cubit,
      listener: _handleStateChanges,
      builder: (context, state) {
        final isUploading = state is PhotoUploadUploading;
        final imagePaths = state.imagePaths;
        final primaryIndex = state.primaryIndex;

        return OnboardingPopScope(
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: AppDimens.paddingAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const QuestionProgressBar(progress: 1.0),
                    const SizedBox(height: AppDimens.p16),

                    _buildHeader(isUploading: isUploading),
                    const SizedBox(height: AppDimens.p8),

                    _buildTitleArea(),
                    const SizedBox(height: AppDimens.p16),

                    const PrivacyInfoBox(),
                    const SizedBox(height: AppDimens.p24),

                    _buildPhotoGrid(
                      imagePaths: imagePaths,
                      primaryIndex: primaryIndex,
                      isUploading: isUploading,
                    ),

                    _buildUploadButton(
                      imagePaths: imagePaths,
                      isUploading: isUploading,
                    ),
                    const SizedBox(height: AppDimens.p12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, PhotoUploadState state) {
    if (state is PhotoUploadSuccess) {
      AppSnackBar.show(
        context,
        message: state.successMessage.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
    } else if (state is PhotoUploadFailure) {
      AppSnackBar.show(
        context,
        message: state.errorMessage.t(context),
        type: SnackBarType.error,
      );
    } else if (state is PhotoUploadValidationError) {
      AppSnackBar.show(
        context,
        message: state.errorMessage.t(context),
        type: SnackBarType.error,
      );
    }
  }

  Widget _buildHeader({required bool isUploading}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: isUploading ? null : () => ExitAppDialog.show(context),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        TextButton(
          onPressed: isUploading ? null : _cubit.skipUpload,
          child: Text(
            LocaleKeys.common_skip.t(context),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.auth_photo_upload_title.t(context),
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.p8),
        Text(
          LocaleKeys.auth_photo_upload_subtitle.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid({
    required List<String> imagePaths,
    required int primaryIndex,
    required bool isUploading,
  }) {
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppDimens.p16,
          mainAxisSpacing: AppDimens.p16,
          childAspectRatio: 0.9,
        ),
        itemCount: 5,
        itemBuilder: (context, index) {
          final hasImage = index < imagePaths.length;
          if (!hasImage) {
            return EmptyPhotoSlot(
              isUploading: isUploading,
              index: index,
              onAddTap: () => PhotoPickerBottomSheet.show(
                context,
                onImagePicked: _cubit.addImage,
              ),
            );
          }
          return FilledPhotoSlot(
            index: index,
            file: File(imagePaths[index]),
            isPrimary: primaryIndex == index,
            isUploading: isUploading,
            onRemove: () => _cubit.removeImage(index),
            onSetPrimary: () => _cubit.setPrimary(index),
          );
        },
      ),
    );
  }

  Widget _buildUploadButton({
    required List<String> imagePaths,
    required bool isUploading,
  }) {
    return CustomButton(
      text: LocaleKeys.auth_photo_upload_button.t(context),
      isLoading: isUploading,
      onPressed: imagePaths.isNotEmpty && !isUploading
          ? _cubit.uploadImages
          : null,
      backgroundColor: imagePaths.isNotEmpty
          ? AppColors.primary
          : AppColors.border,
    );
  }
}
