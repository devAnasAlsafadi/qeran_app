import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'composer_copy.dart';
import 'composer_video_preview.dart';

/// Her video in the composer (C6): «فيديو» with «الحد الأقصى {m:ss}» from
/// config, then its preview (BA-D).
class ComposerVideo extends StatelessWidget {
  const ComposerVideo({
    super.key,
    required this.video,
    required this.maxSeconds,
    required this.onRemove,
  });

  final PickedVideo video;
  final int? maxSeconds;

  /// Null while it publishes: nothing leaves.
  final VoidCallback? onRemove;

  static const _headerPadding = EdgeInsets.fromLTRB(
    QeranSpacing.s20,
    0,
    QeranSpacing.s20,
    QeranSpacing.s8,
  );

  @override
  Widget build(BuildContext context) {
    final max = maxSeconds;
    return Padding(
      padding: const EdgeInsets.only(bottom: QeranSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: _headerPadding, child: _header(context, max)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
            child: ComposerVideoPreview(video: video, onRemove: onRemove),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, int? max) => Row(
    children: [
      Text(
        LocaleKeys.matchmaker_community_video.t(context),
        style: QeranTypography.label.copyWith(
          color: QeranColors.inkStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      if (max != null) _max(context, max),
    ],
  );

  Widget _max(BuildContext context, int max) => Text(
    LocaleKeys.matchmaker_community_max_duration.t(
      context,
      namedArgs: {'d': secondsText(max)},
    ),
    style: QeranTypography.label.copyWith(color: QeranColors.inkMuted),
  );
}
