import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/like_action_outcome.dart';
import '../error_codes.dart';
import '../models/like_requests_data_model.dart';

abstract interface class LikesRemoteDataSource {
  /// `GET /api/likes/incoming` — Bearer JWT.
  Future<LikeRequestsDataModel> getIncomingLikes();

  /// `GET /api/likes/outgoing` — Bearer JWT.
  Future<LikeRequestsDataModel> getOutgoingLikes();

  /// `POST /api/likes/{likeRequestId}/accept` — Bearer JWT, no body.
  /// Returns a typed [LikeActionOutcome] for both the success and
  /// known semantic failures (subscription required, expired, missing).
  /// Transport-level failures throw `ServerException`; the repository
  /// converts them to `Left(Failure)`.
  Future<LikeActionOutcome> acceptLike(int likeRequestId);

  /// `POST /api/likes/{likeRequestId}/reject` — Bearer JWT, no body.
  /// Reject is never subscription-gated; only the "not found / expired"
  /// branches surface as typed outcomes.
  Future<LikeActionOutcome> rejectLike(int likeRequestId);
}

class LikesRemoteDataSourceImpl implements LikesRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const LikesRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<LikeRequestsDataModel> getIncomingLikes() async {
    AppLogger.debug('FETCH LIKES — incoming', tag: 'LIKES');
    // `getRaw` bypasses the global `status == 1` gate. We still
    // validate the envelope ourselves inside `_toModel` so a status-1
    // body parses cleanly AND a future direct-shape body (no envelope)
    // keeps working without a network-layer change.
    final body = await _apiConsumer.getRaw(EndPoints.likesIncoming);
    return _toModel(body);
  }

  @override
  Future<LikeRequestsDataModel> getOutgoingLikes() async {
    AppLogger.debug('FETCH LIKES — outgoing', tag: 'LIKES');
    final body = await _apiConsumer.getRaw(EndPoints.likesOutgoing);
    return _toModel(body);
  }

  @override
  Future<LikeActionOutcome> acceptLike(int likeRequestId) =>
      _action(
        path: EndPoints.likesAccept(likeRequestId),
        likeRequestId: likeRequestId,
        action: 'accept',
      );

  @override
  Future<LikeActionOutcome> rejectLike(int likeRequestId) =>
      _action(
        path: EndPoints.likesReject(likeRequestId),
        likeRequestId: likeRequestId,
        action: 'reject',
      );

  /// Shared accept/reject runner. Hits the no-body POST through
  /// `postRaw` (the global `status == 1` gate would otherwise turn
  /// every classified failure into a transport error and discard the
  /// raw message we need for classification).
  Future<LikeActionOutcome> _action({
    required String path,
    required int likeRequestId,
    required String action,
  }) async {
    AppLogger.debug('LIKES — $action likeRequestId=$likeRequestId', tag: 'LIKES');
    try {
      final body = await _apiConsumer.postRaw(path);
      final message = _envelopeMessage(body);
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          final code = body['errorCode'] as String?;
          final outcome = _classify(message, code);
          AppLogger.warning(
            'LIKES — $action rejected likeRequestId=$likeRequestId '
            'outcome=${outcome.runtimeType} code="$code" message="$message"',
            tag: 'LIKES',
          );
          return outcome;
        }
      }
      AppLogger.info(
        'LIKES — $action accepted likeRequestId=$likeRequestId',
        tag: 'LIKES',
      );
      return LikeActionSuccess(serverMessage: message);
    } on ServerException catch (e) {
      // `postRaw` throws either `CodedServerException` (carries
      // `errorCode`) on `{success:false}` or non-2xx, or a plain
      // `ServerException` from transport errors. Map known codes /
      // messages to typed outcomes; everything else propagates so the
      // repository turns it into `Left(Failure)`.
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classify(e.message, code);
      if (outcome is LikeActionFailure) {
        AppLogger.warning(
          'LIKES — $action transport/unmapped likeRequestId=$likeRequestId '
          'code="$code" message="${e.message}"',
          tag: 'LIKES',
        );
        rethrow;
      }
      AppLogger.warning(
        'LIKES — $action rejected likeRequestId=$likeRequestId '
        'outcome=${outcome.runtimeType} code="$code" message="${e.message}"',
        tag: 'LIKES',
      );
      return outcome;
    }
  }

  String _envelopeMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final raw = body['message'];
      if (raw is String) return raw;
    }
    return '';
  }

  /// Maps backend failures onto a typed outcome. Strategy:
  ///
  /// 1. If `errorCode` is present, switch on it (canonical path).
  /// 2. Otherwise, fall back to Arabic-message substring matching for
  ///    backward compatibility with the pre-errorCode rollout. This
  ///    branch can be removed once backend ships `errorCode` on every
  ///    failure response.
  ///
  /// Order in the legacy block matters: "انتهت مدة الطلب" must
  /// classify BEFORE the broader "غير موجود / منتهي" branch — the
  /// latter would otherwise swallow it through the "منتهي" substring.
  LikeActionOutcome _classify(String rawMessage, String? errorCode) {
    if (errorCode != null && errorCode.isNotEmpty) {
      switch (errorCode) {
        case LikesErrorCodes.subscriptionRequired:
        case LikesErrorCodes.likesQuotaExceeded:
        case LikesErrorCodes.likesFreeQuotaExceeded:
          return LikeActionRequiresSubscription(serverMessage: rawMessage);
        case LikesErrorCodes.likeExpired:
          return LikeActionExpired(serverMessage: rawMessage);
        case LikesErrorCodes.likeNotFound:
          return LikeActionNotFoundOrExpired(serverMessage: rawMessage);
        case LikesErrorCodes.profileNotApproved:
          return LikeActionProfileUnderReview(serverMessage: rawMessage);
        default:
          return LikeActionFailure(serverMessage: rawMessage);
      }
    }
    // Legacy Arabic-message fallback — retained for backward compat
    // until the backend errorCode rollout is complete.
    final m = _normaliseArabic(rawMessage);
    if (m.contains(_normaliseArabic('الاشتراك مطلوب'))) {
      return LikeActionRequiresSubscription(serverMessage: rawMessage);
    }
    if (m.contains(_normaliseArabic('انتهت مدة'))) {
      return LikeActionExpired(serverMessage: rawMessage);
    }
    if (m.contains(_normaliseArabic('غير موجود')) ||
        m.contains(_normaliseArabic('منتهي'))) {
      return LikeActionNotFoundOrExpired(serverMessage: rawMessage);
    }
    return LikeActionFailure(serverMessage: rawMessage);
  }

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

  /// Three deployment states this parser must survive:
  ///
  /// 1. **Envelope (current)** — `{ status: 1, data: {pending, archived,
  ///    requiresSubscription}, message }`. We honour `status` — a value
  ///    other than `1` / `true` throws with a localized key so the UI
  ///    never surfaces the raw server message.
  /// 2. **Direct (previous deployment)** — `{ pending, archived,
  ///    requiresSubscription }`. Used as a fallback so the screen stays
  ///    green if the backend flips again mid-rollout.
  /// 3. **Unknown / broken** — anything else throws with `errors.generic`.
  ///    The raw shape is logged at error-level for engineering follow-up.
  LikeRequestsDataModel _toModel(dynamic body) {
    if (body is! Map<String, dynamic>) {
      AppLogger.error(
        'LIKES — unexpected body shape: ${body.runtimeType}',
        tag: 'LIKES',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    // (1) Envelope shape — preferred.
    if (body.containsKey('status') || body.containsKey('data')) {
      final ok = body['status'] == 1 || body['status'] == true;
      if (!ok) {
        AppLogger.warning(
          'LIKES — envelope reported failure '
          'status=${body['status']} message="${body['message']}"',
          tag: 'LIKES',
        );
        throw ServerException(message: LocaleKeys.errors_generic);
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        AppLogger.error(
          'LIKES — envelope ok but data shape unexpected: ${data.runtimeType}',
          tag: 'LIKES',
        );
        throw ServerException(message: LocaleKeys.errors_generic);
      }
      final model = LikeRequestsDataModel.fromJson(data);
      _logSummary(model);
      return model;
    }
    // (2) Direct shape — backward-compatible fallback.
    if (body.containsKey('pending') || body.containsKey('archived')) {
      final model = LikeRequestsDataModel.fromJson(body);
      _logSummary(model);
      return model;
    }
    // (3) Unknown.
    AppLogger.error(
      'LIKES — body has neither envelope nor direct keys: '
      '${body.keys.toList()}',
      tag: 'LIKES',
    );
    throw ServerException(message: LocaleKeys.errors_generic);
  }

  void _logSummary(LikeRequestsDataModel model) {
    AppLogger.info(
      'Likes — pending=${model.pending.length} '
      'archived=${model.archived.length} '
      'requiresSubscription=${model.requiresSubscription}',
      tag: 'LIKES',
    );
  }
}
