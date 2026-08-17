part of 'qeran_filter_searchable_facet.dart';

/// The expanded panel: search field over a bounded, scrollable checklist.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.controller,
    required this.focusNode,
    required this.onQueryChanged,
    required this.rows,
    required this.isSelected,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onQueryChanged;
  final List<QeranSelectableOption> rows;
  final bool Function(String value) isSelected;
  final void Function(String value) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.inkFaint.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QeranTextField(
            controller: controller,
            focusNode: focusNode,
            hint: LocaleKeys.filters_search_hint.t(context),
            prefix: const Icon(
              Icons.search_rounded,
              color: QeranColors.inkFaint,
              size: 20,
            ),
            onChanged: onQueryChanged,
          ),
          QeranSpacing.vs8,
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: rows.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: QeranSpacing.s12,
                    ),
                    child: Text(
                      LocaleKeys.filters_search_empty.t(context),
                      style: QeranTypography.caption.copyWith(
                        color: QeranColors.inkMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final o = rows[i];
                      return _OptionRow(
                        label: o.display,
                        selected: isSelected(o.value),
                        onTap: () => onTap(o.value),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One tappable checklist row — wine check + wine label when selected, faint
/// outline + neutral label otherwise.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
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
