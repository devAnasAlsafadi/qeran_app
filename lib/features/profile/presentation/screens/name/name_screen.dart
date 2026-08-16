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

import '../../blocs/name/name_cubit.dart';
import '../../blocs/name/name_state.dart';
import 'widgets/name_form.dart';

/// Account-management screen for the member's names. Both the display name and
/// the real name are plain, always-editable inputs saved by one action.
class NameScreen extends StatelessWidget {
  const NameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NameCubit>(
      create: (_) => sl<NameCubit>()..load(),
      child: const _NameView(),
    );
  }
}

class _NameView extends StatelessWidget {
  const _NameView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(
        title: LocaleKeys.profile_name_screen_title.t(context),
      ),
      body: SafeArea(
        child: BlocConsumer<NameCubit, NameState>(
          listenWhen: (previous, current) =>
              previous.eventVersion != current.eventVersion,
          listener: _onEvent,
          builder: (context, state) => switch (state.status) {
            NameStatus.initial ||
            NameStatus.loading => const Center(child: QeranLoader()),
            NameStatus.failure => QeranErrorState(
              title: LocaleKeys.profile_name_load_failed.t(context),
              message: state.errorMessage?.t(context),
              retryLabel: LocaleKeys.profile_retry.t(context),
              onRetry: () => context.read<NameCubit>().load(),
            ),
            NameStatus.loaded => _Body(state: state),
          },
        ),
      ),
    );
  }

  void _onEvent(BuildContext context, NameState state) {
    switch (state.event) {
      case NameEvent.saved:
        AppSnackBar.show(
          context,
          message: LocaleKeys.profile_name_save_success.t(context),
          type: SnackBarType.success,
        );
      case NameEvent.saveFailed:
        AppSnackBar.show(
          context,
          message:
              state.errorMessage?.t(context) ??
              LocaleKeys.profile_name_save_failed.t(context),
          type: SnackBarType.error,
        );
      case NameEvent.none:
        break;
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final NameState state;

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
            context.read<NameCubit>().save(
              displayName: displayName,
              realName: realName,
            ),
      ),
    );
  }
}
