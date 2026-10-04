import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/di/injection_container.dart';

import '../../domain/entities/report_target.dart';
import '../blocs/report_cubit.dart';
import 'report_sheet_body.dart';

/// Opens the report sheet for [target] — a profile, or a post, comment or
/// reply. On success the sheet closes and a confirmation toast shows on the
/// root (survives the pop); content that's gone closes it with a notice.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider<ReportCubit>(
      create: (_) => sl<ReportCubit>(param1: target),
      child: ReportSheetBody(target: target),
    ),
  );
}

/// The sheet for a member's profile.
Future<void> showUserReportSheet(BuildContext context, String userId) =>
    showReportSheet(context, target: UserReportTarget(userId));
