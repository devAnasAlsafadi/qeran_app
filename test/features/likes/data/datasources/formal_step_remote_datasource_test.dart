import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/likes/data/datasources/formal_step_remote_datasource.dart';
import 'package:qeran/features/likes/data/error_codes.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_outcome.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

/// The request endpoint's whole job is turning one of five server verdicts
/// into something the card can say. A misrouted code is silent: the member
/// gets a plausible wrong sentence and no way to tell it is wrong.
void main() {
  late _MockApiConsumer api;
  late FormalStepRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = FormalStepRemoteDataSourceImpl(apiConsumer: api);
  });

  void answer(Map<String, dynamic> body) {
    when(() => api.postRaw(any())).thenAnswer((_) async => body);
  }

  group('the address', () {
    // The LIKE id, not the request id — accept and reject take the other one.
    // Sending the wrong one reaches a real endpoint with a real id and fails
    // in a way that looks like a server problem.
    //
    // Asserted against the LITERAL path, not against `EndPoints
    // .formalStepRequest(42)`. Verifying the helper against itself passes
    // whatever the helper is changed to say — a mutation that reshaped the
    // path to `formal-step/42/request` went undetected until this stopped
    // being written that way.
    test('posts to /api/formal-step/request/{likeRequestId}', () async {
      answer({'status': 1, 'message': '', 'data': '7'});

      final outcome = await ds.requestFormalStep(42);

      final path = verify(() => api.postRaw(captureAny())).captured.single;
      expect(path, 'formal-step/request/42');
      expect(outcome, isA<FormalStepRequestSuccess>());
      expect((outcome as FormalStepRequestSuccess).requestId, 7);
    });

    test('a numeric data field parses too', () async {
      answer({'status': 1, 'message': '', 'data': 7});

      final outcome = await ds.requestFormalStep(42);
      expect((outcome as FormalStepRequestSuccess).requestId, 7);
    });

    // `data` is undocumented for this endpoint. A missing id is not a failed
    // request — the matches refresh brings the real block back regardless.
    test('a missing data field is still a success', () async {
      answer({'status': 1, 'message': 'تم'});

      final outcome = await ds.requestFormalStep(42);
      expect(outcome, isA<FormalStepRequestSuccess>());
      expect((outcome as FormalStepRequestSuccess).requestId, isNull);
    });
  });

  group('classification', () {
    const cases = <String, Type>{
      FormalStepErrorCodes.formalStepAlreadyPending:
          FormalStepRequestAlreadyPending,
      FormalStepErrorCodes.formalStepNotAllowed: FormalStepRequestNotAllowed,
      FormalStepErrorCodes.likeNotAccepted: FormalStepRequestNotAllowed,
      FormalStepErrorCodes.caseNotActive: FormalStepRequestCaseEnded,
      FormalStepErrorCodes.profileNotApproved:
          FormalStepRequestProfileUnderReview,
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () async {
        answer({'status': 0, 'message': 'خطأ', 'errorCode': entry.key});

        final outcome = await ds.requestFormalStep(1);
        expect(outcome.runtimeType, entry.value);
      });
    }

    // Both mean "not at a point where this is allowed", so they share one
    // member on purpose. This pins that they still MEET there rather than
    // one of them quietly falling through to the generic failure.
    test('the two not-allowed codes reach the same member', () async {
      answer({
        'status': 0,
        'message': '',
        'errorCode': FormalStepErrorCodes.formalStepNotAllowed,
      });
      final a = await ds.requestFormalStep(1);
      answer({
        'status': 0,
        'message': '',
        'errorCode': FormalStepErrorCodes.likeNotAccepted,
      });
      final b = await ds.requestFormalStep(1);

      expect(a.runtimeType, b.runtimeType);
      expect(a, isA<FormalStepRequestNotAllowed>());
    });

    test('the reused codes fall through to a plain failure', () async {
      for (final code in const [
        FormalStepErrorCodes.caseNotFound,
        FormalStepErrorCodes.unauthorized,
        FormalStepErrorCodes.validationError,
      ]) {
        answer({'status': 0, 'message': 'x', 'errorCode': code});

        final outcome = await ds.requestFormalStep(1);
        expect(outcome, isA<FormalStepRequestFailure>(), reason: code);
        expect((outcome as FormalStepRequestFailure).errorCode, code);
      }
    });

    // The subscription vocabulary is NOT part of this endpoint's contract.
    // If a code like this ever arrives it must reach the generic failure, not
    // a paywall the formal step does not have.
    test('a subscription code gets no special treatment here', () async {
      answer({
        'status': 0,
        'message': 'الاشتراك مطلوب',
        'errorCode': 'SUBSCRIPTION_REQUIRED',
      });

      final outcome = await ds.requestFormalStep(1);
      expect(outcome, isA<FormalStepRequestFailure>());
    });

    // Unlike the photo-exchange classifier there is deliberately NO Arabic
    // substring fallback: these endpoints were born with error codes, and a
    // guessed match would mislabel a failure with full confidence.
    test('a coded-looking Arabic message with no code is not guessed at',
        () async {
      answer({'status': 0, 'message': 'يوجد طلب خطوة رسمية قائم بالفعل'});

      final outcome = await ds.requestFormalStep(1);
      expect(outcome, isA<FormalStepRequestFailure>());
      expect((outcome as FormalStepRequestFailure).errorCode, isNull);
    });
  });

  group('thrown transport errors', () {
    test('a classified CodedServerException becomes its typed outcome',
        () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(
          message: 'ignored',
          errorCode: FormalStepErrorCodes.caseNotActive,
        ),
      );

      expect(await ds.requestFormalStep(5), isA<FormalStepRequestCaseEnded>());
    });

    // An unmapped code has no honest card-level meaning, so it stays an
    // exception and reaches the repository as a Left.
    test('an unmapped code is rethrown for the repository', () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(message: 'oops', errorCode: 'UNKNOWN'),
      );

      expect(() => ds.requestFormalStep(6), throwsA(isA<ServerException>()));
    });

    test('an unexpected 2xx body shape throws rather than claiming success',
        () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => 'not a map');

      expect(() => ds.requestFormalStep(7), throwsA(isA<ServerException>()));
    });
  });
}
