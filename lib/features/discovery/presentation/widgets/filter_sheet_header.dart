import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Filter-sheet header: title (start edge → right in Arabic) with the
/// close button on the opposite (end) edge, and the subtitle beneath.
/// Fully direction-aware — mirrors automatically between AR and EN.
class FilterSheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const FilterSheetHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s16,
        QeranSpacing.s16,
        QeranSpacing.s16,
        QeranSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.discovery_filter_title.t(context),
                  textAlign: TextAlign.start,
                  style: QeranTypography.headline,
                ),
              ),
              _CircleCloseButton(onTap: onClose),
            ],
          ),
          QeranSpacing.vs8,
          Padding(
            padding: const EdgeInsetsDirectional.only(end: QeranSpacing.s48),
            child: Text(
              LocaleKeys.discovery_filter_subtitle.t(context),
              textAlign: TextAlign.start,
              style: QeranTypography.bodySm.copyWith(
                color: QeranColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(
        side: BorderSide(color: QeranColors.wine08),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: QeranColors.wine,
          ),
        ),
      ),
    );
  }
}
