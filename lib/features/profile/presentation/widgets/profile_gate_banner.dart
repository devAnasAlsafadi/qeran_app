import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_status.dart';
import '../blocs/profile_gate/profile_gate_cubit.dart';
import '../blocs/profile_gate/profile_gate_state.dart';

/// Inline "your profile is under review" notice shown on the gated screens
/// (Discovery / Likes / Subscriptions) while the signed-in user's profile is
/// NOT approved. Renders zero-size when the gate is open — Visible, loading, or
/// unavailable (fail-open). Decoration only; disabling the actions themselves
/// lives at each action's call site (see the cubit approval guards).
class ProfileGateBanner extends StatelessWidget {
  const ProfileGateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileGateCubit, ProfileGateState>(
      builder: (context, state) {
        if (state is! ProfileGateResolved ||
            state.status == ProfileStatus.visible) {
          return const SizedBox.shrink();
        }
        return _Banner(status: state.status);
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.status});

  final ProfileStatus status;

  @override
  Widget build(BuildContext context) {
    // Reuses the owner-facing profile-status copy: pending → "awaiting review",
    // hidden/rejected → the "contact your matchmaker" variants.
    final messageKey = switch (status) {
      ProfileStatus.hidden => LocaleKeys.profile_status_hidden,
      ProfileStatus.rejected => LocaleKeys.profile_status_rejected,
      _ => LocaleKeys.profile_status_pending_review,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s8,
        QeranSpacing.s16,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            size: 18,
            color: QeranColors.goldDeep,
          ),
          QeranSpacing.hs8,
          Expanded(
            child: Text(
              messageKey.t(context),
              style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
            ),
          ),
        ],
      ),
    );
  }
}
