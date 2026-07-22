import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_sheet.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_filter_selection.dart';
import '../blocs/discovery_filter_cubit.dart';
import '../blocs/discovery_filter_state.dart';
import '../widgets/filter_question_renderer.dart';

/// The filter sheet's result on Save: the flat query [payload] (fed straight
/// into `DiscoveryCubit.applyFilters`) plus the raw [selections] snapshot, kept
/// by the deck so the sheet re-seeds with the applied state when it reopens.
typedef DiscoveryFilterResult = ({
  Map<String, String> payload,
  Map<int, DiscoveryFilterSelection> selections,
});

/// Convenience opener for the dynamic discovery filter, on the shared DS
/// bottom-sheet shell ([QeranBottomSheetScaffold]).
///
/// [initialSelections] seeds the draft so already-applied facets open as
/// selected. Returns a [DiscoveryFilterResult] on Save, or `null` if the user
/// dismissed the sheet without applying. An empty payload means the user
/// applied with no selections — the caller treats that as "clear all filters".
Future<DiscoveryFilterResult?> showDiscoveryFilterSheet(
  BuildContext context, {
  Map<int, DiscoveryFilterSelection> initialSelections = const {},
}) {
  return showQeranBottomSheet<DiscoveryFilterResult>(
    context: context,
    builder: (_) => BlocProvider<DiscoveryFilterCubit>(
      create: (_) => DiscoveryFilterCubit(
        getFilters: sl(),
        initialSelections: initialSelections,
      )..loadFilters(),
      child: const _DiscoveryFilterSheet(),
    ),
  );
}

class _DiscoveryFilterSheet extends StatelessWidget {
  const _DiscoveryFilterSheet();

  @override
  Widget build(BuildContext context) {
    return QeranBottomSheetScaffold(
      title: LocaleKeys.discovery_filter_title.t(context),
      body: const _Content(),
      footer: const _Footer(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryFilterCubit, DiscoveryFilterState>(
      builder: (context, state) {
        return switch (state) {
          DiscoveryFilterInitial() || DiscoveryFilterLoading() => const Padding(
            padding: EdgeInsets.all(QeranSpacing.s48),
            child: Center(child: QeranLoader()),
          ),
          DiscoveryFilterFailure(message: final msg) => QeranErrorState(
            title: LocaleKeys.discovery_filter_load_failed.t(context),
            message: msg.t(context),
            retryLabel: LocaleKeys.discovery_error_retry.t(context),
            onRetry: () => context.read<DiscoveryFilterCubit>().loadFilters(),
          ),
          DiscoveryFilterLoaded(
            questions: final qs,
            selections: final sel,
          ) =>
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QeranSpacing.s20,
                QeranSpacing.s8,
                QeranSpacing.s20,
                QeranSpacing.s24,
              ),
              itemCount: qs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: QeranSpacing.s20),
              itemBuilder: (_, i) => FilterQuestionRenderer(
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
    final cubit = context.read<DiscoveryFilterCubit>();
    // Commit + close; the opener applies the payload and refreshes the deck.
    Navigator.of(context).pop((
      payload: cubit.buildPayload(),
      selections: cubit.currentSelections(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryFilterCubit, DiscoveryFilterState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, state) {
        final enabled = state is DiscoveryFilterLoaded;
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
                  label: LocaleKeys.discovery_filter_clear_all.t(context),
                  variant: QeranButtonVariant.ghost,
                  // Clears facets + ranges in place; Apply commits the payload.
                  onPressed: enabled
                      ? () => context.read<DiscoveryFilterCubit>().clearAll()
                      : null,
                ),
              ),
              QeranSpacing.hs12,
              Expanded(
                child: QeranButton(
                  label: LocaleKeys.discovery_filter_save_cta.t(context),
                  variant: QeranButtonVariant.primaryWine,
                  onPressed: enabled ? () => _apply(context) : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
