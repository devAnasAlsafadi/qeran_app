import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/compatibility_case_update.dart';
import '../json_parsers.dart';
import '../models/compatibility_case_update_model.dart';

/// Pure payload parsing for matchmaker SignalR events. Extracted from the
/// service so it can be unit-tested without a live hub: the transport
/// hands us `List<Object?>?`; these helpers return a validated entity or
/// `null` on a malformed payload. Never throws.
class MatchmakerRealtimeEventParser {
  MatchmakerRealtimeEventParser._();

  /// Parses a `CompatibilityCaseUpdated` payload, or returns `null` if
  /// the wire shape is unexpected.
  static CompatibilityCaseUpdate? parseCaseUpdated(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) {
      AppLogger.warning(
        'MM-RT — CompatibilityCaseUpdated: missing or malformed args',
        tag: 'MM-RT',
      );
      return null;
    }
    try {
      return CompatibilityCaseUpdateModel.fromJson(map);
    } catch (e) {
      AppLogger.error(
        'MM-RT — CompatibilityCaseUpdated parse failed: $e',
        error: e,
        tag: 'MM-RT',
      );
      return null;
    }
  }

  /// Coerces `args[0]` into `Map<String, dynamic>` (SignalR may hand us a
  /// `Map<dynamic, dynamic>` depending on the JSON impl); `null` if it
  /// isn't a map.
  static Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    return parseNullableMap(args.first);
  }
}
