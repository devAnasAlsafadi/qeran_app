import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_sheet_handle.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/report_reason.dart';
import '../blocs/report_cubit.dart';
import '../blocs/report_state.dart';

/// Opens the report sheet for a user and/or a piece of content. At least one of
/// [targetUserId] / [targetContentId] must be supplied. On success the sheet
/// closes and a confirmation toast shows on the root (survives the pop).
Future<void> showReportSheet(
  BuildContext context, {
  String? targetUserId,
  String? targetContentId,
}) {
  assert(
    targetUserId != null || targetContentId != null,
    'showReportSheet needs at least one target',
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider<ReportCubit>(
      create: (_) => sl<ReportCubit>(),
      child: _ReportSheet(
        targetUserId: targetUserId,
        targetContentId: targetContentId,
      ),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({this.targetUserId, this.targetContentId});

  final String? targetUserId;
  final String? targetContentId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
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
        ReportReason.impersonation =>
          LocaleKeys.report_reason_impersonation.t(c),
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
          p.eventVersion != c.eventVersion &&
          c.outcome != ReportOutcome.none,
      listener: _onOutcome,
      builder: (context, state) {
        return PopScope(
          canPop: !state.submitting,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s12,
              QeranSpacing.s20,
              QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: QeranSheetHandle()),
                  QeranSpacing.vs16,
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          color: QeranColors.danger, size: 24),
                      QeranSpacing.hs8,
                      Expanded(
                        child: Text(
                          LocaleKeys.report_title.t(context),
                          style: QeranTypography.title
                              .copyWith(color: QeranColors.wine),
                        ),
                      ),
                    ],
                  ),
                  QeranSpacing.vs8,
                  Text(
                    LocaleKeys.report_prompt.t(context),
                    style: QeranTypography.bodySm
                        .copyWith(color: QeranColors.inkMuted),
                  ),
                  QeranSpacing.vs12,
                  ...ReportReason.values.map(
                    (r) => _ReasonRow(
                      label: _label(context, r),
                      selected: _selected == r,
                      onTap: state.submitting
                          ? null
                          : () => setState(() => _selected = r),
                    ),
                  ),
                  QeranSpacing.vs16,
                  QeranTextField(
                    controller: _note,
                    label: LocaleKeys.report_note_label.t(context),
                    hint: LocaleKeys.report_note_hint.t(context),
                    maxLines: 3,
                    maxLength: 500,
                    enabled: !state.submitting,
                  ),
                  QeranSpacing.vs12,
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
                    onPressed: state.submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A DS radio row — a 20×20 circle that fills gold with a wine dot when
/// selected, leading the reason label. The whole row is tappable.
class _ReasonRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ReasonRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.xsR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: QeranMotion.fast,
              curve: QeranCurves.standard,
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? QeranColors.gold : null,
                border: selected
                    ? null
                    : Border.all(color: QeranColors.wine40, width: 1.5),
              ),
              child: selected
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: QeranColors.wine,
                      ),
                    )
                  : null,
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                label,
                style: QeranTypography.body.copyWith(
                  color: selected ? QeranColors.wine : QeranColors.inkBody,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
