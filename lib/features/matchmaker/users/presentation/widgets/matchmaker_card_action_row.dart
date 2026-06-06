import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_users_list.dart';

/// The per-list action row beneath a user card. Exactly ONE filled
/// (primaryWine) button — the list's primary action — with the rest ghost,
/// laid out as equal-width cells:
///   • pending               → موافقة* · مراسلة · عرض · ملاحظات
///   • approved-unsubscribed → مراسلة* · عرض · ملاحظات
///   • approved-subscribed   → مراسلة* · عرض · ملاحظات · الإهتمامات
/// (* = the filled primary). Scaffolded in M3a — every handler is a no-op;
/// they are wired per action in M3b–f. Buttons mirror automatically (RTL/LTR)
/// via the `Row`'s directional layout.
class MatchmakerCardActionRow extends StatelessWidget {
  const MatchmakerCardActionRow({super.key, required this.list});

  final MatchmakerUsersList list;

  @override
  Widget build(BuildContext context) {
    final specs = _specsFor(list);
    return Row(
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) QeranSpacing.hs8,
          Expanded(child: _button(context, specs[i])),
        ],
      ],
    );
  }

  List<_BtnSpec> _specsFor(MatchmakerUsersList list) => switch (list) {
        MatchmakerUsersList.pending => _pendingActions,
        MatchmakerUsersList.approvedUnsubscribed => _unsubscribedActions,
        MatchmakerUsersList.approvedSubscribed => _subscribedActions,
      };

  /// Scaffold-only button — [_BtnSpec.onPressed] is a no-op in M3a; handlers
  /// are wired per action in M3b–f.
  Widget _button(BuildContext context, _BtnSpec spec) {
    return QeranButton(
      label: spec.labelKey.t(context),
      // TODO(M3b–f): wire approve / message / view / notes / interests.
      onPressed: () {},
      variant: spec.primary
          ? QeranButtonVariant.primaryWine
          : QeranButtonVariant.ghost,
      size: QeranButtonSize.xs,
      leadingIcon: spec.icon,
    );
  }
}

/// One button's label + icon + whether it is the list's filled primary.
class _BtnSpec {
  const _BtnSpec(this.labelKey, this.icon, {this.primary = false});

  final String labelKey;
  final IconData icon;
  final bool primary;
}

// Per-list button sets — pure data, exactly one `primary: true` each.
const _pendingActions = <_BtnSpec>[
  _BtnSpec(
    LocaleKeys.matchmaker_users_action_approve,
    Icons.check_circle_outline,
    primary: true,
  ),
  _BtnSpec(
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
  ),
  _BtnSpec(LocaleKeys.matchmaker_users_action_view, Icons.visibility_outlined),
  _BtnSpec(LocaleKeys.matchmaker_users_action_notes, Icons.note_alt_outlined),
];

const _unsubscribedActions = <_BtnSpec>[
  _BtnSpec(
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
    primary: true,
  ),
  _BtnSpec(LocaleKeys.matchmaker_users_action_view, Icons.visibility_outlined),
  _BtnSpec(LocaleKeys.matchmaker_users_action_notes, Icons.note_alt_outlined),
];

const _subscribedActions = <_BtnSpec>[
  _BtnSpec(
    LocaleKeys.matchmaker_users_action_message,
    Icons.chat_bubble_outline_rounded,
    primary: true,
  ),
  _BtnSpec(LocaleKeys.matchmaker_users_action_view, Icons.visibility_outlined),
  _BtnSpec(LocaleKeys.matchmaker_users_action_notes, Icons.note_alt_outlined),
  _BtnSpec(
    LocaleKeys.matchmaker_users_action_interests,
    Icons.favorite_border_rounded,
  ),
];
