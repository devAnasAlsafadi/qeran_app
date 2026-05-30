import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/enum/gender.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/case_user.dart';
import '../../domain/entities/compatibility_case.dart';
import 'matchmaker_case_labels.dart';

/// One compatibility-case card: the two participants as unblurred avatars
/// with their names (age + gender shown only when the server sends them),
/// joined by a gold heart, under a single status chip — the formal-request
/// status when the case has reached the formal track (gold), otherwise the
/// stage (muted). A muted line shows when the like was accepted. Tappable;
/// the detail + status-update actions are wired in 3b.
class MatchmakerCaseCard extends StatelessWidget {
  const MatchmakerCaseCard({super.key, required this.caseItem, this.onTap});

  final CompatibilityCase caseItem;
  final VoidCallback? onTap;

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
          if (statusChip != null) ...[statusChip, QeranSpacing.vs16],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _CaseUserColumn(user: caseItem.myUser)),
              const _Connector(),
              Expanded(child: _CaseUserColumn(user: caseItem.otherUser)),
            ],
          ),
          if (dateLine != null) ...[QeranSpacing.vs16, dateLine],
        ],
      ),
    );
  }

  /// The single primary signal: the formal-request status (gold "interest"
  /// chip) once the case reaches the formal track, otherwise the stage
  /// (muted "meta" chip). `null` when the value is unknown — no chip.
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
    return QeranChip(label: labelKey.t(context), variant: variant, icon: icon);
  }

  Widget? _dateLine(BuildContext context) {
    final d = caseItem.likeAcceptedAt;
    if (d == null) return null;
    final text =
        '${LocaleKeys.matchmaker_cases_like_accepted_at.t(context)} '
        '${_formatDate(d)}';
    return Center(child: Text(text, style: QeranTypography.caption));
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$day';
  }
}

/// One participant: centered avatar + first name + optional age/gender meta.
class _CaseUserColumn extends StatelessWidget {
  const _CaseUserColumn({required this.user});

  final CaseUser user;

  @override
  Widget build(BuildContext context) {
    final meta = _meta();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchmakerUserAvatar(url: user.profileImageUrl, size: 56),
        QeranSpacing.vs8,
        Text(
          user.firstName,
          style: QeranTypography.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (meta != null) ...[QeranSpacing.vs4, meta],
      ],
    );
  }

  /// Age + gender, shown only when present. `null` when the server sent
  /// neither (the current payload omits both).
  Widget? _meta() {
    final parts = <Widget>[];
    if (user.age != null) {
      parts.add(Text('${user.age}', style: QeranTypography.caption));
    }
    final g = user.gender;
    if (g != null) {
      if (parts.isNotEmpty) parts.add(QeranSpacing.hs4);
      parts.add(Icon(_genderIcon(g), size: 14, color: QeranColors.wine));
    }
    if (parts.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}

IconData _genderIcon(Gender g) => switch (g) {
      Gender.male => Icons.male_rounded,
      Gender.female => Icons.female_rounded,
    };

/// The gold heart joining the two participants, sized to sit centered on
/// the avatars (which lead each column).
class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
        child: Center(
          child: Icon(Icons.favorite_rounded, size: 18, color: QeranColors.gold),
        ),
      ),
    );
  }
}
