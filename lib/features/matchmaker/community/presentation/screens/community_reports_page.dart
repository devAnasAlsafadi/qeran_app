import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/domain/entities/community_flagged_item.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/screens/community_post_page.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_delete_dialog.dart';
import 'package:qeran/features/community/presentation/widgets/menus/community_menu_actions.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/widgets/connectivity_banner_host.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/reports/community_reports_cubit.dart';
import '../widgets/reports/reports_body.dart';
import '../widgets/reports/reports_toast.dart';

/// Opens «البلاغات» (E7–E10) — from the Dashboard's row only (K7, D36).
Future<void> openCommunityReports(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => sl<CommunityReportsCubit>()..load(),
          child: const CommunityReportsScreen(),
        ),
      ),
    );

/// «البلاغات»: the open reports on comments and replies in her posts, each
/// kept or deleted from its card, or opened on its post.
class CommunityReportsScreen extends StatelessWidget {
  const CommunityReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityReportsCubit, CommunityReportsState>(
      listenWhen: (a, b) => a.eventVersion != b.eventVersion,
      listener: (context, state) => showReportsToast(context, state.event),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.matchmaker_community_reports_title.t(context),
        ),
        body: AttachedConnectivityBanner(
          child: Column(
            children: [
              const ConnectivityBannerSlot(),
              Expanded(
                child: ReportsBody(
                  onOpen: (item) => _open(context, item),
                  onDelete: (item) => _delete(context, item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The post at the reported item (D36); the list is read again when she's
  /// back (S17).
  Future<void> _open(BuildContext context, CommunityFlaggedItem item) async {
    final reports = context.read<CommunityReportsCubit>();
    await openCommunityPost(
      context,
      postId: item.postId,
      landing: _landingAt(item.comment),
      viewer: CommunityViewer.matchmaker,
    );
    await reports.reload();
  }

  /// The same question as on the post, in her words for an item that isn't
  /// hers (E4, E5).
  Future<void> _delete(BuildContext context, CommunityFlaggedItem item) async {
    final reports = context.read<CommunityReportsCubit>();
    final kind = contentKindOf(item.comment);
    if (await confirmCommunityDelete(context, kind, mine: false)) {
      await reports.delete(item);
    }
  }

  static CommunityLanding _landingAt(CommunityComment comment) =>
      switch (comment.parentCommentId) {
        final parent? => CommunityLanding(
          commentId: parent,
          replyId: comment.id,
        ),
        null => CommunityLanding(commentId: comment.id),
      };
}
