import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_search_field.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/question_option_entity.dart';

/// Renders a single-select list of radio options (matching Figma reference).
///
/// A long list gets a search box above it. Filtering is CLIENT-SIDE over the
/// options the backend already sent — `GET /api/questions` returns every option
/// inline with no paging, so what is filtered is the whole list and a search
/// can never hide a match that lives on some unfetched page.
class QuestionSelectWidget extends StatefulWidget {
  final QuestionEntity question;
  final String? selectedOptionId;
  final ValueChanged<String> onChanged;

  const QuestionSelectWidget({
    super.key,
    required this.question,
    required this.selectedOptionId,
    required this.onChanged,
  });

  @override
  State<QuestionSelectWidget> createState() => _QuestionSelectWidgetState();
}

class _QuestionSelectWidgetState extends State<QuestionSelectWidget> {
  /// Where a list stops being scannable by eye. Nationality and country of
  /// residence are every country on earth and need the box; gender and marital
  /// status are read faster without one in the way.
  static const int _searchThreshold = 15;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _showsSearch =>
      widget.question.options.length >= _searchThreshold;

  /// The options passing the current query. Case-insensitive and trimmed, so
  /// a trailing space or a capital never hides a country that is right there.
  List<QuestionOptionEntity> get _visibleOptions {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.question.options;
    return widget.question.options
        .where((option) => option.text.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final options = _visibleOptions;
    // Only a QUERY produces "no matches". A question the backend sent with no
    // options at all renders nothing here, exactly as it did before search —
    // that is a data gap, not an empty search result.
    final searchedToNothing = options.isEmpty && _query.trim().isNotEmpty;
    return Column(
      children: [
        if (_showsSearch) ...[
          QeranSearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
          QeranSpacing.vs8,
        ],
        if (searchedToNothing)
          const _NoMatches()
        else
          ...options.map(
            (option) => _OptionRow(
              label: option.text,
              isSelected: widget.selectedOptionId == option.id,
              onTap: () => widget.onChanged(option.id),
            ),
          ),
      ],
    );
  }
}

/// Shown when a query matches nothing — reuses the filter sheet's wording so
/// the two searches answer an empty result with one sentence.
class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Text(
        LocaleKeys.filters_search_empty.t(context),
        style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
      ),
    );
  }
}

/// One tappable row: the radio circle and its label.
///
/// The circle is drawn rather than taken from Material so it carries the
/// wine/hairline pair from the design system; the row leaves its own left/right
/// placement to the ambient direction, so AR mirrors it without a manual swap.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
        child: Row(
          children: [
            _RadioCircle(isSelected: isSelected),
            QeranSpacing.hs16,
            Expanded(
              child: Text(
                label,
                style: isSelected
                    ? QeranTypography.subtitle
                    : QeranTypography.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The selection indicator: a wine ring that fills with a wine dot when chosen.
class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? QeranColors.wine : QeranColors.hairline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.wine,
                ),
              ),
            )
          : null,
    );
  }
}
