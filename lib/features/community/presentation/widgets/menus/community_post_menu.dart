import 'package:flutter/widgets.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';

import '../../../domain/entities/community_post.dart';
import 'community_menu_actions.dart';
import 'community_menu_button.dart';

/// A post's ⋮ (E1) — on the feed card and on the post screen — or null when
/// the viewer has nothing to do with it.
Widget? communityPostMenu(CommunityPost post) {
  final actions = postMenuActions(post);
  if (actions.isEmpty) return null;
  return CommunityMenuButton(
    actions: actions,
    kind: ReportContentKind.post,
    iconSize: 22,
    onSelected: (context, action) => switch (action) {
      CommunityMenuAction.report => showReportSheet(
        context,
        target: ContentReportTarget(ReportContentKind.post, post.id),
      ),
      // A post offers only Report in the member's app.
      CommunityMenuAction.delete || CommunityMenuAction.block => null,
    },
  );
}
