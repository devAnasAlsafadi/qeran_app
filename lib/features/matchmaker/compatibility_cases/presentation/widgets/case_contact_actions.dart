import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../users/presentation/widgets/matchmaker_action_chip.dart';

/// The contact-action row on a compatibility-case list card: soft chips to
/// message the OTHER side's matchmaker and the other person, plus a notes
/// placeholder. These CONTACT people — they are not case actions (status
/// updates live on the detail screen). Each chat chip renders only when its
/// callback is non-null (the conversation exists) — backend-driven, no
/// fabricated entry points. Reuses [MatchmakerActionChip]; the [Wrap] mirrors
/// RTL/LTR and never truncates labels. Renders nothing (no divider) when no
/// chip is available.
class CaseContactActions extends StatelessWidget {
  const CaseContactActions({
    super.key,
    required this.personLabel,
    this.myUserLabel,
    this.onMessageMatchmaker,
    this.onMessagePerson,
    this.onMessageMyUser,
    this.onNotes,
    this.personLoading = false,
    this.myUserLoading = false,
    this.matchmakerLoading = false,
    this.hasNote = false,
  });

  /// The other person's display name for their chip (the card falls back to a
  /// generic label upstream when the name is blank).
  final String personLabel;

  /// `myUser`'s display name — only meaningful alongside [onMessageMyUser].
  final String? myUserLabel;

  final VoidCallback? onMessageMatchmaker;
  final VoidCallback? onMessagePerson;

  /// Direct chat with the matchmaker's OWN participant. Non-null only when both
  /// participants are hers, so the two name-labelled chips are unambiguous.
  final VoidCallback? onMessageMyUser;

  final VoidCallback? onNotes;

  /// True while the person / my-user / matchmaker chat is resolving on tap —
  /// shows that chip's loader.
  final bool personLoading;
  final bool myUserLoading;
  final bool matchmakerLoading;

  /// Whether THIS matchmaker has a private note on the case — fills the Notes
  /// chip icon (outlined → solid) as a subtle "has content" signal.
  final bool hasNote;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (onMessageMatchmaker != null)
        _chip(
          LocaleKeys.matchmaker_cases_action_message_matchmaker.t(context),
          Icons.support_agent_rounded,
          onMessageMatchmaker!,
          loading: matchmakerLoading,
        ),
      // Both participants are mine → one chip each, ordered the same way the
      // pair is drawn (my user first) so the labels map onto the avatars.
      if (onMessageMyUser != null)
        _chip(
          (myUserLabel?.trim().isNotEmpty ?? false)
              ? myUserLabel!.trim()
              : LocaleKeys.matchmaker_cases_action_message.t(context),
          Icons.chat_bubble_outline_rounded,
          onMessageMyUser!,
          loading: myUserLoading,
        ),
      if (onMessagePerson != null)
        _chip(
          personLabel,
          Icons.chat_bubble_outline_rounded,
          onMessagePerson!,
          loading: personLoading,
        ),
      if (onNotes != null)
        _chip(
          LocaleKeys.matchmaker_cases_action_notes.t(context),
          hasNote ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
          onNotes!,
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
          child: Divider(height: 1, color: QeranColors.divider),
        ),
        Wrap(
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s8,
          children: chips,
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool loading = false,
  }) {
    return MatchmakerActionChip(
      label: label,
      icon: icon,
      primary: false,
      loading: loading,
      onTap: onTap,
    );
  }
}
