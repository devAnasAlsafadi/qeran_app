import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';

const Locale _ar = Locale('ar');
const Locale _en = Locale('en');

/// The app-language picker as a live bottom sheet (replaces the former
/// full-screen Save-button page). Tapping an option switches the locale
/// immediately (the whole app flips RTL↔LTR) and closes the sheet — no Save.
/// Persistence is EasyLocalization's own `setLocale` store; UI only.
Future<void> showSettingsLanguageSheet(BuildContext context) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => _LanguageSheet(host: context),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.host});

  /// The settings-screen context — used to apply the locale after the sheet
  /// pops (its own context is torn down by then).
  final BuildContext host;

  void _select(BuildContext sheetContext, Locale locale) {
    Navigator.of(sheetContext).pop();
    if (locale != host.locale) host.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final current = host.locale;
    return QeranBottomSheetScaffold(
      title: LocaleKeys.settings_language_title.t(context),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s4,
          QeranSpacing.s20,
          QeranSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: LocaleKeys.settings_lang_arabic.t(context),
              native: 'العربية',
              selected: current == _ar,
              onTap: () => _select(context, _ar),
            ),
            QeranSpacing.vs8,
            _LanguageOption(
              label: LocaleKeys.settings_lang_english.t(context),
              native: 'English',
              selected: current == _en,
              onTap: () => _select(context, _en),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.native,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String native;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.cardR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: selected ? QeranColors.creamSurface : QeranColors.paper,
            borderRadius: QeranRadii.cardR,
            border: Border.all(
              color: selected ? QeranColors.gold : QeranColors.wine08,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: QeranTypography.subtitle),
                    Text(
                      native,
                      style: QeranTypography.caption.copyWith(
                        color: QeranColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: QeranColors.goldDeep,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
