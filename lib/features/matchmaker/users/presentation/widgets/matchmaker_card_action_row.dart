import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_users_list.dart';
import 'matchmaker_action_chip.dart';

/// The action a card button triggers. The card maps each to its handler
/// (wired progressively across M3b–f).
enum MatchmakerCardAction { approve, message, view, notes, interests }

/// The per-list action block beneath a user card — a clear 1 + N hierarchy:
///   • Row 1 — the list's lone primary action, a FULL-WIDTH filled wine chip:
///       pending → موافقة · approved-(un)subscribed → مراسلة
///   • Row 2 — the secondary actions as content-sized soft chips in a [Wrap]:
///       pending → مراسلة · عرض · ملاحظات
///       approved-unsubscribed → عرض · ملاحظات
///       approved-subscribed   → عرض · ملاحظات · الإهتمامات
///
/// The primary leads (dominant, full-width); the secondaries group beneath and
/// wrap so labels NEVER truncate — balanced at any label width across all three
/// lists (3 or 4 actions). Mirrors automatically (RTL/LTR).
class MatchmakerCardActionRow extends StatelessWidget {
  const MatchmakerCardActionRow({
    super.key,
    required this.list,
    required this.onAction,
    this.loadingAction,
  });

  final MatchmakerUsersList list;
  final void Function(MatchmakerCardAction action) onAction;

  /// The action whose button shows an inline loader (and is disabled) while it
  /// resolves — e.g. مراسلة while its conversation opens. Null when idle.
  final MatchmakerCardAction? loadingAction;

  @override
  Widget build(BuildContext context) {
    final specs = _specsFor(list);
    final primary = specs.firstWhere((s) => s.primary);
    final secondaries = specs.where((s) => !s.primary).toList(growable: false);
    return Column(
      // Stretch lets the primary row + Wrap span full width; both then centre
      // their content horizontally.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Primary centred at ~70% width (3 : 14 : 3) — prominent but not a
        // heavy full-width bar; equal side gaps mirror with the row.
        Row(
          children: [
            const Spacer(flex: 3),
            Expanded(
              flex: 14,
              child: _button(context, primary, fullWidth: true),
            ),
            const Spacer(flex: 3),
          ],
        ),
        QeranSpacing.vs8,
        // Secondaries centred beneath; content-sized chips, never truncate.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: QeranSpacing.s8,
          runSpacing: QeranSpacing.s8,
          children: [for (final spec in secondaries) _button(context, spec)],
        ),
      ],
    );
  }

  List<_BtnSpec> _specsFor(MatchmakerUsersList list) => switch (list) {
    MatchmakerUsersList.pending => _pendingActions,
    MatchmakerUsersList.approvedUnsubscribed => _unsubscribedActions,
    MatchmakerUsersList.approvedSubscribed => _subscribedActions,
  };

  Widget _button(BuildContext context, _BtnSpec spec, {bool fullWidth = false}) {
    return MatchmakerActionChip(
      label: spec.labelKey.t(context),
      icon: spec.icon,
      primary: spec.primary,
      fullWidth: fullWidth,
      loading: spec.action == loadingAction,
      onTap: () => onAction(spec.action),
    );
  }
}

/// One button's action + label + icon + whether it is the list's filled
/// primary.
class _BtnSpec {
  const _BtnSpec(this.action, this.labelKey, this.icon, {this.primary = false});

  final MatchmakerCardAction action;
  final String labelKey;
  final IconData icon;
  final bool primary;
}

// Per-list button sets — pure data, exactly one `primary: true` each.
const _pendingActions = <_BtnSpec>[
  _BtnSpec(
    MatchmakerCardAction.approve,
    LocaleKeys.matchmaker_users_action_approve,
    Icons.check_circle_outline,
    primary: true,
  ),
  _BtnSpec(
    MatchmakerCardAction.message,
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
  ),
  _BtnSpec(
    MatchmakerCardAction.view,
    LocaleKeys.matchmaker_users_action_view,
    Icons.visibility_outlined,
  ),
  _BtnSpec(
    MatchmakerCardAction.notes,
    LocaleKeys.matchmaker_users_action_notes,
    Icons.note_alt_outlined,
  ),
];

const _unsubscribedActions = <_BtnSpec>[
  _BtnSpec(
    MatchmakerCardAction.message,
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
    primary: true,
  ),
  _BtnSpec(
    MatchmakerCardAction.view,
    LocaleKeys.matchmaker_users_action_view,
    Icons.visibility_outlined,
  ),
  _BtnSpec(
    MatchmakerCardAction.notes,
    LocaleKeys.matchmaker_users_action_notes,
    Icons.note_alt_outlined,
  ),
];

const _subscribedActions = <_BtnSpec>[
  _BtnSpec(
    MatchmakerCardAction.message,
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
    primary: true,
  ),
  _BtnSpec(
    MatchmakerCardAction.view,
    LocaleKeys.matchmaker_users_action_view,
    Icons.visibility_outlined,
  ),
  _BtnSpec(
    MatchmakerCardAction.notes,
    LocaleKeys.matchmaker_users_action_notes,
    Icons.note_alt_outlined,
  ),
  _BtnSpec(
    MatchmakerCardAction.interests,
    LocaleKeys.matchmaker_users_action_interests,
    Icons.favorite_border_rounded,
  ),
];
