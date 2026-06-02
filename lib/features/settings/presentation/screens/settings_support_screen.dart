import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/widgets/app_text_form_field.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/support_cubit.dart';
import '../widgets/settings_screen_header.dart';
import '../widgets/support_type_field.dart';

/// Help & Support form. Submit is wired to [SupportCubit] — a placeholder
/// until the backend endpoint lands (see that cubit's contract note).
class SettingsSupportScreen extends StatelessWidget {
  const SettingsSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SupportCubit>(
      create: (_) => SupportCubit(),
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
  String? _typeKey;

  @override
  void dispose() {
    _subject.dispose();
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    final type = _typeKey;
    final subject = _subject.text.trim();
    final details = _details.text.trim();
    if (type == null || subject.isEmpty || details.isEmpty) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.settings_support_validation.t(context),
        type: SnackBarType.info,
      );
      return;
    }
    context
        .read<SupportCubit>()
        .submit(type: type, subject: subject, details: details);
  }

  void _onState(BuildContext context, SupportState state) {
    if (state.status != SupportStatus.success) return;
    AppSnackBar.show(
      context,
      message: LocaleKeys.settings_support_success.t(context),
      type: SnackBarType.success,
    );
    NavigationManager.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<SupportCubit, SupportState>(
          listener: _onState,
          builder: (context, state) {
            final loading = state.status == SupportStatus.submitting;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsScreenHeader(
                  title: LocaleKeys.settings_support_title.t(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QeranSpacing.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QeranSpacing.vs8,
                        Text(
                          LocaleKeys.settings_support_intro.t(context),
                          style: QeranTypography.bodySm
                              .copyWith(color: QeranColors.inkMuted),
                        ),
                        QeranSpacing.vs24,
                        _Label(LocaleKeys.settings_support_type_label.t(context)),
                        QeranSpacing.vs8,
                        SupportTypeField(
                          selectedKey: _typeKey,
                          onChanged: (k) => setState(() => _typeKey = k),
                        ),
                        QeranSpacing.vs16,
                        _Label(
                          LocaleKeys.settings_support_subject_label.t(context),
                        ),
                        QeranSpacing.vs8,
                        AppTextFormField(
                          controller: _subject,
                          hintText: LocaleKeys.settings_support_subject_hint
                              .t(context),
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                        QeranSpacing.vs16,
                        _Label(
                          LocaleKeys.settings_support_details_label.t(context),
                        ),
                        QeranSpacing.vs8,
                        AppTextFormField(
                          controller: _details,
                          hintText: LocaleKeys.settings_support_details_hint
                              .t(context),
                          obscureText: false,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
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
                      CustomButton(
                        text: LocaleKeys.settings_support_submit.t(context),
                        isLoading: loading,
                        onPressed: loading ? null : _submit,
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
          },
        ),
      ),
    );
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
