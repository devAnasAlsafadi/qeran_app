import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';

/// The strip under the composer's header when publishing didn't get through
/// (D3): «تعذّر رفع المنشور. تحقّقي من اتصالك.» and «إعادة المحاولة». The
/// draft stays as it was.
class PublishStrip extends StatelessWidget {
  const PublishStrip({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s16,
        QeranSpacing.s6,
        QeranSpacing.s6,
        QeranSpacing.s6,
      ),
      decoration: const BoxDecoration(
        color: QeranColors.danger08,
        border: Border(bottom: BorderSide(color: QeranColors.danger40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, size: 22, color: QeranColors.danger),
          const SizedBox(width: QeranSpacing.s12),
          Expanded(
            child: Text(
              LocaleKeys.matchmaker_community_upload_failed.t(context),
              style: QeranTypography.label.copyWith(color: QeranColors.danger),
            ),
          ),
          _Retry(onTap: onRetry),
        ],
      ),
    );
  }
}

/// «إعادة المحاولة» in the strip's own danger, a 48 pt target.
class _Retry extends StatelessWidget {
  const _Retry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s12),
          child: Center(
            widthFactor: 1,
            child: Text(
              LocaleKeys.matchmaker_community_retry.t(context),
              style: QeranTypography.label.copyWith(color: QeranColors.danger),
            ),
          ),
        ),
      ),
    );
  }
}
