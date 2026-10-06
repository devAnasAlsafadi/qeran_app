import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/community_viewer.dart';
import '../blocs/guidelines/community_guidelines_cubit.dart';
import 'community_guidelines_screen.dart';

/// Opens the guidelines step over [context] (D7, F5): true once the reader
/// has agreed, false for «ليس الآن» or going back (F7). A
/// `MaterialPageRoute`, so iOS keeps its edge-swipe back.
Future<bool> openCommunityGuidelines(
  BuildContext context, {
  CommunityViewer viewer = CommunityViewer.member,
}) async {
  final agreed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => CommunityGuidelinesPage(viewer: viewer)),
  );
  return agreed ?? false;
}

/// The pushed guidelines step on paper, over the server's text — the
/// version for this viewer's role (D39): «إرشادات المجتمع» for a member,
/// «إرشادات النشر» before her first post (G1).
class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({
    super.key,
    this.viewer = CommunityViewer.member,
  });

  final CommunityViewer viewer;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunityGuidelinesCubit>(
      // Hers tells her app, not the member's profile gate (her DI).
      create: (_) => sl<CommunityGuidelinesCubit>(
        instanceName: viewer == CommunityViewer.matchmaker ? viewer.name : null,
      )..load(),
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title:
              (viewer == CommunityViewer.matchmaker
                      ? LocaleKeys.community_posting_guidelines_title
                      : LocaleKeys.community_guidelines_title)
                  .t(context),
          background: QeranColors.paper,
        ),
        body: const CommunityGuidelinesScreen(),
      ),
    );
  }
}
