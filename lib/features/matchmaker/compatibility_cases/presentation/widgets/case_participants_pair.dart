import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/enum/gender.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../domain/entities/case_user.dart';

/// The two participants of a compatibility case, rendered identically across
/// the list card and the detail hero: unblurred avatars + first names
/// (age/gender shown only when present), joined by a gold heart. With
/// [showRoleLabels] each participant is marked by OWNERSHIP; the list card
/// omits the labels to stay scannable.
///
/// The labels used to be positional — slot 1 was always "مستخدمي" and slot 2
/// always "الطرف الآخر" — which read as "this one is not mine" even when BOTH
/// participants belonged to this matchmaker. They are now driven by
/// `CaseUser.isAssignedToMe`, the same field that decides the contact chips:
///   mine → "مستخدمي" · a colleague's → that colleague's name
///   · nobody's → "بلا خطّابة".
class CaseParticipantsPair extends StatelessWidget {
  const CaseParticipantsPair({
    super.key,
    required this.myUser,
    required this.otherUser,
    this.avatarSize = 56,
    this.showRoleLabels = false,
    this.otherMatchmakerName,
  });

  final CaseUser myUser;
  final CaseUser otherUser;
  final double avatarSize;
  final bool showRoleLabels;

  /// The other side's matchmaker (`CaseChat.otherMatchmakerName`). Null when
  /// the other participant is mine or has no matchmaker — never fabricated.
  final String? otherMatchmakerName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ParticipantColumn(
            user: myUser,
            avatarSize: avatarSize,
            roleLabel: showRoleLabels ? _roleLabelFor(context, myUser) : null,
            isMine: myUser.isAssignedToMe,
          ),
        ),
        _Connector(height: avatarSize),
        Expanded(
          child: _ParticipantColumn(
            user: otherUser,
            avatarSize: avatarSize,
            roleLabel: showRoleLabels ? _roleLabelFor(context, otherUser) : null,
            isMine: otherUser.isAssignedToMe,
          ),
        ),
      ],
    );
  }

  /// Ownership label for one participant. A colleague's name is preferred over
  /// the generic "الطرف الآخر" when the server sent one; with no name and no
  /// assignment the participant genuinely has no matchmaker.
  String _roleLabelFor(BuildContext context, CaseUser user) {
    if (user.isAssignedToMe) {
      return LocaleKeys.matchmaker_cases_mine.t(context);
    }
    final owner = otherMatchmakerName?.trim() ?? '';
    if (owner.isNotEmpty) return owner;
    return LocaleKeys.matchmaker_cases_party_unassigned.t(context);
  }
}

class _ParticipantColumn extends StatelessWidget {
  const _ParticipantColumn({
    required this.user,
    required this.avatarSize,
    required this.roleLabel,
    required this.isMine,
  });

  final CaseUser user;
  final double avatarSize;

  /// Already-resolved label text (the pair owns the ownership decision).
  final String? roleLabel;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final meta = _meta();
    final roleKey = roleLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchmakerUserAvatar(
          url: user.profileImageUrl,
          size: avatarSize,
          monogramName: user.name,
        ),
        QeranSpacing.vs8,
        Text(
          user.name,
          style: QeranTypography.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (meta != null) ...[QeranSpacing.vs4, meta],
        if (roleKey != null) ...[QeranSpacing.vs8, _roleChip(roleKey)],
      ],
    );
  }

  Widget _roleChip(String label) {
    // Mine → solid wine chip / white; not mine → soft wine-tinted chip. The
    // label text is already resolved by the parent.
    if (isMine) {
      return QeranChip(
        label: label,
        variant: QeranChipVariant.score,
        compact: true,
        icon: Icons.person_rounded,
      );
    }
    return QeranChip(
      label: label,
      variant: QeranChipVariant.status,
      statusColor: QeranColors.wine,
      compact: true,
      maxWidth: 120,
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
  const _Connector({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: QeranSpacing.s8),
        child: Center(
          child:
              Icon(Icons.favorite_rounded, size: 18, color: QeranColors.gold),
        ),
      ),
    );
  }
}
