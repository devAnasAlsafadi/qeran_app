import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Shown inside a filter sheet when `/filters` came back with no usable
/// questions at all — the load succeeded, there is simply nothing to filter on.
///
/// Deliberately lighter than [QeranEmptyState]: this sits inside a bottom sheet
/// that already has a title and footer, so an icon disc and headline would
/// out-shout the chrome around it.
class QeranFilterFacetsEmpty extends StatelessWidget {
  const QeranFilterFacetsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(QeranSpacing.s32),
      child: Center(
        child: Text(
          LocaleKeys.filters_none_available.t(context),
          textAlign: TextAlign.center,
          style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
        ),
      ),
    );
  }
}
