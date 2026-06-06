import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_users_list.dart';

/// The action a card button triggers. The card maps each to its handler
/// (wired progressively across M3b–f).
enum MatchmakerCardAction { approve, message, view, notes, interests }

/// The per-list action row beneath a user card. Exactly ONE filled
/// (primaryWine) button — the list's primary action — with the rest as soft
/// wine-tinted "chip" buttons ([QeranButtonVariant.neutral]):
///   • pending               → موافقة* · مراسلة · عرض · ملاحظات
///   • approved-unsubscribed → مراسلة* · عرض · ملاحظات
///   • approved-subscribed   → مراسلة* · عرض · ملاحظات · الإهتمامات
/// (* = the filled primary). Buttons are content-sized and flow in a [Wrap]
/// so labels NEVER truncate — the chips sit on one line when they fit, else
/// they wrap to a second line. Mirrors automatically (RTL/LTR).
class MatchmakerCardActionRow extends StatelessWidget {
  const MatchmakerCardActionRow({
    super.key,
    required this.list,
    required this.onAction,
  });

  final MatchmakerUsersList list;
  final void Function(MatchmakerCardAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: [for (final spec in _specsFor(list)) _button(context, spec)],
    );
  }

  List<_BtnSpec> _specsFor(MatchmakerUsersList list) => switch (list) {
    MatchmakerUsersList.pending => _pendingActions,
    MatchmakerUsersList.approvedUnsubscribed => _unsubscribedActions,
    MatchmakerUsersList.approvedSubscribed => _subscribedActions,
  };

  Widget _button(BuildContext context, _BtnSpec spec) {
    return QeranButton(
      label: spec.labelKey.t(context),
      onPressed: () => onAction(spec.action),
      variant: spec.primary
          ? QeranButtonVariant.primaryWine
          : QeranButtonVariant.neutral,
      size: QeranButtonSize.xs,
      leadingIcon: spec.icon,
      // Content-sized so the full label always shows; the Wrap handles overflow.
      fullWidth: false,
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
