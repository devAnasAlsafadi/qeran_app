import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../../../shared/data/matchmaker_envelope.dart';
import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import '../../domain/entities/matchmaker_interest_page.dart';
import '../../domain/entities/matchmaker_like_activity.dart';
import '../models/matchmaker_interest_archive_item_model.dart';
import '../models/matchmaker_interest_match_model.dart';
import '../models/matchmaker_interest_user_model.dart';
import '../models/matchmaker_like_activity_model.dart';

abstract interface class MatchmakerInterestsRemoteDataSource {
  Future<MatchmakerInterestPage<MatchmakerLikeActivity>> getLikes(
    String userId,
    MatchmakerLikeDirection direction,
  );
  Future<MatchmakerInterestPage<List<MatchmakerInterestMatch>>> getMatches(
    String userId,
  );
  Future<MatchmakerInterestPage<List<MatchmakerInterestArchiveItem>>>
  getArchivedMatches(String userId);
}

class MatchmakerInterestsRemoteDataSourceImpl
    implements MatchmakerInterestsRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerInterestsRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerInterestPage<MatchmakerLikeActivity>> getLikes(
    String userId,
    MatchmakerLikeDirection direction,
  ) {
    final path = direction == MatchmakerLikeDirection.outgoing
        ? EndPoints.matchmakerUserLikesOutgoing(userId)
        : EndPoints.matchmakerUserLikesIncoming(userId);
    return _page(path, 'likes-${direction.name}', (data) {
      final activity = MatchmakerLikeActivityModel.fromJson(
        parseNullableMap(data) ?? const {},
      ).toEntity();
      // The one matchmaker endpoint carrying both `expiresAt` and the
      // server's `remainingSeconds` snapshot — so it is where this app learns
      // the clock offset that the compatibility-case countdowns then ride on
      // (that payload has no snapshot of its own). See [ServerClock].
      ServerClock.instance.calibrateFromAny([
        for (final like in activity.pending)
          (expiresAt: like.expiresAt, remainingSeconds: like.remainingSeconds),
      ]);
      return activity;
    });
  }

  @override
  Future<MatchmakerInterestPage<List<MatchmakerInterestMatch>>> getMatches(
    String userId,
  ) {
    return _page(EndPoints.matchmakerUserMatches(userId), 'matches', (data) {
      final matches = parseMapList(data)
          .map((m) => MatchmakerInterestMatchModel.fromJson(m).toEntity())
          .toList(growable: false);
      // A photo-exchange block that sends both halves calibrates the clock the
      // same way the likes rows do — this tab can be the first one opened.
      ServerClock.instance.calibrateFromAny([
        for (final m in matches)
          if (m.pendingPhotoExchange case final p?)
            (expiresAt: p.expiresAt, remainingSeconds: p.remainingSeconds),
      ]);
      return matches;
    });
  }

  @override
  Future<MatchmakerInterestPage<List<MatchmakerInterestArchiveItem>>>
  getArchivedMatches(String userId) {
    return _page(
      EndPoints.matchmakerUserMatchesArchived(userId),
      'matches-archived',
      (data) => parseMapList(data)
          .map((m) => MatchmakerInterestArchiveItemModel.fromJson(m).toEntity())
          .toList(growable: false),
    );
  }

  /// Shared GET → unwrap envelope → parse the `{user, data}` page. `get()`
  /// enforced the outer status==1 envelope; the inner page may be single- or
  /// double-wrapped (unwrapInnerEnvelope tolerates both). [parseData] turns the
  /// page's `data` field into the tab payload.
  Future<MatchmakerInterestPage<T>> _page<T>(
    String path,
    String tag,
    T Function(Object? data) parseData,
  ) async {
    AppLogger.debug('MATCHMAKER — interests $tag', tag: 'MATCHMAKER');
    final response = await _apiConsumer.get(path);
    final pageJson = unwrapInnerEnvelope(
      (response as Map<String, dynamic>)['data'],
    );
    if (pageJson == null) {
      AppLogger.error(
        'MATCHMAKER — interests $tag ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    final user = MatchmakerInterestUserModel.fromJson(
      parseNullableMap(pageJson['user']) ?? const {},
    ).toEntity();
    return MatchmakerInterestPage(
      user: user,
      data: parseData(pageJson['data']),
    );
  }
}
