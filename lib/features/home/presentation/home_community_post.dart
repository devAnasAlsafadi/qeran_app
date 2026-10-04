import 'package:flutter/widgets.dart';

import '../../community/presentation/screens/community_post_page.dart';
import '../../notifications/presentation/routing/notification_deep_link.dart';

/// A Community notification's post, pushed over whatever is showing (H1). If
/// it closes on «العودة إلى المجتمع» (Q12), everything above the shell —
/// [context]'s route — is popped too; true then, for the shell to select
/// Community.
Future<bool> openPostOverShell(
  BuildContext context,
  OpenCommunityPost link,
) async {
  final shell = ModalRoute.of(context);
  final back = await openCommunityPost(
    context,
    postId: link.postId,
    landing: link.landing,
  );
  if (back && shell != null && context.mounted) {
    Navigator.of(context).popUntil((route) => route == shell);
  }
  return back;
}
