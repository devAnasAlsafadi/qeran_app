import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/features/support/domain/entities/support_category.dart';
import 'package:qeran/features/support/presentation/blocs/support_cubit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../widgets/settings_screen_header.dart';
import '../widgets/support_type_field.dart';

/// Help & Support form. Loads the backend problem-type list, then submits a
/// real ticket via [SupportCubit]; the limit / validation / category errors
/// surface as toasts (no fake success).
class SettingsSupportScreen extends StatelessWidget {
  const SettingsSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupportCubit>(
      create: (_) => sl<SupportCubit>()..loadCategories(),
      child: const _SupportBody(),
    );
  }
}

class _SupportBody extends StatefulWidget {
  const _SupportBody();

  @override
  State<_SupportBody> createState() => _SupportBodyState();
}

class _SupportBodyState extends State<_SupportBody> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _details = TextEditingController();
  int? _categoryId;

  static const int _subjectMax = 200;
  static const int _detailsMax = 4000;

  @override
  void dispose() {
    _subject.dispose();
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final categoryId = _categoryId;
    final subject = _subject.text.trim();
    final details = _details.text.trim();
    if (categoryId == null || subject.isEmpty || details.isEmpty) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.settings_support_validation.t(context),
        type: SnackBarType.info,
      );
      return;
    }
    context.read<SupportCubit>().submit(
      categoryId: categoryId,
      subject: subject,
      details: details,
    );
  }

  void _onState(BuildContext context, SupportState state) {
    switch (state.submitStatus) {
      case SupportSubmitStatus.success:
        AppSnackBar.show(
          context,
          message: state.submitMessage.t(context),
          type: SnackBarType.success,
        );
        NavigationManager.pop(context);
      case SupportSubmitStatus.failure:
        AppSnackBar.show(
          context,
          message: state.submitMessage.t(context),
          type: state.submitLimitReached
              ? SnackBarType.info
              : SnackBarType.error,
        );
      case SupportSubmitStatus.idle:
      case SupportSubmitStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsScreenHeader(
              title: LocaleKeys.settings_support_title.t(context),
            ),
            Expanded(
              child: BlocConsumer<SupportCubit, SupportState>(
                listenWhen: (prev, curr) =>
                    prev.eventVersion != curr.eventVersion,
                listener: _onState,
                builder: (context, state) {
                  return _Form(
                    categories: state.categories,
                    categoriesStatus: state.categoriesStatus,
                    categoriesErrorKey: state.categoriesErrorKey,
                    selectedId: _categoryId,
                    subject: _subject,
                    details: _details,
                    subjectMax: _subjectMax,
                    detailsMax: _detailsMax,
                    loading: state.isSubmitting,
                    onRetryCategories: context
                        .read<SupportCubit>()
                        .loadCategories,
                    onCategoryChanged: (id) => setState(() => _categoryId = id),
                    onSubmit: _submit,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final List<SupportCategory> categories;
  final SupportCategoriesStatus categoriesStatus;
  final String categoriesErrorKey;
  final int? selectedId;
  final TextEditingController subject;
  final TextEditingController details;
  final int subjectMax;
  final int detailsMax;
  final bool loading;
  final VoidCallback onRetryCategories;
  final ValueChanged<int> onCategoryChanged;
  final VoidCallback onSubmit;

  const _Form({
    required this.categories,
    required this.categoriesStatus,
    required this.categoriesErrorKey,
    required this.selectedId,
    required this.subject,
    required this.details,
    required this.subjectMax,
    required this.detailsMax,
    required this.loading,
    required this.onRetryCategories,
    required this.onCategoryChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QeranSpacing.vs8,
                Text(
                  LocaleKeys.settings_support_intro.t(context),
                  style: QeranTypography.bodySm.copyWith(
                    color: QeranColors.inkMuted,
                  ),
                ),
                QeranSpacing.vs24,
                _Label(LocaleKeys.settings_support_type_label.t(context)),
                QeranSpacing.vs8,
                _CategoryFieldState(
                  status: categoriesStatus,
                  errorKey: categoriesErrorKey,
                  categories: categories,
                  selectedId: selectedId,
                  onChanged: onCategoryChanged,
                  onRetry: onRetryCategories,
                ),
                QeranSpacing.vs16,
                _Label(LocaleKeys.settings_support_subject_label.t(context)),
                QeranSpacing.vs8,
                QeranTextField(
                  controller: subject,
                  hint: LocaleKeys.settings_support_subject_hint.t(context),
                  keyboardType: TextInputType.text,
                  maxLength: subjectMax,
                ),
                QeranSpacing.vs16,
                _Label(LocaleKeys.settings_support_details_label.t(context)),
                QeranSpacing.vs8,
                QeranTextField(
                  controller: details,
                  hint: LocaleKeys.settings_support_details_hint.t(context),
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  maxLength: detailsMax,
                ),
                QeranSpacing.vs24,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s20,
            QeranSpacing.s8,
            QeranSpacing.s20,
            QeranSpacing.s16,
          ),
          child: Column(
            children: [
              QeranButton(
                label: LocaleKeys.settings_support_submit.t(context),
                variant: QeranButtonVariant.primaryWine,
                loading: loading,
                onPressed:
                    loading ||
                        categoriesStatus != SupportCategoriesStatus.loaded
                    ? null
                    : onSubmit,
              ),
              QeranSpacing.vs12,
              Text(
                LocaleKeys.settings_support_footer.t(context),
                textAlign: TextAlign.center,
                style: QeranTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryFieldState extends StatelessWidget {
  const _CategoryFieldState({
    required this.status,
    required this.errorKey,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    required this.onRetry,
  });

  final SupportCategoriesStatus status;
  final String errorKey;
  final List<SupportCategory> categories;
  final int? selectedId;
  final ValueChanged<int> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      SupportCategoriesStatus.loading => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s16),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          border: Border.all(color: QeranColors.wine08),
        ),
        child: const QeranSkeleton(width: 180, height: 16),
      ),
      SupportCategoriesStatus.failure => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.fromSTEB(
          QeranSpacing.s16,
          QeranSpacing.s8,
          QeranSpacing.s8,
          QeranSpacing.s8,
        ),
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          border: Border.all(color: QeranColors.danger12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: QeranColors.danger,
              size: 20,
            ),
            QeranSpacing.hs8,
            Expanded(
              child: Text(
                errorKey.t(context),
                style: QeranTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(LocaleKeys.settings_support_retry.t(context)),
            ),
          ],
        ),
      ),
      SupportCategoriesStatus.loaded => SupportTypeField(
        categories: categories,
        selectedId: selectedId,
        onChanged: onChanged,
      ),
    };
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: QeranTypography.label);
  }
}
