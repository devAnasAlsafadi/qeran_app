import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/compatibility_case.dart';
import 'case_contact_actions.dart';
import 'case_paired_avatars.dart';
import 'matchmaker_case_labels.dart';

/// One compatibility-case card in the list: a compact "matched pair" — the
/// two participants' avatars overlapped at the top, both first names on one
/// line joined with "&", then a small status chip (gold once the case
/// reaches the formal track, muted otherwise) and a de-emphasized
/// accepted-on date. Tappable → the case detail (3b).
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
    this.onNotes,
    this.personLoading = false,
    this.matchmakerLoading = false,
  });

  final CompatibilityCase caseItem;
  final VoidCallback? onTap;

  /// Contact actions on the card. The person callback is always present (the
  /// chat is resolved-or-created on tap); the matchmaker callback is null when
  /// its conversation doesn't exist yet, so that chip is omitted.
  final VoidCallback? onMessageMatchmaker;
  final VoidCallback? onMessagePerson;
  final VoidCallback? onNotes;

  /// True while the person / matchmaker chat is resolving on tap — shows that
  /// chip's loader.
  final bool personLoading;
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
              ),
              QeranSpacing.hs16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _names,
                      style: QeranTypography.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            onMessageMatchmaker: onMessageMatchmaker,
            onMessagePerson: onMessagePerson,
            personLoading: personLoading,
            matchmakerLoading: matchmakerLoading,
            onNotes: onNotes,
            hasNote: caseItem.hasMyNote,
          ),
        ],
      ),
    );
  }

  /// Both first names on one line joined with "&". Degrades to the single
  /// present name (no separator, no fabricated text) when one is blank.
  String get _names {
    final a = caseItem.myUser.firstName.trim();
    final b = caseItem.otherUser.firstName.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a & $b';
  }

  /// The other person's name for their message chip — falls back to a generic
  /// "message" label when the server omitted the name.
  String _personLabel(BuildContext context) {
    final name = caseItem.otherUser.firstName.trim();
    if (name.isNotEmpty) return name;
    return LocaleKeys.matchmaker_cases_action_message.t(context);
  }

  /// The single status signal as a compact chip: the formal-request status
  /// (gold "interest") once the case reaches the formal track, otherwise the
  /// stage (muted "meta"). `null` when the value is unknown — no chip.
  Widget? _statusChip(BuildContext context) {
    final formal = caseItem.formalRequest;
    final String? labelKey;
    final IconData? icon;
    final QeranChipVariant variant;
    if (formal != null) {
      labelKey = formalStatusLabelKey(formal.status);
      icon = formalStatusIcon(formal.status);
      variant = QeranChipVariant.interest;
    } else {
      labelKey = stageLabelKey(caseItem.stage);
      icon = stageIcon(caseItem.stage);
      variant = QeranChipVariant.meta;
    }
    if (labelKey == null) return null;
    return QeranChip(
      label: labelKey.t(context),
      variant: variant,
      icon: icon,
      compact: true,
    );
  }

  Widget? _dateLine(BuildContext context) {
    final d = caseItem.likeAcceptedAt;
    if (d == null) return null;
    final text =
        '${LocaleKeys.matchmaker_cases_like_accepted_at.t(context)} '
        '${_formatDate(d)}';
    return Text(
      text,
      style: QeranTypography.caption.copyWith(color: QeranColors.inkFaint),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}
