import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

/// Shared chrome for collapsible filter blocks (select / radio / checkbox).
///
/// Visual: a rounded cream card with the question label on the start edge
/// (right in Arabic, left in English) and a chevron on the opposite (end)
/// edge — both mirror automatically with the text direction.
class FilterExpandableShell extends StatefulWidget {
  final String label;
  final Widget Function(BuildContext context) bodyBuilder;
  final bool initiallyExpanded;

  const FilterExpandableShell({
    super.key,
    required this.label,
    required this.bodyBuilder,
    this.initiallyExpanded = false,
  });

  @override
  State<FilterExpandableShell> createState() => _FilterExpandableShellState();
}

class _FilterExpandableShellState extends State<FilterExpandableShell> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.controlR,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: QeranRadii.controlR,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QeranSpacing.s16,
                vertical: QeranSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.start,
                      style: QeranTypography.subtitle,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: QeranColors.wine,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                QeranSpacing.s16,
                0,
                QeranSpacing.s16,
                QeranSpacing.s12,
              ),
              child: widget.bodyBuilder(context),
            ),
          ),
        ],
      ),
    );
  }
}
