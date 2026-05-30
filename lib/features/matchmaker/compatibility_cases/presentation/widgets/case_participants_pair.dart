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
/// [showRoleLabels] the detail view marks the matchmaker's own user
/// ("مستخدمي", a wine chip) and the other party (a muted caption); the list
/// card omits these to stay scannable.
class CaseParticipantsPair extends StatelessWidget {
  const CaseParticipantsPair({
    super.key,
    required this.myUser,
    required this.otherUser,
    this.avatarSize = 56,
    this.showRoleLabels = false,
  });

  final CaseUser myUser;
  final CaseUser otherUser;
  final double avatarSize;
  final bool showRoleLabels;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ParticipantColumn(
            user: myUser,
            avatarSize: avatarSize,
            roleLabelKey:
                showRoleLabels ? LocaleKeys.matchmaker_cases_mine : null,
            isMine: true,
          ),
        ),
        _Connector(height: avatarSize),
        Expanded(
          child: _ParticipantColumn(
            user: otherUser,
            avatarSize: avatarSize,
            roleLabelKey:
                showRoleLabels ? LocaleKeys.matchmaker_cases_other_party : null,
            isMine: false,
          ),
        ),
      ],
    );
  }
}

class _ParticipantColumn extends StatelessWidget {
  const _ParticipantColumn({
    required this.user,
    required this.avatarSize,
    required this.roleLabelKey,
    required this.isMine,
  });

  final CaseUser user;
  final double avatarSize;
  final String? roleLabelKey;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final meta = _meta();
    final roleKey = roleLabelKey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MatchmakerUserAvatar(url: user.profileImageUrl, size: avatarSize),
        QeranSpacing.vs8,
        Text(
          user.firstName,
          style: QeranTypography.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        if (meta != null) ...[QeranSpacing.vs4, meta],
        if (roleKey != null) ...[QeranSpacing.vs8, _roleLabel(context, roleKey)],
      ],
    );
  }

  Widget _roleLabel(BuildContext context, String key) {
    if (isMine) {
      return QeranChip(
        label: key.t(context),
        variant: QeranChipVariant.status,
        statusColor: QeranColors.wine,
        compact: true,
        icon: Icons.person_rounded,
      );
    }
    return Text(
      key.t(context),
      style: QeranTypography.caption,
      textAlign: TextAlign.center,
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
