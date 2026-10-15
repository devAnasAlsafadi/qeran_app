import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/keyed_server_exception.dart';
import 'package:qeran/core/utils/server_datetime.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../likes/data/error_codes.dart';
import '../../domain/entities/like_outcome.dart';
import '../discovery_search_body.dart';
import '../models/discovery_filter_question_model.dart';
import '../models/discovery_page_model.dart';

abstract interface class DiscoveryRemoteDataSource {
  /// `POST /api/Discovery/search`. [filterParams] is the flat map produced by
  /// `DiscoveryFilterCubit.buildPayload()` — keys like `RangeFrom[5]`,
  /// `RangeTo[5]`, `QuestionFilters[18]` — which [discoverySearchBody] turns
  /// into the body's dictionaries.
  Future<DiscoveryPageModel> fetchPage({
    int page,
    int pageSize,
    Map<String, String>? filterParams,
  });

  /// `GET /api/discovery/filters` — returns the dashboard-controlled list
  /// of filter questions the user can apply. Pure read; no parameters.
  Future<List<DiscoveryFilterQuestionModel>> fetchFilters();

  /// `POST /api/likes/{targetUserId}` — Bearer JWT, no body, raw
  /// `{success, message, data}` envelope.
  ///
  /// Returns a typed [LikeOutcome] for both the success path
  /// ([LikeAccepted]) and the four known semantic failure messages
  /// ([LikePaywall], [LikeAlreadyPending], [LikeGenderMismatch],
  /// [LikeUserUnavailable]). Unknown server messages or transport
  /// errors throw `ServerException` — the repository converts them to
  /// `Left(Failure)`.
  Future<LikeOutcome> likeProfile(String targetUserId);

  /// `POST /api/discovery/skip/{targetUserId}` — Bearer JWT, no body.
  /// Permanent server-side skip. Throws `ServerException` on
  /// transport-level failure; the repository converts to
  /// `Left(Failure)`.
  Future<void> skipProfile(String targetUserId);

  /// `POST /api/Discovery/skip/reset` — Bearer JWT, no body. Restores every
  /// profile this user skipped.
  ///
  /// Returns how many were put back. **Zero is a success**, not a failure: it
  /// means the user had skipped nobody, and the caller has to be able to tell
  /// that apart from an error so the UI can say so instead of silently
  /// reloading an unchanged deck.
  ///
  /// Throws `ServerException` on a failed envelope; the repository converts it
  /// to `Left(Failure)`.
  Future<int> resetSkippedProfiles();
}

class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const DiscoveryRemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _apiConsumer = apiConsumer;

  @override
  Future<DiscoveryPageModel> fetchPage({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async {
    AppLogger.debug(
      'FETCH DISCOVERY -> page=$page pageSize=$pageSize '
      'filters=${filterParams?.length ?? 0}',
      tag: 'DISCOVERY',
    );

    // Uses `postRaw` (not `post`) so a coded failure envelope is returned
    // rather than thrown before we can read it: the no-subscription daily-view
    // cap arrives as `{status:0, errorCode:DAILY_VIEWS_EXCEEDED,
    // data:{resetAt}}`, and we must surface `resetAt` for the "come back
    // tomorrow" countdown.
    try {
      final body = await _apiConsumer.postRaw(
        EndPoints.discoverySearch,
        body: discoverySearchBody(
          page: page,
          pageSize: pageSize,
          filters: filterParams,
        ),
      );
      if (body is! Map<String, dynamic>) {
        throw ServerException(message: LocaleKeys.errors_generic);
      }

      final ok = body['status'] == 1 || body['status'] == true;
      if (!ok) {
        final errorCode = body['errorCode'] as String?;
        if (errorCode == DiscoveryErrorCodes.dailyViewsExceeded) {
          throw DailyViewsExceededException(resetAt: _resetAtFrom(body));
        }
        throw keyedServerException(
          CodedServerException(
            message: body['message'] as String? ?? '',
            errorCode: errorCode,
          ),
          label: 'DISCOVERY',
          tag: 'DISCOVERY',
        );
      }

      final apiResponse = ApiResponse<DiscoveryPageModel>.fromJson(
        body,
        (json) => DiscoveryPageModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data == null) {
        throw ServerException(message: LocaleKeys.errors_generic);
      }

      AppLogger.info(
        'Discovery page ${apiResponse.data!.pageNumber}/'
        '${apiResponse.data!.totalPages} — '
        '${apiResponse.data!.profiles.length} profile(s)',
        tag: 'DISCOVERY',
      );

      return apiResponse.data!;
    } on DailyViewsExceededException {
      rethrow;
    } on CodedServerException catch (e) {
      // The cap can also arrive as a non-2xx response — `getRaw` throws before
      // we can read `data.resetAt`, so fall back to the next UTC midnight,
      // which is exactly what this cap's `resetAt` denotes.
      if (e.errorCode == DiscoveryErrorCodes.dailyViewsExceeded) {
        throw DailyViewsExceededException(resetAt: _nextUtcMidnight());
      }
      throw keyedServerException(e, label: 'DISCOVERY', tag: 'DISCOVERY');
    }
  }

  /// Parses `data.resetAt` from the daily-cap envelope; falls back to the next
  /// UTC midnight (what this cap's `resetAt` denotes) when absent/unparseable.
  DateTime _resetAtFrom(Map<String, dynamic> body) {
    final data = body['data'];
    final raw = data is Map<String, dynamic> ? data['resetAt'] : null;
    return parseServerDateTime(raw) ?? _nextUtcMidnight();
  }

  DateTime _nextUtcMidnight() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }

  @override
  Future<List<DiscoveryFilterQuestionModel>> fetchFilters() async {
    AppLogger.debug('FETCH DISCOVERY FILTERS', tag: 'DISCOVERY');

    final response = await _apiConsumer.get(EndPoints.discoveryFilters);

    final apiResponse =
        ApiResponse<List<DiscoveryFilterQuestionModel>>.fromJson(
          response,
          (json) => (json as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(DiscoveryFilterQuestionModel.fromJson)
              .toList(),
        );

    if (apiResponse.data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_generic,
      );
    }

    AppLogger.info(
      'Discovery filters — ${apiResponse.data!.length} question(s)',
      tag: 'DISCOVERY',
    );

    return apiResponse.data!;
  }

  @override
  Future<LikeOutcome> likeProfile(String targetUserId) async {
    AppLogger.debug('LIKE profileId=$targetUserId', tag: 'DISCOVERY');
    try {
      final body = await _apiConsumer.postRaw(
        EndPoints.likeProfile(targetUserId),
      );
      if (body is! Map<String, dynamic>) {
        throw ServerException(message: LocaleKeys.errors_generic);
      }
      // A gated/rejected like can arrive as a 200 `{status: 0, errorCode}`
      // envelope — the raw handler does NOT throw on `status: 0` (see
      // http_consumer), so classify it here instead of mis-reading it as an
      // accepted like. Only an explicit failure marker flips this; a plain
      // success Map ({success:true} or {status:1}) stays accepted.
      final errorCode = body['errorCode'] as String?;
      final isRejected =
          body['status'] == 0 || (errorCode != null && errorCode.isNotEmpty);
      if (isRejected) {
        final message = body['message'] as String? ?? LocaleKeys.errors_generic;
        final outcome = _classifyLikeFailure(message, errorCode: errorCode);
        if (outcome != null) {
          AppLogger.warning(
            'Like rejected (status:0) — ${outcome.runtimeType} '
            'target=$targetUserId code="$errorCode"',
            tag: 'DISCOVERY',
          );
          return outcome;
        }
        throw CodedServerException(message: message, errorCode: errorCode);
      }
      // The success envelope is `{success: true, message, data: "42"}`
      // where `data` is the like row id as a string. Some servers may
      // return it as a number — accept both.
      final data = body['data'];
      final likeId = switch (data) {
        String s when s.isNotEmpty => s,
        num n => n.toString(),
        _ => '',
      };
      AppLogger.info(
        'Like accepted — id=$likeId target=$targetUserId',
        tag: 'DISCOVERY',
      );
      return LikeAccepted(likeId: likeId);
    } on ServerException catch (e) {
      // `postRaw` throws `CodedServerException` (non-2xx, or a 2xx
      // `{success: false}`) carrying the stable `errorCode`. Classify by
      // that code; an unknown or missing one leaves as the generic key (the
      // code kept), so the repository converts it to `Left(Failure)`.
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classifyLikeFailure(e.message, errorCode: code);
      if (outcome != null) {
        AppLogger.warning(
          'Like rejected — ${outcome.runtimeType} target=$targetUserId '
          'message="${e.message}"',
          tag: 'DISCOVERY',
        );
        return outcome;
      }
      AppLogger.warning(
        'Like failed (unmapped) target=$targetUserId message="${e.message}"',
        tag: 'DISCOVERY',
      );
      throw keyedServerException(e, label: 'LIKE', tag: 'DISCOVERY');
    }
  }

  @override
  Future<void> skipProfile(String targetUserId) async {
    AppLogger.debug('SKIP profileId=$targetUserId', tag: 'DISCOVERY');
    await _apiConsumer.postRaw(EndPoints.discoverySkip(targetUserId));
    AppLogger.info('Skip recorded target=$targetUserId', tag: 'DISCOVERY');
  }

  @override
  Future<int> resetSkippedProfiles() async {
    AppLogger.debug('RESET SKIPPED PROFILES', tag: 'DISCOVERY');
    // `post`, not the `postRaw` its sibling skip uses: this one has a count to
    // read, and `post` enforces `status == 1` so anything reaching the next
    // line is a success envelope.
    final body = await _apiConsumer.post(EndPoints.discoverySkipReset);
    final restored = _restoredCount(body);
    AppLogger.info('Skip reset restored=$restored', tag: 'DISCOVERY');
    return restored;
  }

  /// Reads `data` as a count of restored profiles.
  ///
  /// Anything unreadable — a missing field, a string, a negative — degrades to
  /// `0` rather than throwing. The reset has ALREADY happened server-side by
  /// the time this runs, so throwing here would report a completed mutation as
  /// a failure and invite the user to fire it again.
  int _restoredCount(dynamic body) {
    if (body is! Map) return 0;
    final raw = body['data'];
    final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    return (value == null || value < 0) ? 0 : value;
  }

  /// Maps a gated like failure onto a typed [LikeOutcome] by its
  /// [errorCode]. A missing or unrecognised code returns `null`, and the
  /// caller throws the generic key. The message is never parsed: every like
  /// error carries its code (Tariq), and release day rewords the messages an
  /// old Arabic substring match relied on (H2, D19).
  LikeOutcome? _classifyLikeFailure(String rawMessage, {String? errorCode}) =>
      switch (errorCode) {
        LikesErrorCodes.subscriptionRequired ||
        LikesErrorCodes.likesQuotaExceeded ||
        LikesErrorCodes.likesFreeQuotaExceeded => LikePaywall(
          serverMessage: rawMessage,
        ),
        LikesErrorCodes.likeAlreadyExists => LikeAlreadyPending(
          serverMessage: rawMessage,
        ),
        LikesErrorCodes.sameGenderNotAllowed => LikeGenderMismatch(
          serverMessage: rawMessage,
        ),
        LikesErrorCodes.targetUserNotFound || LikesErrorCodes.likeNotFound =>
          LikeUserUnavailable(serverMessage: rawMessage),
        LikesErrorCodes.profileNotApproved => LikeUnderReview(
          serverMessage: rawMessage,
        ),
        _ => null,
      };
}
