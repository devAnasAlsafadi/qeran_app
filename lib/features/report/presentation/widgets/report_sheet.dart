import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../blocs/report_cubit.dart';
import 'report_sheet_body.dart';

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
      child: ReportSheetBody(
        targetUserId: targetUserId,
        targetContentId: targetContentId,
      ),
    ),
  );
}
