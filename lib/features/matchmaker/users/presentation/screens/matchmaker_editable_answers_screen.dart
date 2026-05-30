import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_skeleton.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/matchmaker_editable_answer.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';
import '../blocs/matchmaker_answer_save_state.dart';
import '../blocs/matchmaker_editable_answers_cubit.dart';
import '../widgets/matchmaker_editable_answer_row.dart';

/// Editable text answers for one user. Shown only from PendingReview /
/// Rejected profiles (the entry point gates eligibility). Each row reads →
/// inline edits → saves; a successful save updates the row in place.
class MatchmakerEditableAnswersScreen extends StatelessWidget {
  const MatchmakerEditableAnswersScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<MatchmakerEditableAnswersCubit>(param1: userId)..loadFirst(),
        ),
        BlocProvider(
          create: (_) => sl<MatchmakerAnswerSaveCubit>(param1: userId),
        ),
      ],
      child: const _EditableAnswersView(),
    );
  }
}

class _EditableAnswersView extends StatelessWidget {
  const _EditableAnswersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.matchmaker_answers_title.t(context),
      ),
      body: BlocListener<MatchmakerAnswerSaveCubit, MatchmakerAnswerSaveState>(
        listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
        listener: _onSaveOutcome,
        child: BlocBuilder<MatchmakerEditableAnswersCubit,
            PaginatedListState<MatchmakerEditableAnswer>>(
          builder: (context, state) {
            final cubit = context.read<MatchmakerEditableAnswersCubit>();
            if (state.isLoading && state.items.isEmpty) {
              return const _AnswersSkeleton();
            }
            if (state.errorMessage != null && state.items.isEmpty) {
              return QeranErrorState(
                title: LocaleKeys.matchmaker_answers_error_title.t(context),
                message: state.errorMessage!.t(context),
                retryLabel: LocaleKeys.matchmaker_profile_retry.t(context),
                onRetry: cubit.loadFirst,
              );
            }
            if (state.items.isEmpty) {
              return _EmptyRefreshable(onRefresh: cubit.refresh);
            }
            return MatchmakerPaginatedList(
              hasMore: state.hasMore,
              onRefresh: cubit.refresh,
              onLoadMore: cubit.loadMore,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  QeranSpacing.s20,
                  QeranSpacing.s8,
                  QeranSpacing.s20,
                  QeranSpacing.s20,
                ),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const MatchmakerLoadMoreFooter();
                  }
                  return MatchmakerEditableAnswerRow(answer: state.items[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSaveOutcome(BuildContext context, MatchmakerAnswerSaveState state) {
    switch (state.outcome) {
      case AnswerSaveOutcome.success:
        final qid = state.lastQuestionId;
        final answer = state.lastAnswer;
        if (qid != null && answer != null) {
          context
              .read<MatchmakerEditableAnswersCubit>()
              .applyUpdate(qid, answer);
        }
        AppSnackBar.show(
          context,
          message: LocaleKeys.matchmaker_answers_save_success.t(context),
          type: SnackBarType.success,
        );
      case AnswerSaveOutcome.failure:
        AppSnackBar.show(
          context,
          message:
              (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
          type: SnackBarType.error,
        );
      case AnswerSaveOutcome.none:
        break;
    }
  }
}

class _AnswersSkeleton extends StatelessWidget {
  const _AnswersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s20,
        QeranSpacing.s20,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: QeranSpacing.s12),
          child: QeranSkeleton.box(height: 104),
        ),
      ),
    );
  }
}

/// Empty state that still scrolls so pull-to-refresh works.
class _EmptyRefreshable extends StatelessWidget {
  const _EmptyRefreshable({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return MatchmakerPaginatedList(
      hasMore: false,
      onRefresh: onRefresh,
      onLoadMore: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: QeranEmptyState(
              icon: Icons.edit_note_rounded,
              title: LocaleKeys.matchmaker_answers_empty_title.t(context),
              message: LocaleKeys.matchmaker_answers_empty_message.t(context),
            ),
          ),
        ),
      ),
    );
  }
}
