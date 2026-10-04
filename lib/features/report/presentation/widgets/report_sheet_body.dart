import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_sheet_handle.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/report_reason.dart';
import '../blocs/report_cubit.dart';
import '../blocs/report_state.dart';
import 'report_reason_row.dart';

/// The report sheet's content: the title, the reasons, an optional note,
/// and Send / Cancel. Closes itself on success.
class ReportSheetBody extends StatefulWidget {
  const ReportSheetBody({super.key, this.targetUserId, this.targetContentId});

  final String? targetUserId;
  final String? targetContentId;

  @override
  State<ReportSheetBody> createState() => _ReportSheetBodyState();
}

class _ReportSheetBodyState extends State<ReportSheetBody> {
  final TextEditingController _note = TextEditingController();
  ReportReason? _selected;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(BuildContext c, ReportReason r) => switch (r) {
    ReportReason.inappropriateContent =>
      LocaleKeys.report_reason_inappropriate.t(c),
    ReportReason.impersonation => LocaleKeys.report_reason_impersonation.t(c),
    ReportReason.harassment => LocaleKeys.report_reason_harassment.t(c),
    ReportReason.scam => LocaleKeys.report_reason_scam.t(c),
    ReportReason.falseInformation =>
      LocaleKeys.report_reason_false_information.t(c),
    ReportReason.other => LocaleKeys.report_reason_other.t(c),
  };

  void _onOutcome(BuildContext context, ReportState state) {
    if (!context.mounted) return;
    switch (state.outcome) {
      case ReportOutcome.success:
        Navigator.of(context).pop();
        AppSnackBar.showOnRoot(
          message: (state.messageKey ?? LocaleKeys.report_success).t(context),
          type: SnackBarType.success,
        );
      case ReportOutcome.failure:
        AppSnackBar.show(
          context,
          message: (state.messageKey ?? LocaleKeys.errors_generic).t(context),
          type: SnackBarType.error,
        );
      case ReportOutcome.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportCubit, ReportState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion && c.outcome != ReportOutcome.none,
      listener: _onOutcome,
      builder: (context, state) => PopScope(
        canPop: !state.submitting,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s12,
            QeranSpacing.s20,
            QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(child: _content(context, state)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ReportState state) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Center(child: QeranSheetHandle()),
      QeranSpacing.vs16,
      _title(context),
      QeranSpacing.vs8,
      Text(
        LocaleKeys.report_prompt.t(context),
        style: QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
      ),
      QeranSpacing.vs12,
      ..._reasons(context, state),
      QeranSpacing.vs16,
      _noteField(context, state),
      QeranSpacing.vs12,
      ..._actions(context, state),
    ],
  );

  Iterable<Widget> _reasons(BuildContext context, ReportState state) =>
      ReportReason.values.map(
        (r) => ReportReasonRow(
          label: _label(context, r),
          selected: _selected == r,
          onTap: state.submitting ? null : () => setState(() => _selected = r),
        ),
      );

  Widget _noteField(BuildContext context, ReportState state) => QeranTextField(
    controller: _note,
    label: LocaleKeys.report_note_label.t(context),
    hint: LocaleKeys.report_note_hint.t(context),
    maxLines: 3,
    maxLength: 500,
    enabled: !state.submitting,
  );

  Widget _title(BuildContext context) => Row(
    children: [
      const Icon(Icons.flag_outlined, color: QeranColors.danger, size: 24),
      QeranSpacing.hs8,
      Expanded(
        child: Text(
          LocaleKeys.report_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.wine),
        ),
      ),
    ],
  );

  /// Send, once a reason is chosen, then Cancel.
  List<Widget> _actions(BuildContext context, ReportState state) => [
    QeranButton(
      label: LocaleKeys.report_submit.t(context),
      variant: QeranButtonVariant.primary,
      loading: state.submitting,
      onPressed: (_selected == null || state.submitting)
          ? null
          : () => context.read<ReportCubit>().submit(
              targetUserId: widget.targetUserId,
              targetContentId: widget.targetContentId,
              reason: _selected!,
              note: _note.text,
            ),
    ),
    QeranSpacing.vs8,
    QeranButton(
      label: LocaleKeys.common_cancel.t(context),
      variant: QeranButtonVariant.ghost,
      onPressed: state.submitting ? null : () => Navigator.of(context).pop(),
    ),
  ];
}
