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
    required this.allowsMultiple,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onQueryChanged;
  final List<QeranSelectableOption> rows;
  final bool Function(String value) isSelected;
  final void Function(String value) onTap;
  final bool allowsMultiple;

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
                        allowsMultiple: allowsMultiple,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The collapsed dropdown header: summarizes the selection, or falls back to
/// the facet label as a placeholder. Wine border + wine bold text once
/// anything is chosen.
class _Trigger extends StatelessWidget {
  const _Trigger({
    required this.label,
    required this.selectedText,
    required this.isExpanded,
    required this.onTap,
  });

  final String label;
  final String? selectedText;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = selectedText != null;
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.controlR,
          border: Border.all(
            color: active
                ? QeranColors.wine
                : QeranColors.inkFaint.withValues(alpha: 0.3),
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedText ?? label,
                style: QeranTypography.body.copyWith(
                  color: active ? QeranColors.wine : QeranColors.inkMuted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: active ? QeranColors.wine : QeranColors.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}
