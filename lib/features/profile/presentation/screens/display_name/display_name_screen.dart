import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../domain/entities/display_name_lock.dart';
import '../../blocs/display_name/display_name_cubit.dart';
import '../../blocs/display_name/display_name_state.dart';
import 'widgets/display_name_form.dart';
import 'widgets/display_name_notice.dart';
import 'widgets/display_name_readonly_card.dart';

/// Account-management screen for the member's names. The display name is
/// editable (subject to the backend's 7-day cooldown); the real name is shown
/// but never editable here.
class DisplayNameScreen extends StatelessWidget {
  const DisplayNameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DisplayNameCubit>(
      create: (_) => sl<DisplayNameCubit>()..load(),
      child: const _DisplayNameView(),
    );
  }
}

class _DisplayNameView extends StatelessWidget {
  const _DisplayNameView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.profile_name_screen_title.t(context),
      ),
      body: SafeArea(
        child: BlocConsumer<DisplayNameCubit, DisplayNameState>(
          listenWhen: (previous, current) =>
              previous.eventVersion != current.eventVersion,
          listener: _onEvent,
          builder: (context, state) => switch (state.status) {
            DisplayNameStatus.initial ||
            DisplayNameStatus.loading => const Center(child: QeranLoader()),
            DisplayNameStatus.failure => QeranErrorState(
              title: LocaleKeys.profile_name_load_failed.t(context),
              message: state.errorMessage?.t(context),
              retryLabel: LocaleKeys.profile_retry.t(context),
              onRetry: () => context.read<DisplayNameCubit>().load(),
            ),
            DisplayNameStatus.loaded => _Body(state: state),
          },
        ),
      ),
    );
  }

  void _onEvent(BuildContext context, DisplayNameState state) {
    switch (state.event) {
      case DisplayNameEvent.saved:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_name_save_success.t(context),
          type: SnackBarType.success,
        );
      case DisplayNameEvent.saveFailed:
        AppSnackBar.show(
          context,
          message:
              state.errorMessage?.t(context) ??
              LocaleKeys.profile_name_save_failed.t(context),
          type: SnackBarType.error,
        );
      case DisplayNameEvent.none:
        break;
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final DisplayNameState state;

  @override
  Widget build(BuildContext context) {
    // Resolved once per build: the countdown is rendered in whole days or
    // hours, so it does not need to tick.
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DisplayNameReadOnlyCard(
            displayName: state.displayName,
            realName: state.realName,
          ),
          QeranSpacing.vs24,
          if (state.canEdit(now))
            DisplayNameForm(
              currentName: state.displayName,
              isDefaultName: state.isDefaultName,
              saving: state.saving,
              onSave: (name) => context.read<DisplayNameCubit>().save(name),
            )
          else
            DisplayNameNotice(
              icon: Icons.lock_clock_rounded,
              message: _lockMessage(context, state.lockRemaining(now)),
            ),
        ],
      ),
    );
  }

  /// The cooldown in the unit the UI counts it. A lock with no usable
  /// timestamp still blocks editing — it just says so without a number rather
  /// than inventing one.
  String _lockMessage(BuildContext context, NameLockRemaining? remaining) {
    return switch (remaining) {
      NameLockDays(:final days) => LocaleKeys.profile_name_locked_days
          .t(context)
          .replaceFirst('{days}', '$days'),
      NameLockHours(:final hours) => LocaleKeys.profile_name_locked_hours
          .t(context)
          .replaceFirst('{hours}', '$hours'),
      _ => LocaleKeys.profile_name_locked_generic.t(context),
    };
  }
}
