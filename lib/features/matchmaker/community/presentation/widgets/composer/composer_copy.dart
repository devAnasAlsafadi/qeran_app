import 'package:flutter/widgets.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';

import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../generated/locale_keys.g.dart';
import '../../../../../community/presentation/formatting/video_duration.dart';

/// Config's image types as she reads them: «JPG أو PNG» / "JPG or PNG".
/// JPEG is JPG's other name, so it isn't listed twice. Config silent: the
/// types the app itself sends.
String imageTypesText(BuildContext context, List<String> types) => _typesText(
  context,
  types.isEmpty ? [for (final f in ImageFormat.values) f.extension] : types,
  drop: types.contains('jpg') ? 'jpeg' : null,
);

/// Config's video types, the same way: «MP4 أو MOV».
String videoTypesText(BuildContext context, List<String> types) => _typesText(
  context,
  types.isEmpty ? [for (final c in VideoContainer.values) c.extension] : types,
);

String _typesText(BuildContext context, List<String> types, {String? drop}) {
  final list = {
    for (final t in types.where((t) => t != drop)) t.toUpperCase(),
  }.toList();
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

/// [seconds] as a player writes it: «1:24», "0:52".
String secondsText(int seconds) =>
    formatVideoDuration(Duration(seconds: seconds));

/// A video limit as the sheet says it (BA-A8, Q16): whole minutes in B1
/// forms («دقيقة واحدة / دقيقتان / {n} دقائق / {n} دقيقة»), otherwise m:ss.
String durationLimitText(BuildContext context, int seconds) =>
    seconds % 60 == 0 && seconds > 0
    ? LocaleKeys.matchmaker_community_minutes.tPlural(context, seconds ~/ 60)
    : secondsText(seconds);
