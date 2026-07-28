import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import 'case_contact_actions.dart';
import 'case_paired_avatars.dart';
import 'matchmaker_case_labels.dart';

/// One compatibility-case card in the list: a compact "matched pair" — the
/// two participants' overlapped monogram/photo avatars, both first names on
/// one line joined by a gold heart, a color-differentiated status chip
/// (gold=active · wine=waiting · soft=expired · danger=closed) and a
/// de-emphasized accepted-on date. Tappable → the case detail (3b).
///
/// The spread-apart hero layout lives in the details screen via the shared
/// `CaseParticipantsPair`; this card deliberately does not use it.
class MatchmakerCaseCard extends StatelessWidget {
  const MatchmakerCaseCard({
    super.key,
    required this.caseItem,
    this.onTap,
    this.onMessageMatchmaker,
    this.onMessagePerson,
    this.onMessageMyUser,
    this.onNotes,
    this.personLoading = false,
    this.myUserLoading = false,
    this.matchmakerLoading = false,
  });

  final CompatibilityCase caseItem;
  final VoidCallback? onTap;

  /// Contact actions on the card — each chip renders only when its callback is
  /// non-null, so ownership decides the set (see the list view's gating).
  final VoidCallback? onMessageMatchmaker;
  final VoidCallback? onMessagePerson;

  /// Direct chat with the matchmaker's own participant — set only when BOTH
  /// participants are hers.
  final VoidCallback? onMessageMyUser;

  final VoidCallback? onNotes;

  /// True while the person / my-user / matchmaker chat is resolving on tap —
  /// shows that chip's loader.
  final bool personLoading;
  final bool myUserLoading;
  final bool matchmakerLoading;

  @override
  Widget build(BuildContext context) {
    final statusChip = _statusChip(context);
    final dateLine = _dateLine(context);
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CasePairedAvatars(
                firstUrl: caseItem.myUser.profileImageUrl,
                secondUrl: caseItem.otherUser.profileImageUrl,
                firstName: caseItem.myUser.firstName,
                secondName: caseItem.otherUser.firstName,
              ),
              QeranSpacing.hs16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PairNames(
                      first: caseItem.myUser.firstName.trim(),
                      second: caseItem.otherUser.firstName.trim(),
                    ),
                    if (statusChip != null) ...[QeranSpacing.vs8, statusChip],
                    if (dateLine != null) ...[QeranSpacing.vs8, dateLine],
                  ],
                ),
              ),
            ],
          ),
          CaseContactActions(
            personLabel: _personLabel(context),
            myUserLabel: caseItem.myUser.firstName,
            onMessageMatchmaker: onMessageMatchmaker,
            onMessagePerson: onMessagePerson,
            onMessageMyUser: onMessageMyUser,
            personLoading: personLoading,
            myUserLoading: myUserLoading,
            matchmakerLoading: matchmakerLoading,
            onNotes: onNotes,
            hasNote: caseItem.hasMyNote,
          ),
        ],
      ),
    );
  }

  /// The other person's name for their message chip — falls back to a generic
  /// "message" label when the server omitted the name.
  String _personLabel(BuildContext context) {
    final name = caseItem.otherUser.firstName.trim();
    if (name.isNotEmpty) return name;
    return LocaleKeys.matchmaker_cases_action_message.t(context);
  }

  /// The single status signal as a color-differentiated chip (its kind sets
  /// the palette; the label is the most-specific status). `null` when unknown.
  Widget? _statusChip(BuildContext context) {
    final labelKey = caseStatusChipLabelKey(caseItem);
    if (labelKey == null) return null;
    return _CaseStatusChip(
      label: labelKey.t(context),
      kind: caseStatusKind(caseItem),
    );
  }

  Widget? _dateLine(BuildContext context) {
    final d = caseItem.likeAcceptedAt;
    if (d == null) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.event_rounded,
          size: 14,
          color: QeranColors.inkFaint,
        ),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            '${LocaleKeys.matchmaker_cases_like_accepted_at.t(context)} '
            '${_formatDate(d)}',
            style: QeranTypography.caption.copyWith(color: QeranColors.inkFaint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}

/// Both first names on one line joined by a gold heart. Each name is flexible
/// + ellipsized so a long pair never overflows; degrades to the single present
/// name (no heart, no fabricated text) when one is blank. Mirrors in RTL.
class _PairNames extends StatelessWidget {
  const _PairNames({required this.first, required this.second});

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    if (first.isEmpty || second.isEmpty) {
      return Text(
        first.isEmpty ? second : first,
        style: QeranTypography.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Row(
      children: [
        Flexible(child: _name(first)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
          child: Icon(Icons.favorite_rounded, size: 14, color: QeranColors.gold),
        ),
        Flexible(child: _name(second)),
      ],
    );
  }

  Widget _name(String value) => Text(
        value,
        style: QeranTypography.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

/// The list card's color-differentiated status pill: a leading dot + label,
/// painted by the case's [CaseStatusKind] palette (05 §"Status chip").
class _CaseStatusChip extends StatelessWidget {
  const _CaseStatusChip({required this.label, required this.kind});

  final String label;
  final CaseStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final p = caseStatusKindPalette(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: p.dot, shape: BoxShape.circle),
          ),
          QeranSpacing.hs8,
          Flexible(
            child: Text(
              label,
              style: QeranTypography.caption.copyWith(
                color: p.fg,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
