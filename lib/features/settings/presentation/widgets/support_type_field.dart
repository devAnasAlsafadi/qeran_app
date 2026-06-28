import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/support/domain/entities/support_category.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The problem-type selector for the support form: a tappable field (matching
/// the unified text-field look) that opens a bottom sheet of backend-supplied
/// [categories]. [selectedId] is a `SupportCategory.id`.
class SupportTypeField extends StatelessWidget {
  final List<SupportCategory> categories;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  const SupportTypeField({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final selected = _selectedOf(categories);
    final hasValue = selected != null;
    final label = hasValue
        ? selected.localizedName(lang)
        : LocaleKeys.settings_support_type_placeholder.t(context);
    return Material(
      color: QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        borderRadius: QeranRadii.controlR,
        onTap: () => _openPicker(context, lang),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s16,
          ),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.controlR,
            border: Border.all(color: QeranColors.wine08),
          ),
          child: Row(
            children: [
              if (hasValue && selected.inlineIcon != null) ...[
                Text(selected.inlineIcon!, style: QeranTypography.subtitle),
                QeranSpacing.hs8,
              ],
              Expanded(
                child: Text(
                  label,
                  style: hasValue
                      ? QeranTypography.subtitle
                      : QeranTypography.body
                          .copyWith(color: QeranColors.inkMuted),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: QeranColors.wine,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SupportCategory? _selectedOf(List<SupportCategory> list) {
    for (final c in list) {
      if (c.id == selectedId) return c;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context, String lang) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: QeranColors.creamCanvas,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: QeranSpacing.s12),
            for (final c in categories)
              _PickerRow(
                label: c.localizedName(lang),
                icon: c.inlineIcon,
                selected: c.id == selectedId,
                onTap: () => Navigator.of(sheetCtx).pop(c.id),
              ),
            const SizedBox(height: QeranSpacing.s12),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class _PickerRow extends StatelessWidget {
  final String label;
  final String? icon;
  final bool selected;
  final VoidCallback onTap;
  const _PickerRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s20,
          vertical: QeranSpacing.s16,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Text(icon!, style: QeranTypography.subtitle),
              QeranSpacing.hs8,
            ],
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.start,
                style: selected
                    ? QeranTypography.subtitle
                    : QeranTypography.body,
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, color: QeranColors.wine),
          ],
        ),
      ),
    );
  }
}
