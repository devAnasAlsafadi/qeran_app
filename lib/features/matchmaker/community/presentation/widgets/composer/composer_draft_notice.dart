import 'package:flutter/material.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';

import '../../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../../core/design_system/widgets/qeran_notice.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../blocs/composer/post_draft_state.dart';

/// Why her last pick didn't all go in: C8 in gold, C10 and Q3 in danger.
/// Every number and type comes from config (W1), counted in B1 forms.
class ComposerDraftNotice extends StatelessWidget {
  const ComposerDraftNotice({
    super.key,
    required this.notice,
    required this.imageTypes,
  });

  final DraftNotice notice;

  /// Config's `allowedImageTypes`; empty when it didn't say.
  final List<String> imageTypes;

  static const _padding = EdgeInsets.fromLTRB(
    QeranSpacing.s20,
    0,
    QeranSpacing.s20,
    QeranSpacing.s12,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: _padding,
    child: switch (notice) {
      TooManyImages(:final added, :final picked, :final limit) => QeranNotice(
        icon: Icons.info_rounded,
        text: _tooMany(context, added, picked, limit),
      ),
      UnsupportedFile() => _danger(
        LocaleKeys.matchmaker_community_unsupported_images.t(
          context,
          namedArgs: {'types': fileTypesText(context, imageTypes)},
        ),
      ),
      ImageTooLarge(:final sizeBytes, :final maxBytes) => _danger(
        LocaleKeys.matchmaker_community_image_too_large.t(
          context,
          namedArgs: {
            'size': megabytesText(context, sizeBytes),
            'max': megabytesText(context, maxBytes),
          },
        ),
      ),
    },
  );

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

  QeranNotice _danger(String text) => QeranNotice(
    icon: Icons.block_rounded,
    tone: QeranNoticeTone.danger,
    text: text,
  );
}

/// Config's types as she reads them: «JPG أو PNG» / "JPG or PNG". JPEG is
/// JPG's other name, so it isn't listed twice. Config silent: the types the
/// app itself sends.
String fileTypesText(BuildContext context, List<String> types) {
  final names =
      (types.isEmpty
              ? [for (final format in ImageFormat.values) format.extension]
              : types)
          .map((t) => t.toUpperCase())
          .toSet()
        ..removeWhere((t) => t == 'JPEG' && types.contains('jpg'));
  final list = names.toList();
  if (list.length < 2) return list.join();
  final separator = LocaleKeys.matchmaker_community_types_separator.t(context);
  final last = LocaleKeys.matchmaker_community_types_last_separator.t(context);
  return '${list.sublist(0, list.length - 1).join(separator)}$last${list.last}';
}

/// [bytes] in MB, one decimal at most: «5 ميغابايت», "5.2 MB".
String megabytesText(BuildContext context, int bytes) {
  final fixed = (bytes / (1024 * 1024)).toStringAsFixed(1);
  final n = fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  return LocaleKeys.matchmaker_community_megabytes.t(
    context,
    namedArgs: {'n': n},
  );
}
