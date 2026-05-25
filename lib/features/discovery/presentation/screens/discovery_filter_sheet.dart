import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/discovery_filter_cubit.dart';
import '../blocs/discovery_filter_state.dart';
import '../widgets/filter_question_renderer.dart';

/// Bottom-sheet root for the dynamic filter UI.
///
/// **Not yet opened from anywhere** — Chunk D wires the filter button
/// on `DiscoveryView` / Home overlay. This file is the destination so
/// that wiring is a one-line change.
///
/// The "Save Changes" button currently `Navigator.pop`s with the cubit's
/// draft payload (plan §3). Callers do not yet exist — when they do,
/// `await showDiscoveryFilterSheet(...)` will return the payload map.
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
    backgroundColor: AppColors.background,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimens.p24),
      ),
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
          const _SheetHeader(),
          const Expanded(child: _SheetContent()),
          const _SheetFooter(),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p16,
        AppDimens.p8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleCloseButton(onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              Text(
                LocaleKeys.discovery_filter_title.t(context),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p8),
          Padding(
            padding: const EdgeInsets.only(left: AppDimens.p48),
            child: Text(
              LocaleKeys.discovery_filter_subtitle.t(context),
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greyLight,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
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
          DiscoveryFilterLoading() =>
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
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
                AppDimens.p16,
                AppDimens.p12,
                AppDimens.p16,
                AppDimens.p24,
              ),
              itemCount: qs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimens.p12),
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
            AppDimens.p20,
            AppDimens.p8,
            AppDimens.p20,
            AppDimens.p16,
          ),
          child: CustomButton(
            text: LocaleKeys.discovery_filter_save_cta.t(context),
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
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.p12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              LocaleKeys.discovery_error_retry.t(context),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
