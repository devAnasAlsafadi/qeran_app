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
    this.onMessageMatchmaker,
    this.onMessagePerson,
    this.onNotes,
    this.personLoading = false,
    this.matchmakerLoading = false,
    this.hasNote = false,
  });

  /// The other person's display name for their chip (the card falls back to a
  /// generic label upstream when the name is blank).
  final String personLabel;
  final VoidCallback? onMessageMatchmaker;
  final VoidCallback? onMessagePerson;
  final VoidCallback? onNotes;

  /// True while the person / matchmaker chat is resolving on tap — shows that
  /// chip's loader.
  final bool personLoading;
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
          hasNote ? Icons.note_alt : Icons.note_alt_outlined,
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
