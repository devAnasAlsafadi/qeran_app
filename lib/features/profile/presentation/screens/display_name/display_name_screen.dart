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

import '../../blocs/display_name/display_name_cubit.dart';
import '../../blocs/display_name/display_name_state.dart';
import 'widgets/name_form.dart';

/// Account-management screen for the member's names. Both the display name and
/// the real name are plain, always-editable inputs saved by one action.
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      child: NameForm(
        // Keyed on the saved pair so a successful write re-seeds the fields
        // from the server's response instead of leaving stale text behind.
        key: ValueKey('${state.displayName}|${state.realName ?? ''}'),
        currentDisplayName: state.displayName,
        currentRealName: state.realName,
        isDefaultName: state.profile?.isDefaultName ?? false,
        saving: state.saving,
        onSave: ({required displayName, realName}) =>
            context.read<DisplayNameCubit>().save(
              displayName: displayName,
              realName: realName,
            ),
      ),
    );
  }
}
