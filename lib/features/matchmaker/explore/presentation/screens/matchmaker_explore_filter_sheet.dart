import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../blocs/matchmaker_explore_filter_cubit.dart';
import '../blocs/matchmaker_explore_filter_state.dart';
import '../widgets/matchmaker_explore_filter_renderer.dart';

/// The filter sheet's result: the raw [selections] (to re-seed the sheet +
/// derive `QuestionFilters`) plus the already-trimmed numeric [rangeFrom] /
/// [rangeTo] maps (`RangeFrom[id]`/`RangeTo[id]`).
typedef ExploreFilterResult = ({
  Map<int, DiscoveryFilterSelection> selections,
  Map<int, double> rangeFrom,
  Map<int, double> rangeTo,
});

/// Explore filter sheet (09) — dynamic, backend-driven facets rendered as
/// branded chip-groups + a gold range slider on the shared sheet shell.
/// Returns the chosen [ExploreFilterResult] on apply; `null` if dismissed.
Future<ExploreFilterResult?> showMatchmakerExploreFilterSheet(
  BuildContext context, {
  Map<int, DiscoveryFilterSelection> initialSelections = const {},
}) {
  return showQeranBottomSheet<ExploreFilterResult>(
    context: context,
    builder: (_) => BlocProvider<MatchmakerExploreFilterCubit>(
      create: (_) => MatchmakerExploreFilterCubit(
        getFilters: sl(),
        initialSelections: initialSelections,
      )..loadFilters(),
      child: const _ExploreFilterSheet(),
    ),
  );
}

class _ExploreFilterSheet extends StatelessWidget {
  const _ExploreFilterSheet();

  @override
  Widget build(BuildContext context) {
    return QeranBottomSheetScaffold(
      title: LocaleKeys.matchmaker_explore_filter_title.t(context),
      body: const _Content(),
      footer: const _Footer(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerExploreFilterCubit,
        MatchmakerExploreFilterState>(
      builder: (context, state) {
        return switch (state) {
          MatchmakerExploreFilterInitial() ||
          MatchmakerExploreFilterLoading() =>
            const Padding(
              padding: EdgeInsets.all(QeranSpacing.s48),
              child: Center(child: QeranLoader()),
            ),
          MatchmakerExploreFilterFailure(message: final msg) => QeranErrorState(
              title: LocaleKeys.matchmaker_explore_filter_error.t(context),
              message: msg.t(context),
              retryLabel: LocaleKeys.matchmaker_explore_filter_retry.t(context),
              onRetry: () =>
                  context.read<MatchmakerExploreFilterCubit>().loadFilters(),
            ),
          MatchmakerExploreFilterLoaded(
            questions: final qs,
            selections: final sel,
          ) =>
            qs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(QeranSpacing.s32),
                    child: Center(
                      child: Text(
                        LocaleKeys.matchmaker_explore_filter_empty.t(context),
                        textAlign: TextAlign.center,
                        style: QeranTypography.body
                            .copyWith(color: QeranColors.inkMuted),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      QeranSpacing.s20,
                      QeranSpacing.s8,
                      QeranSpacing.s20,
                      QeranSpacing.s24,
                    ),
                    itemCount: qs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: QeranSpacing.s20),
                    itemBuilder: (_, i) => MatchmakerExploreFilterRenderer(
                      question: qs[i],
                      selection: sel[qs[i].id],
                    ),
                  ),
        };
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  void _apply(BuildContext context) {
    final cubit = context.read<MatchmakerExploreFilterCubit>();
    final ranges = cubit.buildRangeFilters();
    Navigator.of(context).pop((
      selections: cubit.currentSelections(),
      rangeFrom: ranges.from,
      rangeTo: ranges.to,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerExploreFilterCubit,
        MatchmakerExploreFilterState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, state) {
        final loaded = state is MatchmakerExploreFilterLoaded;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s8,
            QeranSpacing.s20,
            QeranSpacing.s16,
          ),
          child: Row(
            children: [
              Expanded(
                child: QeranButton(
                  label:
                      LocaleKeys.matchmaker_explore_filter_clear.t(context),
                  variant: QeranButtonVariant.ghost,
                  // Clears in-place (facets + ranges); تطبيق commits it.
                  onPressed: loaded
                      ? () =>
                          context.read<MatchmakerExploreFilterCubit>().clearAll()
                      : null,
                ),
              ),
              QeranSpacing.hs12,
              Expanded(
                flex: 2,
                child: QeranButton(
                  label:
                      LocaleKeys.matchmaker_explore_filter_apply.t(context),
                  variant: QeranButtonVariant.primary,
                  onPressed: loaded ? () => _apply(context) : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
