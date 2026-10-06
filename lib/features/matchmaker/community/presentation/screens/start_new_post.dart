import 'package:flutter/widgets.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/community/domain/entities/community_viewer.dart';
import 'package:qeran/features/community/presentation/screens/community_guidelines_page.dart';

import '../../../../../core/di/injection_container.dart';
import '../blocs/guidelines/matchmaker_guidelines_status.dart';
import 'post_composer_page.dart';

/// «منشور جديد», wherever she taps it (plan §3.1): «إرشادات النشر» first
/// while she hasn't agreed to them (G1) — «ليس الآن» leaves her where she
/// was — then her composer. Answers the post she published, or null.
Future<CommunityPost?> startNewPost(BuildContext context) async {
  if (await sl<MatchmakerGuidelinesStatus>().owed()) {
    if (!context.mounted) return null;
    final agreed = await openCommunityGuidelines(
      context,
      viewer: CommunityViewer.matchmaker,
    );
    if (!agreed) return null;
  }
  if (!context.mounted) return null;
  return openPostComposer(context);
}
