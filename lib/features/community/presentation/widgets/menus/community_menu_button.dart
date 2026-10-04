import 'package:flutter/material.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_options_sheet.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import 'community_menu_actions.dart';

/// The ⋮ on a post card or a comment row (E1–E4, I1): a 44 pt tap area, the
/// icon ink-muted. Opens the options sheet with [actions] and runs the one
/// chosen through [onSelected], with the button's own context.
class CommunityMenuButton extends StatelessWidget {
  const CommunityMenuButton({
    super.key,
    required this.actions,
    required this.kind,
    required this.onSelected,
    this.iconSize = 20,
  });

  final List<CommunityMenuAction> actions;

  /// What the rows name: the post, a comment or a reply.
  final ReportContentKind kind;
  final void Function(BuildContext context, CommunityMenuAction action)
  onSelected;

  /// 22 on a post card, 20 on a row.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LocaleKeys.community_menu_more.t(context),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => _open(context),
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            Icons.more_vert_rounded,
            size: iconSize,
            color: QeranColors.inkMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final chosen = await QeranOptionsSheet.show<CommunityMenuAction>(
      context,
      options: [
        for (final action in actions)
          communityMenuOption(context, action, kind),
      ],
    );
    if (chosen != null && context.mounted) onSelected(context, chosen);
  }
}
