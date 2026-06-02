import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../widgets/settings_screen_header.dart';

/// App-language picker. Reuses EasyLocalization's `setLocale` (the
/// existing language-switch mechanism) — UI only, no new logic.
class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  static const Locale _ar = Locale('ar');
  static const Locale _en = Locale('en');

  late Locale _selected = context.locale;

  void _save() {
    if (_selected != context.locale) {
      context.setLocale(_selected);
    }
    NavigationManager.pop(context);
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
              title: LocaleKeys.settings_language_title.t(context),
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
                      LocaleKeys.settings_language_prompt.t(context),
                      style: QeranTypography.bodySm
                          .copyWith(color: QeranColors.inkMuted),
                    ),
                    QeranSpacing.vs16,
                    QeranCard(
                      padding: const EdgeInsets.all(QeranSpacing.s20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleKeys.settings_language_section.t(context),
                            style: QeranTypography.label,
                          ),
                          QeranSpacing.vs12,
                          _LanguageOption(
                            label: LocaleKeys.settings_lang_arabic.t(context),
                            native: 'العربية',
                            selected: _selected == _ar,
                            onTap: () => setState(() => _selected = _ar),
                          ),
                          const _OptionDivider(),
                          _LanguageOption(
                            label: LocaleKeys.settings_lang_english.t(context),
                            native: 'English',
                            selected: _selected == _en,
                            onTap: () => setState(() => _selected = _en),
                          ),
                        ],
                      ),
                    ),
                    QeranSpacing.vs16,
                    Text(
                      LocaleKeys.settings_language_note.t(context),
                      style: QeranTypography.caption,
                    ),
                    QeranSpacing.vs32,
                    CustomButton(
                      text: LocaleKeys.settings_save_changes.t(context),
                      onPressed: _save,
                    ),
                    QeranSpacing.vs24,
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

class _LanguageOption extends StatelessWidget {
  final String label;
  final String native;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.native,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: QeranTypography.subtitle),
                  Text(
                    native,
                    style: QeranTypography.caption,
                  ),
                ],
              ),
            ),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.wine : QeranColors.hairline,
          width: 2,
        ),
      ),
      child: selected
          ? const Center(
              child: SizedBox(
                width: 10,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QeranColors.wine,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _OptionDivider extends StatelessWidget {
  const _OptionDivider();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: QeranColors.divider),
    );
  }
}
