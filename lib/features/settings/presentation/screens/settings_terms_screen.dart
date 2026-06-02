import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../widgets/settings_screen_header.dart';

/// Terms & Privacy — static sectioned content. Placeholder copy for now;
/// the real legal text will replace the `settings_terms_*` locale keys
/// when the backend/content team supplies it.
class SettingsTermsScreen extends StatelessWidget {
  const SettingsTermsScreen({super.key});

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
              title: LocaleKeys.settings_terms_title.t(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  QeranSpacing.s20,
                  0,
                  QeranSpacing.s20,
                  QeranSpacing.s32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.settings_terms_updated.t(context),
                      style: QeranTypography.caption,
                    ),
                    QeranSpacing.vs24,
                    _Section(
                      title: LocaleKeys.settings_terms_s1_title.t(context),
                      body: LocaleKeys.settings_terms_s1_body.t(context),
                    ),
                    _Section(
                      title: LocaleKeys.settings_terms_s2_title.t(context),
                      body: LocaleKeys.settings_terms_s2_body.t(context),
                    ),
                    _Section(
                      title: LocaleKeys.settings_terms_s3_title.t(context),
                      body: LocaleKeys.settings_terms_s3_body.t(context),
                    ),
                    _Section(
                      title: LocaleKeys.settings_terms_s4_title.t(context),
                      body: LocaleKeys.settings_terms_s4_body.t(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: QeranSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: QeranTypography.title),
          QeranSpacing.vs8,
          Text(
            body,
            textAlign: TextAlign.start,
            style: QeranTypography.body.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
