import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/effects/ring_motif.dart';
import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/routes/navigation_manager.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import '../../../subscriptions/presentation/blocs/current/current_subscription_state.dart';

/// The Profile tab's invitation to upgrade: a slim wine banner — the title,
/// one line, a small «اكتشف الباقات» beside them (run 8, the client: the
/// card it replaced took half the screen with the name card).
///
/// Shown to everyone who can still upgrade — no subscription, Free or Basic.
/// Hidden for an active VIP (the top tier) and while a purchase is activating
/// (it's already paid for). Backend-driven: tier + isCurrentlyActive, never
/// the plan's name; `lastKnown` too, so a VIP doesn't flash it during a
/// transient /current failure.
class ProfileUpgradeBanner extends StatelessWidget {
  const ProfileUpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
      builder: (context, state) {
        if (!_offered(state)) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.only(top: QeranSpacing.s16),
          child: _Banner(),
        );
      },
    );
  }

  static bool _offered(CurrentSubscriptionState state) {
    final isActiveVip = switch (state) {
      CurrentSubscriptionLoaded(:final subscription) =>
        subscription.isCurrentlyActive && subscription.plan.isVipTier,
      CurrentSubscriptionFailure(:final lastKnown) =>
        lastKnown != null &&
            lastKnown.isCurrentlyActive &&
            lastKnown.plan.isVipTier,
      _ => false,
    };
    return !isActiveVip && state is! CurrentSubscriptionActivating;
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.eHero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.cardR,
        child: Stack(
          children: [
            const PositionedDirectional(
              top: -48,
              end: -48,
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.13,
                size: 128,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(QeranSpacing.s16),
              child: Row(
                children: [
                  const Expanded(child: _Words()),
                  QeranSpacing.hs12,
                  QeranButton(
                    label: LocaleKeys.profile_upsell_cta.t(context),
                    size: QeranButtonSize.compact,
                    fullWidth: false,
                    onPressed: () => NavigationManager.navigateTo(
                      context,
                      RouteNames.packagesScreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title, and the copy pass's line (`15-wording-table.md` §2).
class _Words extends StatelessWidget {
  const _Words();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          LocaleKeys.profile_upsell_title.t(context),
          style: QeranTypography.subtitle.copyWith(
            color: QeranColors.paper,
            fontWeight: FontWeight.w700,
          ),
        ),
        QeranSpacing.vs4,
        Text(
          LocaleKeys.profile_upsell_teaser_1.t(context),
          style: QeranTypography.bodySm.copyWith(color: QeranColors.gold),
        ),
      ],
    );
  }
}
