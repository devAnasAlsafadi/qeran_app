import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/discovery_filter_cubit.dart';
import '../blocs/discovery_filter_state.dart';
import '../widgets/filter_question_renderer.dart';
import '../widgets/filter_sheet_header.dart';

/// Bottom-sheet root for the dynamic filter UI.
///
/// The "Save Changes" button `Navigator.pop`s with the cubit's draft
/// payload (a flat query map) — or the sheet returns `null` if dismissed.
class DiscoveryFilterSheet extends StatelessWidget {
  const DiscoveryFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscoveryFilterCubit>(
      create: (_) => sl<DiscoveryFilterCubit>()..loadFilters(),
      child: const _DiscoveryFilterBody(),
    );
  }
}

/// Convenience opener. Returns the cubit's flat query map
/// (`RangeFrom[...]` / `QuestionFilters[...]` keys) or `null` if the
/// user dismissed the sheet without saving. An empty map means the user
/// saved with no selections — the caller treats that as "clear all
/// filters".
Future<Map<String, String>?> showDiscoveryFilterSheet(
  BuildContext context,
) {
  return showModalBottomSheet<Map<String, String>?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: QeranRadii.domeTop,
    ),
    builder: (_) => const DiscoveryFilterSheet(),
  );
}

class _DiscoveryFilterBody extends StatelessWidget {
  const _DiscoveryFilterBody();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Column(
        children: [
          FilterSheetHeader(onClose: () => Navigator.of(context).pop()),
          const Expanded(child: _SheetContent()),
          const _SheetFooter(),
        ],
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoveryFilterCubit, DiscoveryFilterState>(
      builder: (context, state) {
        return switch (state) {
          DiscoveryFilterInitial() ||
          DiscoveryFilterLoading() => const Center(child: QeranLoader()),
          DiscoveryFilterFailure(message: final msg) => _ErrorView(
              message: msg.t(context),
              onRetry: () =>
                  context.read<DiscoveryFilterCubit>().loadFilters(),
            ),
          DiscoveryFilterLoaded(
            questions: final qs,
            selections: final sel,
          ) =>
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QeranSpacing.s16,
                QeranSpacing.s12,
                QeranSpacing.s16,
                QeranSpacing.s24,
              ),
              itemCount: qs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: QeranSpacing.s12),
              itemBuilder: (_, i) {
                final q = qs[i];
                return FilterQuestionRenderer(
                  question: q,
                  selection: sel[q.id],
                );
              },
            ),
        };
      },
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter();

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
          child: QeranButton(
            label: LocaleKeys.discovery_filter_save_cta.t(context),
            variant: QeranButtonVariant.primaryWine,
            onPressed: enabled
                ? () {
                    final payload =
                        context.read<DiscoveryFilterCubit>().buildPayload();
                    Navigator.of(context).pop(payload);
                  }
                : null,
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: QeranColors.inkMuted,
          ),
          const SizedBox(height: QeranSpacing.s8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
          ),
          const SizedBox(height: QeranSpacing.s12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              LocaleKeys.discovery_error_retry.t(context),
              style: QeranTypography.label.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}
