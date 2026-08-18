part of 'qeran_filter_searchable_facet.dart';

/// Checkbox glyphs for a many-of facet, radio glyphs for a one-of facet — the
/// convention `QuestionCheckboxWidget` / `QuestionSelectWidget` already set in
/// the questionnaire, so a user who picked squares at signup sees squares when
/// filtering.
///
/// Both pairs keep an outline in the UNSELECTED state: an indicator that
/// differs from nothing at all only by presence is a weak affordance, and a
/// checkmark alone would have no empty form.
///
/// Deliberately local to this file rather than hoisted somewhere shared — the
/// variance is one glyph pair, and the chip facet (the only other filter facet)
/// signals selection by fill and has no indicator to unify with. Worth
/// promoting if a third consumer ever appears.
IconData _multiSelectionIndicator({required bool selected}) => selected
    ? Icons.check_box_rounded
    : Icons.check_box_outline_blank_rounded;

IconData _singleSelectionIndicator({required bool selected}) => selected
    ? Icons.check_circle_rounded
    : Icons.circle_outlined;

/// One tappable checklist row — wine indicator + wine label when selected,
/// faint outline + neutral label otherwise. Only the indicator's SHAPE varies
/// with [allowsMultiple]; its colour and size do not.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.allowsMultiple,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool allowsMultiple;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: QeranSpacing.s12,
          horizontal: QeranSpacing.s8,
        ),
        child: Row(
          children: [
            // ONE colour expression and ONE size for both shapes: the multi
            // indicator cannot drift from the single one, because there is no
            // second place to change it.
            Icon(
              allowsMultiple
                  ? _multiSelectionIndicator(selected: selected)
                  : _singleSelectionIndicator(selected: selected),
              color: selected ? QeranColors.wine : QeranColors.inkFaint,
              size: 22,
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                label,
                style: QeranTypography.body.copyWith(
                  color: selected ? QeranColors.wine : QeranColors.inkStrong,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
