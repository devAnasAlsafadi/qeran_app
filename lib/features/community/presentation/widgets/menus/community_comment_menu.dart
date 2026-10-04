import 'package:flutter/widgets.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';

import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_viewer.dart';
import 'community_menu_actions.dart';
import 'community_menu_button.dart';

/// A comment's or reply's ⋮ for [viewer] (E2–E4, I1), with the actions the
/// post screen runs; null when none applies.
Widget? communityCommentMenu(
  CommunityComment comment, {
  required CommunityViewer viewer,
}) {
  final actions = commentMenuActions(
    comment,
    viewer,
  ).where(_runs.contains).toList();
  if (actions.isEmpty) return null;
  final kind = contentKindOf(comment);
  return CommunityMenuButton(
    actions: actions,
    kind: kind,
    onSelected: (context, action) => switch (action) {
      CommunityMenuAction.report => showReportSheet(
        context,
        target: ContentReportTarget(kind, comment.id),
      ),
      CommunityMenuAction.delete || CommunityMenuAction.block => null,
    },
  );
}

/// What a row's ⋮ runs.
const _runs = {CommunityMenuAction.report};
