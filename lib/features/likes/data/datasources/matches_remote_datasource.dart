import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/photo_exchange_outcome.dart';
import '../error_codes.dart';
import '../models/match_card_model.dart';

abstract interface class MatchesRemoteDataSource {
  /// `GET /api/matches` — Bearer JWT. Returns active matches across
  /// stages 0/1/2.
  Future<List<MatchCardModel>> getMatches();

  /// `POST /api/photo-exchange/request/{likeRequestId}` — Bearer JWT,
  /// no body. Returns a typed outcome for both the success path
  /// (with the new request id) and the four known semantic failures.
  Future<PhotoExchangeRequestOutcome> requestPhotoExchange(int likeRequestId);

  /// `POST /api/photo-exchange/{requestId}/accept`.
  Future<PhotoExchangeRespondOutcome> acceptPhotoExchange(int requestId);

  /// `POST /api/photo-exchange/{requestId}/reject`.
  Future<PhotoExchangeRespondOutcome> rejectPhotoExchange(int requestId);
}

class MatchesRemoteDataSourceImpl implements MatchesRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchesRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<List<MatchCardModel>> getMatches() async {
    AppLogger.debug('FETCH MATCHES', tag: 'MATCHES');
    final body = await _apiConsumer.getRaw(EndPoints.matches);
    return _parseMatchesList(body);
  }

  @override
  Future<PhotoExchangeRequestOutcome> requestPhotoExchange(
    int likeRequestId,
  ) async {
    AppLogger.debug(
      'PHOTO-EXCHANGE — request likeRequestId=$likeRequestId',
      tag: 'MATCHES',
    );
    try {
      final body = await _apiConsumer
          .postRaw(EndPoints.photoExchangeRequest(likeRequestId));
      final message = _envelopeMessage(body);
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          final code = body['errorCode'] as String?;
          return _classifyRequest(message, code);
        }
        final requestId = _parseRequestId(body['data']);
        AppLogger.info(
          'PHOTO-EXCHANGE — request accepted '
          'likeRequestId=$likeRequestId requestId=$requestId',
          tag: 'MATCHES',
        );
        return PhotoExchangeRequestSuccess(
          requestId: requestId,
          serverMessage: message,
        );
      }
      // Defensive — unexpected body shape on 2xx.
      AppLogger.warning(
        'PHOTO-EXCHANGE — request unexpected body type=${body.runtimeType}',
        tag: 'MATCHES',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classifyRequest(e.message, code);
      if (outcome is PhotoExchangeRequestFailure) {
        AppLogger.warning(
          'PHOTO-EXCHANGE — request transport/unmapped '
          'likeRequestId=$likeRequestId code="$code" message="${e.message}"',
          tag: 'MATCHES',
        );
        rethrow;
      }
      AppLogger.warning(
        'PHOTO-EXCHANGE — request classified '
        'likeRequestId=$likeRequestId outcome=${outcome.runtimeType} '
        'code="$code" message="${e.message}"',
        tag: 'MATCHES',
      );
      return outcome;
    }
  }

  @override
  Future<PhotoExchangeRespondOutcome> acceptPhotoExchange(int requestId) =>
      _respond(
        path: EndPoints.photoExchangeAccept(requestId),
        requestId: requestId,
        action: 'accept',
      );

  @override
  Future<PhotoExchangeRespondOutcome> rejectPhotoExchange(int requestId) =>
      _respond(
        path: EndPoints.photoExchangeReject(requestId),
        requestId: requestId,
        action: 'reject',
      );

  Future<PhotoExchangeRespondOutcome> _respond({
    required String path,
    required int requestId,
    required String action,
  }) async {
    AppLogger.debug(
      'PHOTO-EXCHANGE — $action requestId=$requestId',
      tag: 'MATCHES',
    );
    try {
      final body = await _apiConsumer.postRaw(path);
      final message = _envelopeMessage(body);
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          final code = body['errorCode'] as String?;
          return _classifyRespond(message, code);
        }
      }
      AppLogger.info(
        'PHOTO-EXCHANGE — $action accepted requestId=$requestId',
        tag: 'MATCHES',
      );
      return PhotoExchangeRespondSuccess(serverMessage: message);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classifyRespond(e.message, code);
      if (outcome is PhotoExchangeRespondFailure) {
        AppLogger.warning(
          'PHOTO-EXCHANGE — $action transport/unmapped requestId=$requestId '
          'code="$code" message="${e.message}"',
          tag: 'MATCHES',
        );
        rethrow;
      }
      AppLogger.warning(
        'PHOTO-EXCHANGE — $action classified requestId=$requestId '
        'outcome=${outcome.runtimeType} code="$code" message="${e.message}"',
        tag: 'MATCHES',
      );
      return outcome;
    }
  }

  // ── Classification ─────────────────────────────────────────────────

  PhotoExchangeRequestOutcome _classifyRequest(
    String rawMessage,
    String? errorCode,
  ) {
    if (errorCode != null && errorCode.isNotEmpty) {
      switch (errorCode) {
        case PhotoExchangeErrorCodes.subscriptionRequired:
          return PhotoExchangeRequestRequiresSubscription(
              serverMessage: rawMessage);
        case PhotoExchangeErrorCodes.photoExchangeAlreadyPending:
          return PhotoExchangeRequestAlreadyPending(serverMessage: rawMessage);
        case PhotoExchangeErrorCodes.photoExchangeLimitReached:
        case PhotoExchangeErrorCodes.photoExchangeFreeLimitReached:
          return PhotoExchangeRequestLimitReached(serverMessage: rawMessage);
        case PhotoExchangeErrorCodes.likeNotAccepted:
          return PhotoExchangeRequestLikeNotAccepted(serverMessage: rawMessage);
        case PhotoExchangeErrorCodes.profileNotApproved:
          return PhotoExchangeRequestProfileUnderReview(
              serverMessage: rawMessage);
        default:
          return PhotoExchangeRequestFailure(
            serverMessage: rawMessage,
            errorCode: errorCode,
          );
      }
    }
    // Legacy Arabic-message fallback.
    final m = _normaliseArabic(rawMessage);
    if (m.contains(_normaliseArabic('الاشتراك مطلوب'))) {
      return PhotoExchangeRequestRequiresSubscription(
          serverMessage: rawMessage);
    }
    if (m.contains(_normaliseArabic('طلب تبادل قائم'))) {
      return PhotoExchangeRequestAlreadyPending(serverMessage: rawMessage);
    }
    if (m.contains(_normaliseArabic('غير موجود')) ||
        m.contains(_normaliseArabic('لم يُقبل')) ||
        m.contains(_normaliseArabic('لم يقبل'))) {
      return PhotoExchangeRequestLikeNotAccepted(serverMessage: rawMessage);
    }
    return PhotoExchangeRequestFailure(
      serverMessage: rawMessage,
      errorCode: null,
    );
  }

  PhotoExchangeRespondOutcome _classifyRespond(
    String rawMessage,
    String? errorCode,
  ) {
    if (errorCode != null && errorCode.isNotEmpty) {
      switch (errorCode) {
        case PhotoExchangeErrorCodes.photoExchangeExpired:
          return PhotoExchangeRespondExpired(serverMessage: rawMessage);
        case PhotoExchangeErrorCodes.photoExchangeNotFound:
          return PhotoExchangeRespondNotFound(serverMessage: rawMessage);
        default:
          return PhotoExchangeRespondFailure(
            serverMessage: rawMessage,
            errorCode: errorCode,
          );
      }
    }
    final m = _normaliseArabic(rawMessage);
    if (m.contains(_normaliseArabic('انتهت مدة'))) {
      return PhotoExchangeRespondExpired(serverMessage: rawMessage);
    }
    if (m.contains(_normaliseArabic('غير موجود'))) {
      return PhotoExchangeRespondNotFound(serverMessage: rawMessage);
    }
    return PhotoExchangeRespondFailure(
      serverMessage: rawMessage,
      errorCode: null,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  String _envelopeMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final raw = body['message'];
      if (raw is String) return raw;
    }
    return '';
  }

  int? _parseRequestId(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  List<MatchCardModel> _parseMatchesList(dynamic body) {
    if (body is List) {
      return _mapList(body);
    }
    if (body is Map<String, dynamic>) {
      // Envelope shape: { status: 1, data: [...] }.
      if (body.containsKey('status') || body.containsKey('data')) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          AppLogger.warning(
            'MATCHES — envelope reported failure '
            'status=${body['status']} message="${body['message']}"',
            tag: 'MATCHES',
          );
          throw ServerException(message: LocaleKeys.errors_generic);
        }
        final data = body['data'];
        if (data is List) {
          final list = _mapList(data);
          AppLogger.info(
            'Matches — count=${list.length}',
            tag: 'MATCHES',
          );
          return list;
        }
        if (data == null) return const [];
        AppLogger.error(
          'MATCHES — envelope ok but data shape unexpected: ${data.runtimeType}',
          tag: 'MATCHES',
        );
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    }
    AppLogger.error(
      'MATCHES — unexpected body shape: ${body.runtimeType}',
      tag: 'MATCHES',
    );
    throw ServerException(message: LocaleKeys.errors_generic);
  }

  /// Per-row parse with structured logging on failure.
  ///
  /// A single bad row used to crash the entire Matches tab — when one
  /// field's type drifts (int vs String), the cast threw all the way
  /// up. We now isolate each row: the safe parsers absorb most type
  /// drift, and any residual failure logs the row's `likeRequestId`
  /// (when extractable) at error level so backend can investigate.
  /// The offending row is dropped from the list; the rest still
  /// renders.
  ///
  /// Production logs do NOT include the full payload — only the
  /// likeRequestId + the exception's runtime message. Sensitive
  /// fields (names, ids of the OTHER party) never reach the log.
  ///
  /// Also emits a `debug`-only per-row dump of the raw
  /// `pendingPhotoExchange` flags so we can verify backend
  /// direction / canAccept / canReject on both sides of a pair
  /// without surfacing PII in prod logs. `AppLogger.debug` is a no-op
  /// outside `kDebugMode`.
  List<MatchCardModel> _mapList(List raw) {
    final out = <MatchCardModel>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      _logPendingDebug(item);
      try {
        out.add(MatchCardModel.fromJson(item));
      } catch (e, st) {
        final lrid = item['likeRequestId'];
        AppLogger.error(
          'MATCHES — failed to parse one match row '
          'likeRequestId=$lrid error=$e',
          error: e,
          stack: st,
          tag: 'MATCHES',
        );
      }
    }
    return List<MatchCardModel>.unmodifiable(out);
  }

  /// Debug-only diagnostic for the photo-exchange direction issue.
  /// Logs the exact backend-supplied fields the UI branches on so
  /// QA can compare initiator vs receiver sides of a pair without
  /// reaching for raw HTTP dumps. No-op in release builds.
  ///
  /// Also dumps the journey fields and the formal-step block. Those are new,
  /// and the block's exact shape is taken from a spec rather than from a real
  /// response — this is how the two get compared without arranging a special
  /// capture. `expiresAt` is the one worth watching: the photo-exchange block
  /// keeps returning a live-looking deadline after a request has lapsed, and
  /// whether the formal step does the same is unconfirmed.
  void _logPendingDebug(Map<String, dynamic> row) {
    final lrid = row['likeRequestId'];
    AppLogger.debug(
      'MATCHES row — likeRequestId=$lrid '
      'stage=${row['stage']} '
      'caseStage=${row['caseStage']} '
      'caseStatus=${row['caseStatus']}',
      tag: 'MATCHES',
    );
    _logBlock(lrid, 'pendingPhotoExchange', row['pendingPhotoExchange'], const [
      'id',
      'direction',
      'requestedByMe',
      'canAccept',
      'canReject',
      'initiatorId',
      'responderId',
      'statusCode',
      'remainingSeconds',
      'expiresAt',
    ]);
    _logBlock(lrid, 'pendingFormalStep', row['pendingFormalStep'], const [
      'id',
      'status',
      'direction',
      'requestedByMe',
      'canAccept',
      'canReject',
      'remainingSeconds',
      'expiresAt',
    ]);
  }

  /// Dumps [keys] out of a nested block, or reports it absent. Unknown keys
  /// print as `null`, which is itself the signal when a field we expected is
  /// not there — and any key the server sends that we did NOT ask for stays
  /// invisible, so the block is listed by name too.
  void _logBlock(Object? lrid, String name, Object? raw, List<String> keys) {
    if (raw is! Map<String, dynamic>) {
      AppLogger.debug('MATCHES row — id=$lrid $name=null', tag: 'MATCHES');
      return;
    }
    final shown = keys.map((k) => '$k=${raw[k]}').join(' ');
    final extra = raw.keys.where((k) => !keys.contains(k)).toList();
    AppLogger.debug(
      'MATCHES row — id=$lrid $name: $shown'
      '${extra.isEmpty ? '' : ' | unlisted keys: $extra'}',
      tag: 'MATCHES',
    );
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
}
