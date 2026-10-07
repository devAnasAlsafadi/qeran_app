import 'package:flutter/widgets.dart';

import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
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
