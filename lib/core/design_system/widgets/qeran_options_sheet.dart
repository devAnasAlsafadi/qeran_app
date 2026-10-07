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
/// share one look and each offers only what the server allows. An optional
/// [title] heads the rows («إضافة صور») and an optional [note] follows them
/// (the limits that apply); a ⋮ menu has neither.
abstract final class QeranOptionsSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required List<QeranOption<T>> options,
    String? title,
    String? note,
  }) => showModalBottomSheet<T>(
    context: context,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) =>
        _QeranOptionsSheetBody<T>(options: options, title: title, note: note),
  );
}

class _QeranOptionsSheetBody<T> extends StatelessWidget {
  final List<QeranOption<T>> options;
  final String? title;
  final String? note;

  const _QeranOptionsSheetBody({required this.options, this.title, this.note});

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s12,
    QeranSpacing.s12,
    QeranSpacing.s12,
    QeranSpacing.s16,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: QeranSheetHandle()),
            QeranSpacing.vs12,
            if (title case final String heading) _SheetText.title(heading),
            for (final option in options)
              QeranOptionRow(
                icon: option.icon,
                label: option.label,
                danger: option.danger,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            if (note case final String limits) _SheetText.note(limits),
          ],
        ),
      ),
    );
  }
}

/// The sheet's title or note: full width, from the start edge.
class _SheetText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final EdgeInsets padding;

  _SheetText.title(this.text)
    : style = QeranTypography.title.copyWith(color: QeranColors.inkStrong),
      padding = const EdgeInsets.fromLTRB(8, 4, 8, 8);

  _SheetText.note(this.text)
    : style = QeranTypography.label.copyWith(color: QeranColors.inkMuted),
      padding = const EdgeInsets.fromLTRB(8, 8, 8, 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Text(text, style: style),
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
