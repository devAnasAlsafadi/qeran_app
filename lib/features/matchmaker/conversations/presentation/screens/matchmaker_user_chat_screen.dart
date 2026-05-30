import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/presentation/screens/chat_conversation_screen.dart';

import '../../domain/entities/matchmaker_conversation.dart';

/// Hosts the shared [ChatConversationScreen] as a PUSHED route for the
/// matchmaker, building the peer [MatchmakerInfo] from the tapped 4a
/// conversation row. The chat module is generic — `ConversationCubit` keys on
/// (conversationId, myUserId-from-session) and already marks-as-read + wires
/// realtime on init — so no bootstrap (`/chat/my-matchmaker`) is needed. The
/// only adaptation is the `onBack` the shared screen now accepts.
class MatchmakerUserChatScreen extends StatelessWidget {
  const MatchmakerUserChatScreen({super.key, required this.conversation});

  final MatchmakerConversation conversation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      body: SafeArea(
        child: ChatConversationScreen(
          info: MatchmakerInfo(
            conversationId: conversation.conversationId,
            name: conversation.fullName,
            profileImageUrl: conversation.profileImageUrl,
            // Carried for the header peer identity; unused by the screen.
            matchmakerId: conversation.userId,
          ),
          onBack: () => NavigationManager.pop(context),
        ),
      ),
    );
  }
}
