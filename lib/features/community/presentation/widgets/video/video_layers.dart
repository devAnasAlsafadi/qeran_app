import 'package:flutter/material.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// The shade over a video that is loading, has ended or has failed (A10,
/// A13, A14).
class VideoDim extends StatelessWidget {
  const VideoDim({super.key});

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: QeranColors.overlayTintDark);
}

/// The wine gradient over the lower part of the frame, under the length
/// and the controls.
class VideoBottomGradient extends StatelessWidget {
  const VideoBottomGradient({super.key});

  /// The share of the frame, from the bottom, it covers.
  static const double share = 0.55;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: share,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QeranColors.wine.withValues(alpha: 0),
                QeranColors.wine60,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gold disc in the middle: play (A9, A12), or replay once it ended
/// (A13).
class VideoPlayDisc extends StatelessWidget {
  const VideoPlayDisc({super.key, required this.onTap, this.replay = false});

  final VoidCallback? onTap;
  final bool replay;

  static const double size = 60;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          (replay
                  ? LocaleKeys.community_video_replay
                  : LocaleKeys.community_video_play)
              .t(context),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: QeranColors.gold,
            shape: BoxShape.circle,
            boxShadow: QeranShadows.e3,
          ),
          child: Icon(
            replay ? Icons.replay_rounded : Icons.play_arrow_rounded,
            size: 34,
            color: QeranColors.wine,
          ),
        ),
      ),
    );
  }
}

/// Waiting for the video (A10): a dark disc with the gold loader.
class VideoBufferingDisc extends StatelessWidget {
  const VideoBufferingDisc({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VideoPlayDisc.size,
      height: VideoPlayDisc.size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: QeranColors.overlayTintDark,
        shape: BoxShape.circle,
      ),
      child: const QeranLoader(
        size: 30,
        primary: QeranColors.gold,
        accent: QeranColors.gold,
      ),
    );
  }
}

/// It couldn't play (A14): why, and a retry.
class VideoFailed extends StatelessWidget {
  const VideoFailed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_rounded, size: 30, color: QeranColors.gold),
          QeranSpacing.vs4,
          Text(
            LocaleKeys.community_video_failed.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.label.copyWith(color: QeranColors.paper),
          ),
          QeranSpacing.vs8,
          QeranButton(
            label: LocaleKeys.community_retry
                .forReader(her: LocaleKeys.community_her_retry)
                .t(context),
            onPressed: onRetry,
            variant: QeranButtonVariant.primaryGold,
            size: QeranButtonSize.compact,
            leadingIcon: Icons.refresh_rounded,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
