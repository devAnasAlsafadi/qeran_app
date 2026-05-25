import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';

/// Shared chrome for collapsible filter blocks (select / radio / checkbox).
///
/// Visual: a rounded grey card with the question label on the trailing
/// edge and a chevron-down on the leading edge, expanding to reveal
/// option rows below. Matches the collapsed rows in filter 1.png /
/// filter 2.png — they all use the same chevron card regardless of
/// single-vs-multi semantics.
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
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.r12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p16,
                vertical: AppDimens.p16,
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
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
                AppDimens.p16,
                0,
                AppDimens.p16,
                AppDimens.p12,
              ),
              child: widget.bodyBuilder(context),
            ),
          ),
        ],
      ),
    );
  }
}
