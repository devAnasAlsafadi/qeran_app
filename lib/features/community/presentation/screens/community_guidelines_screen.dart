import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../blocs/guidelines/community_guidelines_cubit.dart';
import '../blocs/guidelines/community_guidelines_state.dart';
import '../widgets/guidelines/guidelines_action_bar.dart';
import '../widgets/guidelines/guidelines_text.dart';

/// The guidelines step's body (F5, J3): the server's text scrolls, and the
/// choice stays pinned on the safe area — «أوافق وأتابع» once there's text
/// to agree to, «ليس الآن» always (S6).
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityGuidelinesCubit>();
    return BlocConsumer<CommunityGuidelinesCubit, CommunityGuidelinesState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion,
      listener: _onEvent,
      builder: (context, state) => Column(
        children: [
          Expanded(child: _content(context, state)),
          GuidelinesActionBar(
            accepting: state.accepting,
            onAgree: state.canAccept ? cubit.accept : null,
            onNotNow: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, CommunityGuidelinesState state) =>
      switch (state.status) {
        CommunityGuidelinesStatus.loading => const Center(child: QeranLoader()),
        CommunityGuidelinesStatus.failed => QeranErrorState(
          title: LocaleKeys.community_guidelines_error.t(context),
          retryLabel: LocaleKeys.community_retry
              .forReader(her: LocaleKeys.community_her_retry)
              .t(context),
          onRetry: () => context.read<CommunityGuidelinesCubit>().load(),
        ),
        CommunityGuidelinesStatus.ready => GuidelinesText(
          guidelines: state.guidelines!,
        ),
      };

  void _onEvent(BuildContext context, CommunityGuidelinesState state) {
    switch (state.event) {
      case CommunityGuidelinesEvent.accepted:
        Navigator.of(context).pop(true);
      case CommunityGuidelinesEvent.acceptFailed:
        AppSnackBar.show(
          context,
          message: LocaleKeys.community_guidelines_accept_failed
              .forReader(her: LocaleKeys.community_her_guidelines_accept_failed)
              .t(context),
          type: SnackBarType.error,
        );
      case CommunityGuidelinesEvent.none:
        break;
    }
  }
}
