import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/features/questionnaire/presentation/widgets/question_progress_bar.dart';

import '../../blocs/photo_upload/photo_upload_cubit.dart';
import '../../blocs/photo_upload/photo_upload_state.dart';


class UploadImageProfileScreen extends StatefulWidget {
  const UploadImageProfileScreen({super.key});

  @override
  State<UploadImageProfileScreen> createState() =>
      _UploadImageProfileScreenState();
}

class _UploadImageProfileScreenState extends State<UploadImageProfileScreen> {
  late PhotoUploadCubit _cubit;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cubit = sl<PhotoUploadCubit>();
  }

  /// Pick a single image from gallery or camera
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      _cubit.addImage(File(pickedFile.path));
      setState(() {});
    }
  }

  /// Remove image at index
  void _removeImage(int index) {
    _cubit.removeImage(index);
    setState(() {});
  }

  /// Mark image at index as primary
  void _setPrimary(int index) {
    _cubit.setPrimary(index);
    setState(() {});
  }

  /// Upload images
  void _onUpload() {
    _cubit.uploadImages();
  }

  /// Skip upload
  void _onSkip() async {
    await _cubit.skipUpload();
    if (!mounted) return;
    NavigationManager.pushNamedAndRemoveUntil(
      context,
      RouteNames.homeScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhotoUploadCubit, PhotoUploadState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state is PhotoUploadSuccess) {
          NavigationManager.pushNamedAndRemoveUntil(
            context,
            RouteNames.homeScreen,
          );
        } else if (state is PhotoUploadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Progress Bar ──
                const QuestionProgressBar(
                  currentQuestion: 7,
                  totalQuestions: 7,
                ),
                const SizedBox(height: AppDimens.p24),

                // ── Back Arrow + Title Row ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.p16),
                    Text(
                      'أضف صور',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.p8),

                // ── Subtitle ──
                Text(
                  'تحتاج إلى رفع 3 صور على الأقل لمتابعة إكمال ملفك الشخصي',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.p32),

                // ── 6-Slot Grid ──
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppDimens.p12,
                      mainAxisSpacing: AppDimens.p12,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final hasImage = index < _cubit.images.length;
                      final isPrimary = _cubit.primaryIndex == index;

                      if (!hasImage) {
                        return _buildEmptySlot(index);
                      }

                      return _buildFilledSlot(
                        index: index,
                        file: _cubit.images[index],
                        isPrimary: isPrimary,
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimens.p24),

                // ── Info Slot (Photo Guidelines) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Show photo guidelines dialog
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Photo',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'guidelines',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.p24),

                // ── CTA Buttons ──
                BlocBuilder<PhotoUploadCubit, PhotoUploadState>(
                  bloc: _cubit,
                  builder: (context, state) {
                    final isLoading = state is PhotoUploadInProgress;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomButton(
                          text: isLoading ? 'جاري الرفع...' : 'أضف صور',
                          onPressed:
                              _cubit.images.isNotEmpty && !isLoading
                                  ? _onUpload
                                  : null,
                        ),
                        const SizedBox(height: AppDimens.p12),
                        TextButton(
                          onPressed: isLoading ? null : _onSkip,
                          child: Text(
                            'تخطي',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build an empty slot with add button
  Widget _buildEmptySlot(int index) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(AppDimens.borderRadius12),
          border: Border.all(
            color: AppColors.border,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dashed border effect
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.borderRadius12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add,
                  color: AppColors.textSecondary,
                  size: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build a filled slot with image thumbnail and controls
  Widget _buildFilledSlot({
    required int index,
    required File file,
    required bool isPrimary,
  }) {
    return Stack(
      children: [
        // Image thumbnail
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.borderRadius12),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Main badge (only for primary image)
        if (isPrimary)
          Positioned(
            bottom: AppDimens.p8,
            left: AppDimens.p8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p8,
                vertical: AppDimens.p4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Main',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Remove button overlay
        Positioned(
          top: AppDimens.p4,
          right: AppDimens.p4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),

        // Set as primary tap area (if not already primary)
        if (!isPrimary)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _setPrimary(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius:
                        BorderRadius.circular(AppDimens.borderRadius12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
