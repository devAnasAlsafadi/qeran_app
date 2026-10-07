import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../../core/design_system/widgets/qeran_progress_bar.dart';
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
    return _Strip(
      ground: QeranColors.danger08,
      edge: QeranColors.danger40,
      leading: const Icon(
        Icons.error_rounded,
        size: 22,
        color: QeranColors.danger,
      ),
      body: Text(
        LocaleKeys.matchmaker_community_upload_failed.t(context),
        style: QeranTypography.label.copyWith(color: QeranColors.danger),
      ),
      action: _StripAction(
        label: LocaleKeys.matchmaker_community_retry.t(context),
        color: QeranColors.danger,
        onTap: onRetry,
      ),
    );
  }
}

/// Her media going up (D2): «جارٍ رفع المنشور… {p}٪» over the bar, and
/// «إلغاء» while it can still stop ([onCancel] null once the post is being
/// made).
class UploadStrip extends StatelessWidget {
  const UploadStrip({super.key, required this.progress, this.onCancel});

  final double progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return _Strip(
      ground: QeranColors.creamSurface,
      edge: QeranColors.gold40,
      leading: const QeranLoader(size: 22),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.matchmaker_community_uploading.t(
              context,
              namedArgs: {'p': '$percent'},
            ),
            style: QeranTypography.label.copyWith(color: QeranColors.inkStrong),
          ),
          const SizedBox(height: QeranSpacing.s6),
          QeranProgressBar(value: progress),
        ],
      ),
      action: onCancel == null
          ? const SizedBox(width: QeranSpacing.s12)
          : _StripAction(
              label: LocaleKeys.matchmaker_community_cancel.t(context),
              color: QeranColors.wine80,
              onTap: onCancel!,
            ),
    );
  }
}

/// The strip's frame: 60 high at least, its ground and bottom edge, then
/// the leading mark, the body and the action.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.ground,
    required this.edge,
    required this.leading,
    required this.body,
    required this.action,
  });

  final Color ground;
  final Color edge;
  final Widget leading;
  final Widget body;
  final Widget action;

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
      decoration: BoxDecoration(
        color: ground,
        border: Border(bottom: BorderSide(color: edge)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: QeranSpacing.s12),
          Expanded(child: body),
          action,
        ],
      ),
    );
  }
}

/// The strip's action, a 48 pt target in its own colour.
class _StripAction extends StatelessWidget {
  const _StripAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
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
              label,
              style: QeranTypography.label.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
