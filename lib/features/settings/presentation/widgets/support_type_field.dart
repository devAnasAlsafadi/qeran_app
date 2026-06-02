import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The problem-type selector for the support form: a tappable field
/// (matching the unified text-field look) that opens a bottom sheet of
/// options. [selectedKey] is one of the `settings_support_type_*` keys.
class SupportTypeField extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onChanged;

  const SupportTypeField({
    super.key,
    required this.selectedKey,
    required this.onChanged,
  });

  static const List<String> _optionKeys = [
    LocaleKeys.settings_support_type_matchmaker,
    LocaleKeys.settings_support_type_technical,
    LocaleKeys.settings_support_type_account,
    LocaleKeys.settings_support_type_other,
  ];

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedKey != null;
    final label = hasValue
        ? selectedKey!.t(context)
        : LocaleKeys.settings_support_type_placeholder.t(context);
    return Material(
      color: QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        borderRadius: QeranRadii.controlR,
        onTap: () => _openPicker(context),
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

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: QeranColors.creamCanvas,
      shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: QeranSpacing.s12),
            for (final key in _optionKeys)
              _PickerRow(
                label: key.t(sheetCtx),
                selected: key == selectedKey,
                onTap: () => Navigator.of(sheetCtx).pop(key),
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
  final bool selected;
  final VoidCallback onTap;
  const _PickerRow({
    required this.label,
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
