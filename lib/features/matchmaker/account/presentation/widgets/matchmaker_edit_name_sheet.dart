import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_account_cubit.dart';
import '../blocs/matchmaker_account_state.dart';

/// Edit-name bottom sheet — shares the screen's [MatchmakerAccountCubit] (passed
/// via `BlocProvider.value`). Prefilled, ≤100 chars, save → `updateName`. On
/// success: toast + close. A VALIDATION_ERROR shows inline (the cubit preserves
/// the errorCode); the screen ignores that kind so it isn't double-toasted.
Future<void> showMatchmakerEditNameSheet(
  BuildContext context, {
  required MatchmakerAccountCubit cubit,
  required String currentName,
}) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _EditNameSheet(currentName: currentName),
    ),
  );
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.currentName});

  final String currentName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentName);
  String? _inlineError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave => _controller.text.trim().isNotEmpty;

  void _onChanged(String _) {
    if (_inlineError != null) setState(() => _inlineError = null);
  }

  void _save(MatchmakerAccountCubit cubit) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    cubit.updateName(name);
  }

  void _onOutcome(BuildContext context, MatchmakerAccountState state) {
    if (state.outcome == MatchmakerAccountOutcome.saveNameSuccess) {
      AppSnackBar.showOnRoot(
        message: LocaleKeys.matchmaker_account_name_saved.t(context),
        type: SnackBarType.success,
      );
      Navigator.of(context).pop();
    } else if (state.outcome == MatchmakerAccountOutcome.failure &&
        state.errorKind == MatchmakerAccountErrorKind.validation) {
      setState(() => _inlineError =
          (state.actionErrorKey ?? LocaleKeys.errors_generic).t(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MatchmakerAccountCubit>();
    return BlocConsumer<MatchmakerAccountCubit, MatchmakerAccountState>(
      listenWhen: (p, c) => p.eventVersion != c.eventVersion,
      listener: _onOutcome,
      builder: (context, state) {
        final saving = state.inFlight == MatchmakerAccountAction.savingName;
        return QeranBottomSheetScaffold(
          title: LocaleKeys.matchmaker_account_edit_name_title.t(context),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s4,
              QeranSpacing.s20,
              QeranSpacing.s16,
            ),
            child: QeranTextField(
              controller: _controller,
              hint: LocaleKeys.matchmaker_account_name_hint.t(context),
              textInputAction: TextInputAction.done,
              maxLength: 100,
              errorText: _inlineError,
              onChanged: _onChanged,
              onSubmitted: (_) => _save(cubit),
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              QeranSpacing.s16,
            ),
            child: QeranButton(
              label: LocaleKeys.matchmaker_account_save.t(context),
              variant: QeranButtonVariant.primaryWine,
              loading: saving,
              onPressed:
                  (!_canSave || state.isBusy) ? null : () => _save(cubit),
            ),
          ),
        );
      },
    );
  }
}
