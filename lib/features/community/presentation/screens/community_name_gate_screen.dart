import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../core/enum/snakebar_tybe.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../profile/presentation/blocs/name/name_cubit.dart';
import '../../../profile/presentation/blocs/name/name_state.dart';
import '../widgets/name_gate/name_gate_form.dart';

/// The name step's body (F1–F3): the member's profile, then the form.
/// Saving a real name closes the step with true — and a member who turns
/// out to have one already (named on another phone) goes straight through.
class CommunityNameGateScreen extends StatelessWidget {
  const CommunityNameGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NameCubit, NameState>(
          listenWhen: (previous, current) =>
              previous.status != NameStatus.loaded &&
              current.status == NameStatus.loaded,
          listener: _onLoaded,
        ),
        BlocListener<NameCubit, NameState>(
          listenWhen: (previous, current) =>
              previous.eventVersion != current.eventVersion,
          listener: _onEvent,
        ),
      ],
      child: BlocBuilder<NameCubit, NameState>(builder: _body),
    );
  }

  Widget _body(BuildContext context, NameState state) => switch (state.status) {
    NameStatus.initial ||
    NameStatus.loading => const Center(child: QeranLoader()),
    NameStatus.failure => QeranErrorState(
      title: LocaleKeys.profile_name_load_failed.t(context),
      message: state.errorMessage?.t(context),
      retryLabel: LocaleKeys.profile_retry.t(context),
      onRetry: () => context.read<NameCubit>().load(),
    ),
    NameStatus.loaded => NameGateForm(state: state),
  };

  /// Already named: there's nothing to ask.
  void _onLoaded(BuildContext context, NameState state) {
    if (state.profile?.isDefaultName == false) {
      Navigator.of(context).pop(true);
    }
  }

  void _onEvent(BuildContext context, NameState state) {
    switch (state.event) {
      case NameEvent.saved:
        Navigator.of(context).pop(true);
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
