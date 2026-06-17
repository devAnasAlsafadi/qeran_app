import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
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

/// Parallel explore filter sheet — provides a [MatchmakerExploreFilterCubit]
/// (mirroring discovery's, but discovery is untouched) and reuses the discovery
/// leaf sub-widgets via [MatchmakerExploreFilterRenderer]. Returns the chosen
/// [ExploreFilterResult] on apply (an all-empty result from "clear"); `null` if
/// dismissed.
Future<ExploreFilterResult?> showMatchmakerExploreFilterSheet(
  BuildContext context, {
  Map<int, DiscoveryFilterSelection> initialSelections = const {},
}) {
  return showModalBottomSheet<ExploreFilterResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider<MatchmakerExploreFilterCubit>(
      create: (_) => MatchmakerExploreFilterCubit(
        getFilters: sl(),
        initialSelections: initialSelections,
      )..loadFilters(),
      child: const _ExploreFilterBody(),
    ),
  );
}

class _ExploreFilterBody extends StatelessWidget {
  const _ExploreFilterBody();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: [
          const _Header(),
          const Expanded(child: _Content()),
          const _Footer(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s12,
        QeranSpacing.s4,
      ),
      child: Column(
        children: [
          const Center(child: QeranSheetHandle()),
          QeranSpacing.vs12,
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.matchmaker_explore_filter_title.t(context),
                  style: QeranTypography.title,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: QeranColors.wine,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
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
            const Center(child: QeranLoader()),
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
                ? Center(
                    child: Text(
                      LocaleKeys.matchmaker_explore_filter_empty.t(context),
                      style: QeranTypography.body
                          .copyWith(color: QeranColors.inkMuted),
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
                        const SizedBox(height: QeranSpacing.s12),
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

  /// Pops the current selections + the trimmed range maps.
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QeranButton(
                label: LocaleKeys.matchmaker_explore_filter_apply.t(context),
                variant: QeranButtonVariant.primaryWine,
                onPressed: loaded ? () => _apply(context) : null,
              ),
              QeranSpacing.vs8,
              QeranButton(
                label: LocaleKeys.matchmaker_explore_filter_clear.t(context),
                variant: QeranButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop((
                  selections: const <int, DiscoveryFilterSelection>{},
                  rangeFrom: const <int, double>{},
                  rangeTo: const <int, double>{},
                )),
              ),
            ],
          ),
        );
      },
    );
  }
}
