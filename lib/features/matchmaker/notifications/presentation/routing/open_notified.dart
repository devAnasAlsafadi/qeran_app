import 'package:flutter/widgets.dart';

import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../community/domain/entities/community_viewer.dart';
import '../../../../community/presentation/screens/community_post_page.dart';
import '../../../community/presentation/screens/matchmaker_community_screen.dart';
import '../../../conversations/domain/entities/matchmaker_conversation.dart';
import '../../../shared/data/matchmaker_notification_router.dart';

/// The chat a notification names, pushed over whatever is showing — her inbox,
/// or her shell for a push. Thin conversation: chat loads messages by id;
/// the sender's name fills the header so it never renders blank. No route-arg
/// change — satisfies the existing arg type.
void openNotifiedChat(BuildContext context, OpenUserChat link) {
  NavigationManager.navigateTo(
    context,
    RouteNames.matchmakerUserChat,
    arguments: MatchmakerConversation(
      userId: '',
      fullName: link.senderName,
      profileImageUrl: null,
      conversationId: link.conversationId,
      lastMessageAt: null,
      lastMessagePreview: null,
      unreadCount: 0,
    ),
  );
}

/// The post a notification names, at its comment or reply (C8), pushed over
/// whatever is showing — her inbox, or her shell for a push — so back is
/// where she was. Gone, its «العودة إلى المجتمع» opens her Community (Q12):
/// she has no Community tab to go back to.
Future<void> openNotifiedPost(BuildContext context, OpenPost link) async {
  final back = await openCommunityPost(
    context,
    postId: link.target.postId,
    landing: link.target.landing,
    viewer: CommunityViewer.matchmaker,
  );
  if (back && context.mounted) await openMatchmakerCommunity(context);
}
