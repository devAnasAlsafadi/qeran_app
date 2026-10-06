import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';

import '../../../domain/entities/community_post.dart';
import '../../blocs/post_delete/post_delete_cubit.dart';
import 'community_delete_dialog.dart';
import 'community_menu_actions.dart';
import 'community_menu_button.dart';

/// A post's ⋮ (E1) — on the feed card and on the post screen — or null when
/// the viewer has nothing to do with it. On her own post it deletes (B6).
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
      CommunityMenuAction.delete => _delete(context, post),
      // Never on a post.
      CommunityMenuAction.block => null,
    },
  );
}

/// Asks first (B7), then deletes through the screen's [PostDeleteCubit].
Future<void> _delete(BuildContext context, CommunityPost post) async {
  final deleting = context.read<PostDeleteCubit>();
  if (await confirmPostDelete(context)) await deleting.delete(post.id);
}
