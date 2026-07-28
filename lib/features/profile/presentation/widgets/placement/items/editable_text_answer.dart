import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';

import '../../../../domain/entities/placement_item.dart';
import '../../../../domain/entities/placement_item_type.dart';
import '../text_answer_edit_scope.dart';

/// Adds the matchmaker's edit pencil to an already-rendered text answer.
///
/// This is the ONE place the pencil is attached, so every editable surface
/// gets the same affordance and the same null-guard:
///   • Q&A rows (`PlacementItemRenderer`)
///   • the narrative نبذات (`AboutMeSection` / `AboutPartnerSection`)
///
/// Returns [child] completely untouched — no Row, no layout change — when
/// there is no [TextAnswerEditScope] installed, when [item] is null (the
/// placement carries no editable body), or when the item is not a text answer.
/// The user app, my-profile and approved profiles therefore render exactly as
/// they did before; only the matchmaker host installs a scope, and only for the
/// statuses its own gate allows.
class EditableTextAnswer extends StatelessWidget {
  const EditableTextAnswer({
    super.key,
    required this.item,
    required this.child,
    this.affordancePadding = const EdgeInsets.symmetric(
      vertical: QeranSpacing.s8,
    ),
  });

  /// The answer [child] renders. Null when the placement has no item to edit,
  /// which is also how "backend sent no body" reaches us — no pencil is drawn
  /// for something the server never gave us.
  final PlacementItem? item;

  final Widget child;

  /// Vertical inset for the pencil so it lines up with the child's own leading
  /// row. Q&A rows carry a `vertical: s8` padding of their own and match the
  /// default; the narrative sections start flush and pass `EdgeInsets.zero` so
  /// the pencil sits level with their section header.
  final EdgeInsetsGeometry affordancePadding;

  @override
  Widget build(BuildContext context) {
    final target = item;
    final scope = TextAnswerEditScope.maybeOf(context);
    if (scope == null ||
        target == null ||
        target.type != PlacementItemType.text) {
      return child;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        const SizedBox(width: QeranSpacing.s8),
        Padding(
          padding: affordancePadding,
          child: PlacementEditAffordance(
            loading: scope.inFlightQuestionId == target.questionId,
            onTap: () => scope.onEdit(target),
          ),
        ),
      ],
    );
  }
}

/// Small softFill edit pencil for an editable text answer (matchmaker DS
/// style). Shows an inline loader in place of the pencil while its save is in
/// flight, with taps suppressed.
class PlacementEditAffordance extends StatelessWidget {
  const PlacementEditAffordance({
    super.key,
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.softFill,
      borderRadius: QeranRadii.pill,
      child: InkWell(
        borderRadius: QeranRadii.pill,
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s6),
          child: SizedBox(
            width: 16,
            height: 16,
            child: loading
                ? const FittedBox(
                    child: QeranLoader.inline(color: QeranColors.wine),
                  )
                : const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: QeranColors.wine,
                  ),
          ),
        ),
      ),
    );
  }
}
