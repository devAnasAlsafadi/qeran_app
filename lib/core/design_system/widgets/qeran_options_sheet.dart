import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';
import 'qeran_sheet_handle.dart';

/// One row of a [QeranOptionsSheet]: what it shows, and the [value] the sheet
/// returns when it's tapped. [danger] paints it in the destructive colour
/// (Block, Delete).
class QeranOption<T> {
  final IconData icon;
  final String label;
  final T value;
  final bool danger;

  const QeranOption({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
  });
}

/// The options menu behind a ⋮ button — a bottom sheet with a handle and one
/// row per option. Resolves to the tapped option's value, or null when it's
/// dismissed. The rows are the caller's, so a profile and a Community post
/// share one look and each offers only what the server allows.
abstract final class QeranOptionsSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required List<QeranOption<T>> options,
  }) =>
      showModalBottomSheet<T>(
        context: context,
        backgroundColor: QeranColors.paper,
        shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
        builder: (_) => _QeranOptionsSheetBody<T>(options: options),
      );
}

class _QeranOptionsSheetBody<T> extends StatelessWidget {
  final List<QeranOption<T>> options;

  const _QeranOptionsSheetBody({required this.options});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s12,
          QeranSpacing.s12,
          QeranSpacing.s12,
          QeranSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: QeranSheetHandle()),
            QeranSpacing.vs12,
            for (final option in options)
              QeranOptionRow(
                icon: option.icon,
                label: option.label,
                danger: option.danger,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
          ],
        ),
      ),
    );
  }
}

/// A tappable icon + label row, wine or — for a destructive action — danger.
class QeranOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const QeranOptionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? QeranColors.danger : QeranColors.wine;
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.cardR,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            QeranSpacing.hs12,
            Text(
              label,
              style: QeranTypography.body.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
