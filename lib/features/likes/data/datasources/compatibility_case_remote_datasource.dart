import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/formal_step_outcome.dart';
import '../error_codes.dart';

/// Every action a MEMBER can take on their compatibility case: asking for the
/// formal step, answering one, and calling the whole case off.
///
/// Kept in its own datasource rather than added to `MatchesRemoteDataSource`,
/// which is already 409 lines carrying the matches list and all three
/// photo-exchange calls. A sibling is not a split of anything — nothing
/// moved — and it leaves both files a readable size.
///
/// It was named for the formal step while that was all it held. Cancel is a
/// case action on a `/api/matches` path, not a formal-step one, so the name
/// widened to what the four calls actually have in common. The backend groups
/// them the same way: one block of four member-side case routes.
abstract interface class CompatibilityCaseRemoteDataSource {
  /// `POST /api/formal-step/request/{likeRequestId}` — Bearer JWT, no body.
  /// Returns a typed outcome for the success path and the four known semantic
  /// failures.
  Future<FormalStepRequestOutcome> requestFormalStep(int likeRequestId);

  /// `POST /api/formal-step/{requestId}/accept` — responder side.
  /// `requestId` is `pendingFormalStep.id`, NOT the like id.
  Future<FormalStepRespondOutcome> acceptFormalStep(int requestId);

  /// `POST /api/formal-step/{requestId}/reject` — responder side. Ends the
  /// compatibility case rather than routing it anywhere.
  Future<FormalStepRespondOutcome> rejectFormalStep(int requestId);

  /// `POST /api/matches/{likeRequestId}/cancel` — either member calling the
  /// case off, at any stage, for as long as it is still running.
  ///
  /// Takes the RELATIONSHIP id, like the formal-step request and unlike the
  /// accept/reject pair.
  Future<CaseCancelOutcome> cancelCase(int likeRequestId);
}

class CompatibilityCaseRemoteDataSourceImpl implements CompatibilityCaseRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const CompatibilityCaseRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<FormalStepRequestOutcome> requestFormalStep(int likeRequestId) {
    return _post<FormalStepRequestOutcome>(
      path: EndPoints.formalStepRequest(likeRequestId),
      label: 'request likeRequestId=$likeRequestId',
      onOk: (data, message) => FormalStepRequestSuccess(
        requestId: _parseRequestId(data),
        serverMessage: message,
      ),
      classify: _classifyRequest,
      isUnmapped: (o) => o is FormalStepRequestFailure,
    );
  }

  @override
  Future<FormalStepRespondOutcome> acceptFormalStep(int requestId) {
    return _respond(requestId, EndPoints.formalStepAccept(requestId), 'accept');
  }

  @override
  Future<FormalStepRespondOutcome> rejectFormalStep(int requestId) {
    return _respond(requestId, EndPoints.formalStepReject(requestId), 'reject');
  }

  @override
  Future<CaseCancelOutcome> cancelCase(int likeRequestId) {
    return _post<CaseCancelOutcome>(
      path: EndPoints.matchCancel(likeRequestId),
      label: 'cancel likeRequestId=$likeRequestId',
      onOk: (_, message) => CaseCancelSuccess(serverMessage: message),
      classify: _classifyCancel,
      isUnmapped: (o) => o is CaseCancelFailure,
    );
  }

  Future<FormalStepRespondOutcome> _respond(
    int requestId,
    String path,
    String verb,
  ) {
    return _post<FormalStepRespondOutcome>(
      path: path,
      label: '$verb requestId=$requestId',
      onOk: (_, message) => FormalStepRespondSuccess(serverMessage: message),
      classify: _classifyRespond,
      isUnmapped: (o) => o is FormalStepRespondFailure,
    );
  }

  /// The envelope dance every formal-step call performs, once.
  ///
  /// Each endpoint differs only in its path, its success value and its code
  /// vocabulary. Writing the status check, the `data` read, the log lines and
  /// the `ServerException` rethrow three times over is how the three drift
  /// apart — and the drift that matters is [isUnmapped]: an outcome the
  /// client cannot name must stay an exception so the repository turns it
  /// into a `Left`, rather than reaching the card as a typed answer it does
  /// not have words for.
  Future<T> _post<T>({
    required String path,
    required String label,
    required T Function(Object? data, String message) onOk,
    required T Function(String message, String? errorCode) classify,
    required bool Function(T outcome) isUnmapped,
  }) async {
    AppLogger.debug('FORMAL-STEP — $label', tag: 'MATCHES');
    try {
      final body = await _apiConsumer.postRaw(path);
      final message = _envelopeMessage(body);
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) return classify(message, body['errorCode'] as String?);
        AppLogger.info('FORMAL-STEP — $label accepted', tag: 'MATCHES');
        return onOk(body['data'], message);
      }
      // Defensive — unexpected body shape on 2xx.
      AppLogger.warning(
        'FORMAL-STEP — $label unexpected body type=${body.runtimeType}',
        tag: 'MATCHES',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = classify(e.message, code);
      if (isUnmapped(outcome)) {
        AppLogger.warning(
          'FORMAL-STEP — $label transport/unmapped '
          'code="$code" message="${e.message}"',
          tag: 'MATCHES',
        );
        rethrow;
      }
      AppLogger.warning(
        'FORMAL-STEP — $label classified outcome=${outcome.runtimeType} '
        'code="$code" message="${e.message}"',
        tag: 'MATCHES',
      );
      return outcome;
    }
  }

  /// Classifies purely on `errorCode`, with no Arabic-message fallback.
  ///
  /// The photo-exchange classifier keeps one because that endpoint shipped
  /// before `errorCode` existed and old servers still answer in prose. These
  /// endpoints were born with codes. Guessing at substrings we have never
  /// seen a server send would be inventing a contract, and a wrong guess here
  /// silently mislabels a failure rather than falling through to the honest
  /// generic message.
  FormalStepRequestOutcome _classifyRequest(
    String rawMessage,
    String? errorCode,
  ) {
    return switch (errorCode) {
      FormalStepErrorCodes.formalStepAlreadyPending =>
        FormalStepRequestAlreadyPending(serverMessage: rawMessage),
      // One answer for both: neither is a state the member can act on, and
      // the difference between them is not theirs to care about.
      FormalStepErrorCodes.formalStepNotAllowed ||
      FormalStepErrorCodes.likeNotAccepted =>
        FormalStepRequestNotAllowed(serverMessage: rawMessage),
      FormalStepErrorCodes.caseNotActive =>
        FormalStepRequestCaseEnded(serverMessage: rawMessage),
      FormalStepErrorCodes.profileNotApproved =>
        FormalStepRequestProfileUnderReview(serverMessage: rawMessage),
      _ => FormalStepRequestFailure(
          serverMessage: rawMessage,
          errorCode: errorCode,
        ),
    };
  }

  /// Same policy, the responder's vocabulary.
  ///
  /// `PROFILE_NOT_APPROVED` is deliberately absent: answering a request that
  /// was already sent to you is not a new outward action, so it is not gated
  /// on approval and the code does not appear in this endpoint's list.
  /// Letting it through to the generic failure is the honest reading if that
  /// ever changes.
  FormalStepRespondOutcome _classifyRespond(
    String rawMessage,
    String? errorCode,
  ) {
    return switch (errorCode) {
      FormalStepErrorCodes.formalStepNotFound =>
        FormalStepRespondNotFound(serverMessage: rawMessage),
      FormalStepErrorCodes.formalStepExpired =>
        FormalStepRespondExpired(serverMessage: rawMessage),
      FormalStepErrorCodes.caseNotActive =>
        FormalStepRespondCaseEnded(serverMessage: rawMessage),
      _ => FormalStepRespondFailure(
          serverMessage: rawMessage,
          errorCode: errorCode,
        ),
    };
  }

  /// Cancel has no error codes of its own — it reuses the shared ones. The
  /// only failure worth naming is a case that has already stopped, which is
  /// exactly what a second cancel gets.
  CaseCancelOutcome _classifyCancel(String rawMessage, String? errorCode) {
    return switch (errorCode) {
      FormalStepErrorCodes.caseNotActive =>
        CaseCancelAlreadyEnded(serverMessage: rawMessage),
      FormalStepErrorCodes.caseNotFound =>
        CaseCancelNotFound(serverMessage: rawMessage),
      _ => CaseCancelFailure(
          serverMessage: rawMessage,
          errorCode: errorCode,
        ),
    };
  }

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
}
