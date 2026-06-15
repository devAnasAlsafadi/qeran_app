import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_chip.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/subscription_plan.dart';
import '../blocs/subscription_plans_cubit.dart';
import '../blocs/subscription_plans_state.dart';

/// Horizontal, scrollable plan-filter rail shown ONLY under the مشتركون tab.
///
/// One [QeranChip] per [SubscriptionPlan] (plus a leading "All" chip),
/// generated from the dynamic `subscription-plans` list — never hardcoded.
/// Selected = wine (`score`), unselected = gold (`interest`); every plan wears
/// the same gold tier, the NAME is the differentiator (no per-plan hue).
/// `*Directional` padding mirrors RTL/LTR automatically.
///
/// The rail is additive: it renders nothing until plans load, and a load
/// failure simply leaves the list unfiltered (no error surface — "All" only).
class MatchmakerPlanFilterRail extends StatelessWidget {
  const MatchmakerPlanFilterRail({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
      builder: (context, state) {
        // No rail until there's something to filter by.
        if (!state.hasPlans) return const SizedBox.shrink();

        final isArabic = context.locale.languageCode == 'ar';
        final cubit = context.read<SubscriptionPlansCubit>();
        final selected = state.selectedPlanId;

        return SizedBox(
          height: _kRailHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s20,
              QeranSpacing.s2,
              QeranSpacing.s20,
              QeranSpacing.s8,
            ),
            itemCount: state.plans.length + 1, // +1 for the leading "All" chip
            separatorBuilder: (_, _) => QeranSpacing.hs8,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _PlanChip(
                  label: LocaleKeys.matchmaker_users_plan_filter_all.t(context),
                  selected: selected == null,
                  onTap: () => cubit.select(null),
                );
              }
              final plan = state.plans[index - 1];
              return _PlanChip(
                label: _labelFor(plan, isArabic: isArabic),
                selected: selected == plan.planId,
                onTap: () => cubit.select(plan.planId),
              );
            },
          ),
        );
      },
    );
  }

  /// "PlanName · N" — the subscriber count trails the name in the same pill.
  static String _labelFor(SubscriptionPlan plan, {required bool isArabic}) =>
      '${plan.name(isArabic: isArabic)} · ${plan.subscriberCount}';

  static const double _kRailHeight = 44;
}

/// One rail pill. Wine when selected, gold when not — both via existing
/// [QeranChip] variants, so no new tokens or widgets.
class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      // Keep each pill vertically centred in the rail's fixed height.
      alignment: Alignment.center,
      // Ease the wine↔gold state change instead of a hard jump. Keyed on
      // [selected] so the switcher cross-fades the two variants at the
      // chip-selection tempo. QeranChip itself is untouched (shared widget).
      child: AnimatedSwitcher(
        duration: QeranMotion.fast,
        switchInCurve: QeranCurves.standard,
        switchOutCurve: QeranCurves.standard,
        // Both pills occupy the same box; a plain fade reads as a tone shift.
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.center,
          children: [...previous, ?current],
        ),
        child: QeranChip(
          key: ValueKey(selected),
          label: label,
          variant:
              selected ? QeranChipVariant.score : QeranChipVariant.interest,
          icon: Icons.workspace_premium_outlined,
          onTap: onTap,
        ),
      ),
    );
  }
}
