import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/presentation/widgets/filter_expandable_shell.dart';

/// Numeric single-value filter leaf for explore `height` / `weight` questions
/// — Tariq's contract treats these as EXACT-match on a numeric `TextAnswer`
/// (not a range). A digits-only field inside the shared [FilterExpandableShell];
/// emits the trimmed number string (empty clears the filter). Discovery's
/// range treatment of height/weight is untouched — this is explore-only.
class MatchmakerExploreNumberField extends StatefulWidget {
  final DiscoveryFilterQuestion question;
  final SingleValueSelection? selection;
  final ValueChanged<String> onChanged;

  const MatchmakerExploreNumberField({
    super.key,
    required this.question,
    required this.selection,
    required this.onChanged,
  });

  @override
  State<MatchmakerExploreNumberField> createState() =>
      _MatchmakerExploreNumberFieldState();
}

class _MatchmakerExploreNumberFieldState
    extends State<MatchmakerExploreNumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.selection?.value ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilterExpandableShell(
      label: widget.question.label,
      bodyBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.start,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => widget.onChanged(v.trim()),
            style: QeranTypography.subtitle,
            decoration: InputDecoration(
              filled: true,
              fillColor: QeranColors.paper,
              suffixText: widget.question.unit,
              suffixStyle: QeranTypography.caption
                  .copyWith(color: QeranColors.inkMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: QeranSpacing.s12,
                vertical: QeranSpacing.s12,
              ),
              border: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.hairline),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.hairline),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: QeranRadii.controlR,
                borderSide: BorderSide(color: QeranColors.wine),
              ),
            ),
          ),
        );
      },
    );
  }
}
