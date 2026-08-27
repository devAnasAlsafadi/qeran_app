import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/likes/data/datasources/compatibility_case_remote_datasource.dart';
import 'package:qeran/features/likes/data/error_codes.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_outcome.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

/// Four member-side case actions, and each one's whole job is turning a server
/// verdict into something the card can say. A misrouted code is silent: the
/// member gets a plausible wrong sentence and no way to tell it is wrong.
void main() {
  late _MockApiConsumer api;
  late CompatibilityCaseRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = CompatibilityCaseRemoteDataSourceImpl(apiConsumer: api);
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

  group('accept and reject', () {
    // Literal paths again, for the reason the request test carries: verifying
    // the EndPoints helper against itself proves only that it equals itself.
    //
    // And these take the REQUEST id where the request call takes the LIKE id.
    // Both are ints, both plausible, so the wrong one reaches a real endpoint
    // with a real id and fails looking like a server problem.
    test('accept posts to /api/formal-step/{requestId}/accept', () async {
      answer({'status': 1, 'message': 'تمت الموافقة'});

      final outcome = await ds.acceptFormalStep(88);

      final path = verify(() => api.postRaw(captureAny())).captured.single;
      expect(path, 'formal-step/88/accept');
      expect(outcome, isA<FormalStepRespondSuccess>());
    });

    test('reject posts to /api/formal-step/{requestId}/reject', () async {
      answer({'status': 1, 'message': ''});

      final outcome = await ds.rejectFormalStep(88);

      final path = verify(() => api.postRaw(captureAny())).captured.single;
      expect(path, 'formal-step/88/reject');
      expect(outcome, isA<FormalStepRespondSuccess>());
    });

    test('the two never share a path', () async {
      answer({'status': 1, 'message': ''});
      await ds.acceptFormalStep(5);
      await ds.rejectFormalStep(5);

      final paths = verify(() => api.postRaw(captureAny())).captured;
      expect(paths.toSet().length, 2, reason: '$paths');
    });

    const cases = <String, Type>{
      FormalStepErrorCodes.formalStepNotFound: FormalStepRespondNotFound,
      FormalStepErrorCodes.formalStepExpired: FormalStepRespondExpired,
      FormalStepErrorCodes.caseNotActive: FormalStepRespondCaseEnded,
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () async {
        answer({'status': 0, 'message': 'خطأ', 'errorCode': entry.key});

        expect(
          (await ds.acceptFormalStep(1)).runtimeType,
          entry.value,
        );
      });
    }

    // Accept and reject fail in the same ways and share one outcome family;
    // this pins that they also share one CLASSIFIER, rather than two that
    // agree today and drift later.
    test('both verbs classify a code identically', () async {
      answer({
        'status': 0,
        'message': '',
        'errorCode': FormalStepErrorCodes.formalStepExpired,
      });

      expect(
        (await ds.acceptFormalStep(1)).runtimeType,
        (await ds.rejectFormalStep(1)).runtimeType,
      );
    });

    // The REQUEST vocabulary must not leak in. ALREADY_PENDING answering a
    // request you are being asked to answer is meaningless, and NOT_ALLOWED
    // is not in this endpoint's list.
    test('request-only codes fall through to a plain failure', () async {
      for (final code in const [
        FormalStepErrorCodes.formalStepAlreadyPending,
        FormalStepErrorCodes.formalStepNotAllowed,
        FormalStepErrorCodes.likeNotAccepted,
        FormalStepErrorCodes.profileNotApproved,
      ]) {
        answer({'status': 0, 'message': 'x', 'errorCode': code});

        final outcome = await ds.acceptFormalStep(1);
        expect(outcome, isA<FormalStepRespondFailure>(), reason: code);
      }
    });

    test('an unmapped code is rethrown for the repository', () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(message: 'oops', errorCode: 'UNKNOWN'),
      );

      expect(() => ds.rejectFormalStep(6), throwsA(isA<ServerException>()));
    });

    test('a classified throw becomes its typed outcome', () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(
          message: 'ignored',
          errorCode: FormalStepErrorCodes.formalStepExpired,
        ),
      );

      expect(await ds.acceptFormalStep(5), isA<FormalStepRespondExpired>());
    });

    test('an unexpected 2xx body shape throws rather than claiming success',
        () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => 'not a map');

      expect(() => ds.acceptFormalStep(7), throwsA(isA<ServerException>()));
    });
  });

  group('cancel', () {
    // The RELATIONSHIP id, like the formal-step request and unlike the
    // accept/reject pair — and a `matches` path, not a `formal-step` one.
    // Literal, so the assertion cannot pass by agreeing with itself.
    test('posts to /api/matches/{likeRequestId}/cancel', () async {
      answer({'status': 1, 'message': 'تم الإلغاء'});

      final outcome = await ds.cancelCase(405);

      final path = verify(() => api.postRaw(captureAny())).captured.single;
      expect(path, 'matches/405/cancel');
      expect(outcome, isA<CaseCancelSuccess>());
    });

    // What a SECOND cancel gets. The affordance should already be hidden by
    // then, so arriving here means the card was acting on a stale read.
    test('CASE_NOT_ACTIVE reads as already ended', () async {
      answer({
        'status': 0,
        'message': 'الحالة منتهية',
        'errorCode': FormalStepErrorCodes.caseNotActive,
      });

      expect(await ds.cancelCase(1), isA<CaseCancelAlreadyEnded>());
    });

    test('CASE_NOT_FOUND reads as missing', () async {
      answer({
        'status': 0,
        'message': '',
        'errorCode': FormalStepErrorCodes.caseNotFound,
      });

      expect(await ds.cancelCase(1), isA<CaseCancelNotFound>());
    });

    // Cancel has no vocabulary of its own. The formal-step codes are not its
    // business, and letting one through as a named outcome would give the
    // member a sentence about a step when the case is what they acted on.
    test('the formal-step codes get no special treatment', () async {
      for (final code in const [
        FormalStepErrorCodes.formalStepNotFound,
        FormalStepErrorCodes.formalStepExpired,
        FormalStepErrorCodes.formalStepAlreadyPending,
        FormalStepErrorCodes.formalStepNotAllowed,
        FormalStepErrorCodes.profileNotApproved,
      ]) {
        answer({'status': 0, 'message': 'x', 'errorCode': code});

        expect(await ds.cancelCase(1), isA<CaseCancelFailure>(), reason: code);
      }
    });

    test('an unmapped code is rethrown for the repository', () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(message: 'oops', errorCode: 'UNKNOWN'),
      );

      expect(() => ds.cancelCase(6), throwsA(isA<ServerException>()));
    });

    test('a classified throw becomes its typed outcome', () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(
          message: 'ignored',
          errorCode: FormalStepErrorCodes.caseNotActive,
        ),
      );

      expect(await ds.cancelCase(5), isA<CaseCancelAlreadyEnded>());
    });

    test('an unexpected 2xx body shape throws rather than claiming success',
        () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => 'not a map');

      expect(() => ds.cancelCase(7), throwsA(isA<ServerException>()));
    });

    // Four routes, four distinct paths. Cancel resolving to any of the others
    // would end a case when the member asked for something else entirely.
    test('no two of the four actions share a path', () async {
      answer({'status': 1, 'message': ''});
      await ds.requestFormalStep(9);
      await ds.acceptFormalStep(9);
      await ds.rejectFormalStep(9);
      await ds.cancelCase(9);

      final paths = verify(() => api.postRaw(captureAny())).captured;
      expect(paths.toSet().length, 4, reason: '$paths');
    });
  });
}
