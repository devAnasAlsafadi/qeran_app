import 'package:flutter/material.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';

import '../../../../../core/design_system/widgets/qeran_options_sheet.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_viewer.dart';

/// What a ⋮ can offer on a post, a comment or a reply.
enum CommunityMenuAction { delete, report, block }

/// A post's options (S13): Report, unless the viewer may delete it — her own
/// post, whose Delete comes with her composer (Phase 3).
List<CommunityMenuAction> postMenuActions(CommunityPost post) =>
    post.canDelete ? const [] : const [CommunityMenuAction.report];

/// A comment's or reply's options, from the server's flags, in the board's
/// order (E2–E4, I1): Delete when [CommunityComment.canDelete], Report when
/// it isn't the viewer's own, Block when [CommunityComment.canBlock] — and
/// never Block for a matchmaker, whatever the flag says (D40).
List<CommunityMenuAction> commentMenuActions(
  CommunityComment comment,
  CommunityViewer viewer,
) => [
  if (comment.canDelete) CommunityMenuAction.delete,
  if (!comment.isMine) CommunityMenuAction.report,
  if (comment.canBlock && viewer == CommunityViewer.member)
    CommunityMenuAction.block,
];

/// What a report or a delete names: the post, a comment or a reply.
ReportContentKind contentKindOf(CommunityComment comment) =>
    comment.isReply ? ReportContentKind.reply : ReportContentKind.comment;

/// A row of the ⋮ sheet: Delete and Block in danger.
QeranOption<CommunityMenuAction> communityMenuOption(
  BuildContext context,
  CommunityMenuAction action,
  ReportContentKind kind,
) => switch (action) {
  CommunityMenuAction.delete => QeranOption(
    icon: Icons.delete_outline_rounded,
    label:
        (kind == ReportContentKind.reply
                ? LocaleKeys.community_menu_delete_reply
                : LocaleKeys.community_menu_delete)
            .t(context),
    value: action,
    danger: true,
  ),
  CommunityMenuAction.report => QeranOption(
    icon: Icons.flag_outlined,
    label: switch (kind) {
      ReportContentKind.post => LocaleKeys.community_menu_report_post,
      ReportContentKind.comment => LocaleKeys.community_menu_report_comment,
      ReportContentKind.reply => LocaleKeys.community_menu_report_reply,
    }.t(context),
    value: action,
  ),
  CommunityMenuAction.block => QeranOption(
    icon: Icons.block_rounded,
    label: LocaleKeys.block_action_block.t(context),
    value: action,
    danger: true,
  ),
};
