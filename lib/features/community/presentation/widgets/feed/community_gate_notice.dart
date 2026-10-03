import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../profile/domain/entities/profile_status.dart';
import '../../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../../../profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import '../../../../profile/presentation/widgets/profile_gate_icon.dart';

/// Above the feed, while the member can read but not take part (B11, D9):
/// why, in the words of their profile's status. Shown exactly when
/// [ProfileGateCubit.isGated] — the same test that dims Like (S10) — so the
/// notice and the dimmed button never disagree.
class CommunityGateNotice extends StatelessWidget {
  const CommunityGateNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileGateCubit, ProfileGateState>(
      builder: (context, _) {
        final gate = context.read<ProfileGateCubit>();
        if (!gate.isGated) return const SizedBox.shrink();
        final key = switch (gate.status) {
          ProfileStatus.hidden => LocaleKeys.community_gate_hidden,
          ProfileStatus.rejected => LocaleKeys.community_gate_rejected,
          _ => LocaleKeys.community_gate_pending,
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s16,
            0,
            QeranSpacing.s16,
            QeranSpacing.s16,
          ),
          child: QeranNotice(
            icon: profileGateIcon(gate.status),
            text: key.t(context),
          ),
        );
      },
    );
  }
}
