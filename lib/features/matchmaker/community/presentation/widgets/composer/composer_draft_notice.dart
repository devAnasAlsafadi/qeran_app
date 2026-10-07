import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_state.dart';
import 'composer_copy.dart';

/// Why her last pick didn't all go in: C8 in gold; C10, Q3 and BA-A9 in
/// danger. Every number and type comes from config (W1), counted in B1
/// forms.
class ComposerDraftNotice extends StatelessWidget {
  const ComposerDraftNotice({super.key, required this.draft});

  final PostDraftState draft;

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s20,
    0,
    QeranSpacing.s20,
    QeranSpacing.s12,
  );

  @override
  Widget build(BuildContext context) =>
      Padding(padding: _padding, child: _notice(context, draft.notice!));

  Widget _notice(BuildContext context, DraftNotice notice) => switch (notice) {
    TooManyImages(:final added, :final picked, :final limit) => QeranNotice(
      icon: Icons.info_rounded,
      text: _tooMany(context, added, picked, limit),
    ),
    UnsupportedFile() => _danger(Icons.block_rounded, _unsupported(context)),
    ImageTooLarge(:final sizeBytes, :final maxBytes) => _tooLarge(
      context,
      LocaleKeys.matchmaker_community_image_too_large,
      sizeBytes,
      maxBytes,
    ),
    VideoTooLarge(:final sizeBytes, :final maxBytes) => _tooLarge(
      context,
      LocaleKeys.matchmaker_community_video_too_large,
      sizeBytes,
      maxBytes,
    ),
    VideoTooLong(:final seconds, :final maxSeconds) => _tooLong(
      context,
      seconds,
      maxSeconds,
    ),
  };

  /// Q3: both sizes in MB.
  static QeranNotice _tooLarge(
    BuildContext context,
    String key,
    int sizeBytes,
    int maxBytes,
  ) => _danger(
    Icons.block_rounded,
    key.t(
      context,
      namedArgs: {
        'size': megabytesText(context, sizeBytes),
        'max': megabytesText(context, maxBytes),
      },
    ),
  );

  /// BA-A9: both lengths in m:ss.
  static QeranNotice _tooLong(BuildContext context, int seconds, int max) =>
      _danger(
        Icons.timer_off_rounded,
        LocaleKeys.matchmaker_community_video_too_long.t(
          context,
          namedArgs: {'d': secondsText(seconds), 'max': secondsText(max)},
        ),
      );

  /// C10 names both lists once video is offered; images only until then.
  String _unsupported(BuildContext context) {
    final config = draft.config;
    final images = imageTypesText(context, config?.allowedImageTypes ?? []);
    if (!draft.videoOffered) {
      return LocaleKeys.matchmaker_community_unsupported_images.t(
        context,
        namedArgs: {'types': images},
      );
    }
    final videos = videoTypesText(context, config?.allowedVideoTypes ?? []);
    return LocaleKeys.matchmaker_community_unsupported_media.t(
      context,
      namedArgs: {'images': images, 'videos': videos},
    );
  }

  /// C8: «أُضيفت أول {n} صور من {m} اخترتِها. الحد الأقصى {n} صور…».
  String _tooMany(BuildContext context, int added, int picked, int limit) {
    final first = LocaleKeys.matchmaker_community_too_many_added.tPlural(
      context,
      added,
      namedArgs: {'m': '$picked'},
    );
    final max = LocaleKeys.matchmaker_community_too_many_limit.tPlural(
      context,
      limit,
    );
    return '$first $max';
  }

  static QeranNotice _danger(IconData icon, String text) =>
      QeranNotice(icon: icon, tone: QeranNoticeTone.danger, text: text);
}
