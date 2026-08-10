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
///
/// The switch is applied only AFTER the sheet is fully gone, and the sheet is
/// handed a plain [Locale] rather than the caller's context. Both matter: the
/// locale it sets is what destroys the screen it was opened from — both shells
/// mount their tabs inside a `LocaleRebuildScope`, which discards the subtree
/// on a language change. A sheet holding that context would be reading a
/// deactivated element the moment it repainted during its own exit animation.
Future<void> showSettingsLanguageSheet(BuildContext context) async {
  final current = context.locale;
  final selected = await showQeranBottomSheet<Locale>(
    context: context,
    builder: (_) => _LanguageSheet(current: current),
  );
  if (selected == null || selected == current) return;
  // The host outlives the sheet — it is torn down by the line below, not
  // before it — but it can still be popped while the sheet is open.
  if (!context.mounted) return;
  await context.setLocale(selected);
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});

  /// Captured before the sheet opened. A value, not a context: the locale is
  /// read once up front so nothing here depends on an ancestor that the
  /// selection is about to destroy.
  final Locale current;

  /// Returns the choice to the caller, which applies it once the sheet has
  /// finished closing.
  void _select(BuildContext sheetContext, Locale locale) {
    Navigator.of(sheetContext).pop(locale);
  }

  @override
  Widget build(BuildContext context) {
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
