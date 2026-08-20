import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';

import '../../domain/entities/badge_counts.dart';
import '../models/badge_counts_model.dart';

abstract class BadgesRemoteDataSource {
  /// `GET /api/badges`. Never throws on a 404 — see the impl.
  Future<BadgeCounts> getBadges();

  /// `POST /api/badges/mark-seen` with `{ "tab": tabKey }`.
  Future<void> markTabSeen(String tabKey);
}

class BadgesRemoteDataSourceImpl implements BadgesRemoteDataSource {
  BadgesRemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _apiConsumer = apiConsumer;

  final ApiConsumer _apiConsumer;

  /// `getRaw`, not `get`: the payload is a bare dict with no `status` envelope
  /// to enforce, and the raw handler is the one that preserves the transport
  /// status — which the 404 branch below depends on.
  ///
  /// A 404 means the route is not deployed yet, which is not an error the user
  /// should ever see. It reads as "no badges", exactly like an empty dict. Any
  /// other failure still throws: a 500 or an expired token is a real fault and
  /// silently showing zero badges would hide it.
  @override
  Future<BadgeCounts> getBadges() async {
    try {
      final body = await _apiConsumer.getRaw(EndPoints.badges);
      return BadgeCountsModel.fromJson(body);
    } on CodedServerException catch (e) {
      if (e.statusCode == 404) return const BadgeCounts.empty();
      rethrow;
    }
  }

  /// Fire-and-forget by design at the caller, but failures still propagate so
  /// the repository can log them. The next `getBadges` is the correction: the
  /// server stays the authority on what is unread.
  @override
  Future<void> markTabSeen(String tabKey) async {
    await _apiConsumer.postRaw(EndPoints.badgesMarkSeen, body: {'tab': tabKey});
  }
}
