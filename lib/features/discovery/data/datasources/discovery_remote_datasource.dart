import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/like_outcome.dart';
import '../models/discovery_filter_question_model.dart';
import '../models/discovery_page_model.dart';

abstract interface class DiscoveryRemoteDataSource {
  /// [filterParams] is the **already-flat** query map produced by
  /// `DiscoveryFilterCubit.buildPayload()` — keys like
  /// `RangeFrom[5]`, `RangeTo[5]`, `QuestionFilters[18]`. The datasource
  /// spreads them straight into the query string; it does NOT JSON-encode
  /// or otherwise transform.
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

    final qp = <String, dynamic>{
      'Page': page,
      'PageSize': pageSize,
      if (filterParams != null) ...filterParams,
    };

    final response = await _apiConsumer.get(
      EndPoints.discovery,
      queryParameters: qp,
    );

    final apiResponse = ApiResponse<DiscoveryPageModel>.fromJson(
      response,
      (json) => DiscoveryPageModel.fromJson(json as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_generic,
      );
    }

    AppLogger.info(
      'Discovery page ${apiResponse.data!.pageNumber}/'
      '${apiResponse.data!.totalPages} — '
      '${apiResponse.data!.profiles.length} profile(s)',
      tag: 'DISCOVERY',
    );

    return apiResponse.data!;
  }

  @override
  Future<List<DiscoveryFilterQuestionModel>> fetchFilters() async {
    AppLogger.debug('FETCH DISCOVERY FILTERS', tag: 'DISCOVERY');

    final response = await _apiConsumer.get(EndPoints.discoveryFilters);

    final apiResponse = ApiResponse<List<DiscoveryFilterQuestionModel>>.fromJson(
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
      // `postRaw` throws `ServerException(message: server message)` when
      // the server returns `{success: false, message: ...}`. Map the
      // four known Arabic messages onto typed outcomes; unknown ones
      // bubble up so the repository converts to `Left(Failure)`.
      final outcome = _classifyLikeFailure(e.message);
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
      rethrow;
    }
  }

  @override
  Future<void> skipProfile(String targetUserId) async {
    AppLogger.debug('SKIP profileId=$targetUserId', tag: 'DISCOVERY');
    await _apiConsumer.postRaw(EndPoints.discoverySkip(targetUserId));
    AppLogger.info('Skip recorded target=$targetUserId', tag: 'DISCOVERY');
  }

  /// Maps a server-supplied Arabic failure message onto a typed
  /// [LikeOutcome]. Returns `null` for unrecognised messages (the
  /// repository then surfaces them as a transport-level `Failure`).
  ///
  /// Substring matching is the fallback path until backend exposes a
  /// stable `errorCode` field — see the plan §9. We normalise tashkeel,
  /// tatweel, and bidi marks on both sides so future copy edits don't
  /// silently break the dispatch.
  LikeOutcome? _classifyLikeFailure(String rawMessage) {
    final m = _normaliseArabic(rawMessage);
    // Subscription / quota exhausted —
    // "لقد استنفدت عدد الإعجابات المسموح به في اشتراكك"
    if (m.contains(_normaliseArabic('استنفدت')) ||
        m.contains(_normaliseArabic('الإعجابات المسموح'))) {
      return LikePaywall(serverMessage: rawMessage);
    }
    // Already pending / accepted —
    // "يوجد طلب قائم بالفعل بينكما"
    if (m.contains(_normaliseArabic('طلب قائم'))) {
      return LikeAlreadyPending(serverMessage: rawMessage);
    }
    // Gender mismatch —
    // "لا يمكن إرسال إعجاب لشخص من نفس الجنس"
    if (m.contains(_normaliseArabic('نفس الجنس'))) {
      return LikeGenderMismatch(serverMessage: rawMessage);
    }
    // User gone or hidden —
    // "المستخدم غير موجود أو غير مرئي"
    if (m.contains(_normaliseArabic('غير موجود')) ||
        m.contains(_normaliseArabic('غير مرئي'))) {
      return LikeUserUnavailable(serverMessage: rawMessage);
    }
    return null;
  }

  /// Strips tashkeel (U+064B–U+0652), tatweel (U+0640), and bidi
  /// control marks (LRM/RLM, isolates, embeddings) and collapses
  /// whitespace. Lets `.contains` match across copy variants the
  /// backend might emit. The bidi-marks regex is assembled from code
  /// units so the source file itself contains no literal direction-
  /// override characters — the Dart analyzer flags those as a visual
  /// spoofing hazard.
  static final RegExp _tashkeelTatweel = RegExp('[ً-ْـ]');
  static final RegExp _bidiMarks = RegExp(
    '[${String.fromCharCode(0x200E)}${String.fromCharCode(0x200F)}'
    '${String.fromCharCode(0x202A)}-${String.fromCharCode(0x202E)}'
    '${String.fromCharCode(0x2066)}-${String.fromCharCode(0x2069)}]',
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  String _normaliseArabic(String s) {
    return s
        .replaceAll(_tashkeelTatweel, '')
        .replaceAll(_bidiMarks, '')
        .replaceAll(_whitespace, ' ')
        .trim();
  }
}
