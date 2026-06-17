import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../users/presentation/widgets/matchmaker_action_chip.dart';

/// The action row on an explore card — mirrors the Users-tab 1+N layout (one
/// full-width primary + soft secondary chips in a [Wrap]) with the explore
/// action set: **View** is the always-present primary (the explore verb);
/// secondaries render only when their callback is non-null (backend-driven —
/// Notes is assigned-only). Built additively: the matchmaker-chat action (and
/// later Share) drop in as further secondaries without touching the layout.
/// Reuses [MatchmakerActionChip]; mirrors RTL/LTR.
class MatchmakerExploreActionRow extends StatelessWidget {
  const MatchmakerExploreActionRow({
    super.key,
    required this.onView,
    required this.onShare,
    this.onNotes,
    this.onMessageMatchmaker,
    this.matchmakerLoading = false,
  });

  /// Always present — opens the full profile (the explore primary verb).
  final VoidCallback onView;

  /// Always present — opens the recipient picker to share this profile with the
  /// matchmaker's own users (independent of who the browsed user is assigned to).
  final VoidCallback onShare;

  /// Opens the private notes sheet — null (hidden) unless the user is assigned
  /// to me (the note endpoint is assigned-only).
  final VoidCallback? onNotes;

  /// Opens the chat with this user's matchmaker — null (hidden) unless the user
  /// has a DIFFERENT matchmaker. Mutually exclusive with [onNotes] per the
  /// gating (mine → Notes; theirs → Matchmaker chat).
  final VoidCallback? onMessageMatchmaker;

  /// True while that matchmaker chat is resolving on tap — shows the chip loader.
  final bool matchmakerLoading;

  @override
  Widget build(BuildContext context) {
    final secondaries = <Widget>[
      if (onNotes != null)
        MatchmakerActionChip(
          label: LocaleKeys.matchmaker_users_action_notes.t(context),
          icon: Icons.note_alt_outlined,
          primary: false,
          loading: false,
          onTap: onNotes!,
        ),
      if (onMessageMatchmaker != null)
        MatchmakerActionChip(
          label:
              LocaleKeys.matchmaker_cases_action_message_matchmaker.t(context),
          icon: Icons.support_agent_rounded,
          primary: false,
          loading: matchmakerLoading,
          onTap: onMessageMatchmaker!,
        ),
      MatchmakerActionChip(
        label: LocaleKeys.matchmaker_explore_action_share.t(context),
        icon: Icons.ios_share_rounded,
        primary: false,
        loading: false,
        onTap: onShare,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary (View) centred at ~70% width — mirrors the Users-tab row.
        Row(
          children: [
            const Spacer(flex: 3),
            Expanded(
              flex: 14,
              child: MatchmakerActionChip(
                label: LocaleKeys.matchmaker_users_action_view.t(context),
                icon: Icons.visibility_outlined,
                primary: true,
                loading: false,
                fullWidth: true,
                onTap: onView,
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
        if (secondaries.isNotEmpty) ...[
          QeranSpacing.vs8,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: QeranSpacing.s8,
            runSpacing: QeranSpacing.s8,
            children: secondaries,
          ),
        ],
      ],
    );
  }
}
