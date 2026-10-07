import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/block/presentation/widgets/confirm_block_dialog.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/presentation/blocs/report_state.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';

import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_viewer.dart';
import '../../blocs/comments/community_comments_cubit.dart';
import 'community_delete_dialog.dart';
import 'community_menu_actions.dart';
import 'community_menu_button.dart';

/// A comment's or reply's ⋮ for [viewer] (E2–E4, I1); null when it offers
/// nothing. Report opens the sheet; Delete and Block ask first, then go
/// through the post screen's comments and block cubits.
Widget? communityCommentMenu(
  CommunityComment comment, {
  required CommunityViewer viewer,
}) {
  final actions = commentMenuActions(comment, viewer);
  if (actions.isEmpty) return null;
  final kind = contentKindOf(comment);
  return CommunityMenuButton(
    actions: actions,
    kind: kind,
    onSelected: (context, action) => switch (action) {
      CommunityMenuAction.report => _report(context, comment, kind),
      CommunityMenuAction.delete => deleteCommunityComment(context, comment),
      CommunityMenuAction.block => _block(context, comment),
    },
  );
}

/// A report that finds it gone (E7) takes the row away too, as a delete
/// that finds it gone does.
Future<void> _report(
  BuildContext context,
  CommunityComment comment,
  ReportContentKind kind,
) async {
  final comments = context.read<CommunityCommentsCubit>();
  final outcome = await showReportSheet(
    context,
    target: ContentReportTarget(kind, comment.id),
  );
  if (outcome == ReportOutcome.gone) comments.removeGone(comment);
}

/// Asks — in her words for an item that isn't hers (E4, E5) — then deletes
/// [comment] through the post screen's comments: from the ⋮, and from a
/// reported row's «حذف».
Future<void> deleteCommunityComment(
  BuildContext context,
  CommunityComment comment,
) async {
  final comments = context.read<CommunityCommentsCubit>();
  final kind = contentKindOf(comment);
  if (await confirmCommunityDelete(context, kind, mine: comment.isMine)) {
    await comments.delete(comment);
  }
}

/// The same question as a profile's Block (E11).
Future<void> _block(BuildContext context, CommunityComment comment) async {
  final block = context.read<BlockActionCubit>();
  if (await confirmBlockMember(context)) {
    await block.block(comment.author.id);
  }
}
