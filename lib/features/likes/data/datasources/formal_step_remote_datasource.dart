import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/formal_step_outcome.dart';
import '../error_codes.dart';

/// The formal-step endpoints, kept in their OWN datasource rather than added
/// to `MatchesRemoteDataSource`.
///
/// That file is already 409 lines carrying the matches list and all three
/// photo-exchange calls; the formal step brings four more endpoints of its
/// own once accept, reject and cancel land. A sibling is not a split of
/// anything — nothing moves — and it leaves both files a readable size.
abstract interface class FormalStepRemoteDataSource {
  /// `POST /api/formal-step/request/{likeRequestId}` — Bearer JWT, no body.
  /// Returns a typed outcome for the success path and the four known semantic
  /// failures.
  Future<FormalStepRequestOutcome> requestFormalStep(int likeRequestId);
}

class FormalStepRemoteDataSourceImpl implements FormalStepRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const FormalStepRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<FormalStepRequestOutcome> requestFormalStep(int likeRequestId) async {
    AppLogger.debug(
      'FORMAL-STEP — request likeRequestId=$likeRequestId',
      tag: 'MATCHES',
    );
    try {
      final body =
          await _apiConsumer.postRaw(EndPoints.formalStepRequest(likeRequestId));
      final message = _envelopeMessage(body);
      if (body is Map<String, dynamic>) {
        final ok = body['status'] == 1 || body['status'] == true;
        if (!ok) {
          return _classify(message, body['errorCode'] as String?);
        }
        final requestId = _parseRequestId(body['data']);
        AppLogger.info(
          'FORMAL-STEP — request accepted '
          'likeRequestId=$likeRequestId requestId=$requestId',
          tag: 'MATCHES',
        );
        return FormalStepRequestSuccess(
          requestId: requestId,
          serverMessage: message,
        );
      }
      // Defensive — unexpected body shape on 2xx.
      AppLogger.warning(
        'FORMAL-STEP — request unexpected body type=${body.runtimeType}',
        tag: 'MATCHES',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    } on ServerException catch (e) {
      final code = e is CodedServerException ? e.errorCode : null;
      final outcome = _classify(e.message, code);
      if (outcome is FormalStepRequestFailure) {
        AppLogger.warning(
          'FORMAL-STEP — request transport/unmapped '
          'likeRequestId=$likeRequestId code="$code" message="${e.message}"',
          tag: 'MATCHES',
        );
        rethrow;
      }
      AppLogger.warning(
        'FORMAL-STEP — request classified likeRequestId=$likeRequestId '
        'outcome=${outcome.runtimeType} code="$code" message="${e.message}"',
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
  FormalStepRequestOutcome _classify(String rawMessage, String? errorCode) {
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
