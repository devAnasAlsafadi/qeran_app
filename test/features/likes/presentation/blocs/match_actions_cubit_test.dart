import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_outcome.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_outcome.dart';
import 'package:qeran/features/likes/domain/usecases/accept_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/accept_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/cancel_case_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/match_actions_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/match_actions_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

/// The photo exchange, the formal step and cancel, moved here with the cubit.
///
/// Same assertions that ran inside the likes cubit's suite; what changed is
/// the cubit under test, the names of its outcomes, and how the matches
/// refetch is observed. It used to be `verify(getMatches)` against a use case
/// the same cubit owned — it is now a counter on the injected callback, which
/// is a truer test of the contract: this cubit does not know HOW the list
/// reloads, only that it asked.

class _MockRequestPx extends Mock implements RequestPhotoExchangeUseCase {}

class _MockAcceptPx extends Mock implements AcceptPhotoExchangeUseCase {}

class _MockRejectPx extends Mock implements RejectPhotoExchangeUseCase {}

class _MockRequestFormalStep extends Mock
    implements RequestFormalStepUseCase {}

class _MockAcceptFormalStep extends Mock implements AcceptFormalStepUseCase {}

class _MockRejectFormalStep extends Mock implements RejectFormalStepUseCase {}

class _MockCancelCase extends Mock implements CancelCaseUseCase {}

class _MockProfileGate extends Mock implements ProfileGateCubit {}

void main() {
  late _MockRequestPx requestPx;
  late _MockAcceptPx acceptPx;
  late _MockRejectPx rejectPx;
  late _MockRequestFormalStep requestFormal;
  late _MockAcceptFormalStep acceptFormal;
  late _MockRejectFormalStep rejectFormal;
  late _MockCancelCase cancelCase;
  late _MockProfileGate profileGate;
  late MatchActionsCubit cubit;

  /// How many times this cubit asked for the list back.
  late int reloads;

  setUp(() {
    requestPx = _MockRequestPx();
    acceptPx = _MockAcceptPx();
    rejectPx = _MockRejectPx();
    requestFormal = _MockRequestFormalStep();
    acceptFormal = _MockAcceptFormalStep();
    rejectFormal = _MockRejectFormalStep();
    cancelCase = _MockCancelCase();
    profileGate = _MockProfileGate();
    when(() => profileGate.isGated).thenReturn(false);
    reloads = 0;
    cubit = MatchActionsCubit(
      requestPhotoExchange: requestPx,
      acceptPhotoExchange: acceptPx,
      rejectPhotoExchange: rejectPx,
      requestFormalStep: requestFormal,
      acceptFormalStep: acceptFormal,
      rejectFormalStep: rejectFormal,
      cancelCase: cancelCase,
      profileGate: profileGate,
      reloadMatches: () async => reloads++,
    );
  });

  tearDown(() => cubit.close());

  group('requestPhotoExchange', () {
    test('success → emits success event + loadMatches refresh', () async {
      when(() => requestPx(10)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestSuccess(requestId: 7, serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(10);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRequestSuccess,
      );
      verify(() => requestPx(10)).called(1);
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('alreadyPending → event + refresh', () async {
      when(() => requestPx(11)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestAlreadyPending(serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(11);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRequestAlreadyPending,
      );
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('requiresSubscription → paywall event, NO refresh', () async {
      when(() => requestPx(12)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestRequiresSubscription(serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(12);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRequestRequiresSubscription,
      );
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    test('limitReached → limit-reached event, NO refresh', () async {
      when(() => requestPx(14)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestLimitReached(serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(14);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRequestLimitReached,
      );
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    test('transport failure → failure event, NO refresh', () async {
      when(() => requestPx(13)).thenAnswer(
        (_) async => const Left<Failure, PhotoExchangeRequestOutcome>(
          ServerFailure(message: 'errors.generic'),
        ),
      );

      await cubit.requestPhotoExchange(13);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRequestFailure,
      );
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRequestOutcome>>();
      when(() => requestPx(20)).thenAnswer((_) => gate.future);

      final first = cubit.requestPhotoExchange(20);
      expect(cubit.state.isPhotoRequesting(20), isTrue);
      final second = cubit.requestPhotoExchange(20);
      await second;
      gate.complete(
        const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestSuccess(requestId: 1, serverMessage: ''),
        ),
      );
      await first;

      verify(() => requestPx(20)).called(1);
    });
  });

  group('acceptPhotoExchange', () {
    test('success → emits acceptSuccess + refresh', () async {
      when(() => acceptPx(30)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: ''),
        ),
      );

      await cubit.acceptPhotoExchange(30);

      expect(
        cubit.state.event,
        MatchActionEvent.photoAcceptSuccess,
      );
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('expired → respondExpired event + refresh', () async {
      when(() => acceptPx(31)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondExpired(serverMessage: ''),
        ),
      );

      await cubit.acceptPhotoExchange(31);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRespondExpired,
      );
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('rapid duplicate taps blocked while accept is in flight', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
      when(() => acceptPx(40)).thenAnswer((_) => gate.future);

      final first = cubit.acceptPhotoExchange(40);
      expect(cubit.state.isPhotoAccepting(40), isTrue);
      // Reject for the same id should also be blocked by the
      // combined isPhotoExchangeResponding guard.
      final racing = cubit.rejectPhotoExchange(40);
      await racing;
      gate.complete(
        const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: ''),
        ),
      );
      await first;

      verify(() => acceptPx(40)).called(1);
      verifyNever(() => rejectPx(40));
    });
  });

  group('rejectPhotoExchange', () {
    test('success → emits rejectSuccess + refresh', () async {
      when(() => rejectPx(50)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: ''),
        ),
      );

      await cubit.rejectPhotoExchange(50);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRejectSuccess,
      );
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('notFound → respondNotFound event + refresh', () async {
      when(() => rejectPx(51)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondNotFound(serverMessage: ''),
        ),
      );

      await cubit.rejectPhotoExchange(51);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRespondNotFound,
      );
      expect(reloads, 1, reason: 'the list was not refetched');
    });

    test('transport failure → respondFailure, NO refresh', () async {
      when(() => rejectPx(52)).thenAnswer(
        (_) async => const Left<Failure, PhotoExchangeRespondOutcome>(
          ServerFailure(message: 'errors.generic'),
        ),
      );

      await cubit.rejectPhotoExchange(52);

      expect(
        cubit.state.event,
        MatchActionEvent.photoRespondFailure,
      );
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    // The pair the formal step already has, missing here. Photo accept and
    // reject share one guard, so a card mid-accept must not also be able to
    // send a reject — and BOTH directions are needed: a guard reading only
    // the accept set still drops a reject-during-accept, and it takes the
    // mirror to catch it, because nothing is in the accept set then.
    //
    // Found by mutating `isPhotoResponding` down to `isPhotoAccepting`, which
    // passed. The formal-step twin twenty lines below has caught the same
    // mutation since sub-step 4b; this side was never given the test.
    test('a reject while an accept is in flight is dropped', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
      when(() => acceptPx(7)).thenAnswer((_) => gate.future);
      when(() => rejectPx(7)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: ''),
        ),
      );

      final accepting = cubit.acceptPhotoExchange(7);
      await Future<void>.delayed(Duration.zero);
      final rejecting = cubit.rejectPhotoExchange(7);
      gate.complete(
        const Right(PhotoExchangeRespondSuccess(serverMessage: '')),
      );
      await Future.wait([accepting, rejecting]);

      verifyNever(() => rejectPx(any()));
    });

    test('an accept while a reject is in flight is dropped', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
      when(() => rejectPx(7)).thenAnswer((_) => gate.future);
      when(() => acceptPx(7)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: ''),
        ),
      );

      final rejecting = cubit.rejectPhotoExchange(7);
      await Future<void>.delayed(Duration.zero);
      final accepting = cubit.acceptPhotoExchange(7);
      gate.complete(
        const Right(PhotoExchangeRespondSuccess(serverMessage: '')),
      );
      await Future.wait([rejecting, accepting]);

      verifyNever(() => acceptPx(any()));
    });
  });

  group('sendFormalStep', () {
    void serverSays(FormalStepRequestOutcome outcome) {
      when(() => requestFormal(43)).thenAnswer(
        (_) async => Right<Failure, FormalStepRequestOutcome>(outcome),
      );
    }

    // The test that used to sit here verified sendFormalStep posts nothing
    // into the matchmaker chat. It is GONE because it became unwritable, not
    // because the rule was dropped: LikesCubit no longer holds a chat use case
    // to mock, having handed all three to MatchmakerInquiryCubit. A runtime
    // check became a compile-time one, and the reasoning now lives on
    // sendFormalStep itself.

    const outcomes = <FormalStepRequestOutcome, MatchActionEvent>{
      FormalStepRequestSuccess(requestId: null, serverMessage: ''):
          MatchActionEvent.formalStepSuccess,
      FormalStepRequestAlreadyPending(serverMessage: ''):
          MatchActionEvent.formalStepAlreadyPending,
      FormalStepRequestNotAllowed(serverMessage: ''):
          MatchActionEvent.formalStepNotAllowed,
      FormalStepRequestCaseEnded(serverMessage: ''):
          MatchActionEvent.formalStepCaseEnded,
      FormalStepRequestProfileUnderReview(serverMessage: ''):
          MatchActionEvent.formalStepUnderReview,
      FormalStepRequestFailure(serverMessage: '', errorCode: null):
          MatchActionEvent.formalStepFailure,
    };

    test('every outcome reaches an event of its own', () {
      expect(outcomes.values.toSet().length, outcomes.length);
    });

    for (final entry in outcomes.entries) {
      test('${entry.key.runtimeType} reports ${entry.value.name}', () async {
        serverSays(entry.key);

        await cubit.sendFormalStep(43);

        expect(cubit.state.event, entry.value);
      });
    }

    // Every REFUSAL means the card acted on a stale view, so the list is
    // refetched for those too, not only on success. Under-review and a
    // transport failure say nothing about the case, so they leave it alone.
    test('refreshes on success and on every refusal, not on the rest', () async {
      const refresh = {
        MatchActionEvent.formalStepSuccess,
        MatchActionEvent.formalStepAlreadyPending,
        MatchActionEvent.formalStepNotAllowed,
        MatchActionEvent.formalStepCaseEnded,
      };
      for (final entry in outcomes.entries) {
        // One cubit, many outcomes: the counter has to be zeroed per case.
        // `verify().called(1)` used to consume its records and reset itself,
        // which is the kind of thing a counter does not do for you.
        reloads = 0;
        serverSays(entry.key);
        await cubit.sendFormalStep(43);

        if (refresh.contains(entry.value)) {
          expect(reloads, 1, reason: 'the list was not refetched');
        } else {
          expect(reloads, isZero, reason: 'the list was refetched anyway');
        }
      }
    });

    test('a transport failure reports failure and does not refresh', () async {
      when(() => requestFormal(43)).thenAnswer(
        (_) async => const Left<Failure, FormalStepRequestOutcome>(
          ServerFailure(message: 'offline'),
        ),
      );

      await cubit.sendFormalStep(43);

      expect(cubit.state.event, MatchActionEvent.formalStepFailure);
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    // The pre-gate exists so an unapproved member does not spend a round trip
    // learning what the app already knows.
    test('an unapproved profile never reaches the server', () async {
      when(() => profileGate.isGated).thenReturn(true);

      await cubit.sendFormalStep(43);

      expect(cubit.state.event, MatchActionEvent.formalStepUnderReview);
      verifyNever(() => requestFormal(any()));
    });

    test('a second tap while the first is in flight is dropped', () async {
      final gate = Completer<Either<Failure, FormalStepRequestOutcome>>();
      when(() => requestFormal(43)).thenAnswer((_) => gate.future);

      final first = cubit.sendFormalStep(43);
      await Future<void>.delayed(Duration.zero);
      final second = cubit.sendFormalStep(43);
      gate.complete(
        const Right(FormalStepRequestSuccess(requestId: 1, serverMessage: '')),
      );
      await Future.wait([first, second]);

      verify(() => requestFormal(43)).called(1);
    });
  });

  group('answering a formal step', () {
    void serverSays(FormalStepRespondOutcome outcome) {
      when(() => acceptFormal(77)).thenAnswer(
        (_) async => Right<Failure, FormalStepRespondOutcome>(outcome),
      );
      when(() => rejectFormal(77)).thenAnswer(
        (_) async => Right<Failure, FormalStepRespondOutcome>(outcome),
      );
    }

    // These take pendingFormalStep.id where sendFormalStep takes the like id.
    // Both are ints; the wrong one reaches a real endpoint with a real id.
    test('accept and reject each call their own use case', () async {
      serverSays(const FormalStepRespondSuccess(serverMessage: ''));

      await cubit.acceptFormalStep(77);
      verify(() => acceptFormal(77)).called(1);
      verifyNever(() => rejectFormal(any()));

      await cubit.rejectFormalStep(77);
      verify(() => rejectFormal(77)).called(1);
    });

    // Success is the ONLY outcome where the two verbs part company. Reporting
    // a decline as an approval is the failure this pins.
    test('success reports which answer was given', () async {
      serverSays(const FormalStepRespondSuccess(serverMessage: ''));

      await cubit.acceptFormalStep(77);
      expect(cubit.state.event, MatchActionEvent.formalStepAcceptSuccess);

      await cubit.rejectFormalStep(77);
      expect(cubit.state.event, MatchActionEvent.formalStepRejectSuccess);
    });

    const refusals = <FormalStepRespondOutcome, MatchActionEvent>{
      FormalStepRespondNotFound(serverMessage: ''):
          MatchActionEvent.formalStepRespondNotFound,
      FormalStepRespondExpired(serverMessage: ''):
          MatchActionEvent.formalStepRespondExpired,
      FormalStepRespondCaseEnded(serverMessage: ''):
          MatchActionEvent.formalStepRespondCaseEnded,
      FormalStepRespondFailure(serverMessage: '', errorCode: null):
          MatchActionEvent.formalStepRespondFailure,
    };

    test('every refusal reaches an event of its own', () {
      expect(refusals.values.toSet().length, refusals.length);
    });

    // Both verbs fail in the same ways, so both must report them the same
    // way. Two copies of this mapping would be two chances to disagree.
    for (final entry in refusals.entries) {
      test('${entry.key.runtimeType} reads the same either way', () async {
        serverSays(entry.key);

        await cubit.acceptFormalStep(77);
        expect(cubit.state.event, entry.value);

        await cubit.rejectFormalStep(77);
        expect(cubit.state.event, entry.value);
      });
    }

    // Anything the SERVER answered moved the case or proved the card stale.
    // Only a transport failure — where it said nothing — leaves the list be.
    test('refreshes for every server answer, never for a dead connection',
        () async {
      for (final outcome in <FormalStepRespondOutcome>[
        const FormalStepRespondSuccess(serverMessage: ''),
        ...refusals.keys,
      ]) {
        reloads = 0;
        serverSays(outcome);
        await cubit.acceptFormalStep(77);

        if (outcome is FormalStepRespondFailure) {
          expect(reloads, isZero, reason: 'the list was refetched anyway');
        } else {
          expect(reloads, 1, reason: 'the list was not refetched');
        }
      }
    });

    test('a transport failure reports failure and does not refresh', () async {
      when(() => rejectFormal(77)).thenAnswer(
        (_) async => const Left<Failure, FormalStepRespondOutcome>(
          ServerFailure(message: 'offline'),
        ),
      );

      await cubit.rejectFormalStep(77);

      expect(
        cubit.state.event,
        MatchActionEvent.formalStepRespondFailure,
      );
      expect(reloads, isZero, reason: 'the list was refetched anyway');
    });

    // Answering a request already sent to you is not a new outward action, so
    // it is not approval-gated the way sending one is.
    test('an unapproved profile can still answer', () async {
      when(() => profileGate.isGated).thenReturn(true);
      serverSays(const FormalStepRespondSuccess(serverMessage: ''));

      await cubit.acceptFormalStep(77);

      expect(cubit.state.event, MatchActionEvent.formalStepAcceptSuccess);
      verify(() => acceptFormal(77)).called(1);
    });

    // THE guard that spans both buttons: a card mid-accept must not also be
    // able to send a reject. A per-verb guard would let both through.
    test('a reject while an accept is in flight is dropped', () async {
      final gate = Completer<Either<Failure, FormalStepRespondOutcome>>();
      when(() => acceptFormal(77)).thenAnswer((_) => gate.future);
      when(() => rejectFormal(77)).thenAnswer(
        (_) async => const Right<Failure, FormalStepRespondOutcome>(
          FormalStepRespondSuccess(serverMessage: ''),
        ),
      );

      final accepting = cubit.acceptFormalStep(77);
      await Future<void>.delayed(Duration.zero);
      final rejecting = cubit.rejectFormalStep(77);
      gate.complete(
        const Right(FormalStepRespondSuccess(serverMessage: '')),
      );
      await Future.wait([accepting, rejecting]);

      verifyNever(() => rejectFormal(any()));
    });

    // The MIRROR of the test above, and it is not redundant. A guard that
    // reads only the accept set still drops a reject-during-accept — it is
    // this direction that catches it, because nothing is in the accept set.
    test('an accept while a reject is in flight is dropped', () async {
      final gate = Completer<Either<Failure, FormalStepRespondOutcome>>();
      when(() => rejectFormal(77)).thenAnswer((_) => gate.future);
      when(() => acceptFormal(77)).thenAnswer(
        (_) async => const Right<Failure, FormalStepRespondOutcome>(
          FormalStepRespondSuccess(serverMessage: ''),
        ),
      );

      final rejecting = cubit.rejectFormalStep(77);
      await Future<void>.delayed(Duration.zero);
      final accepting = cubit.acceptFormalStep(77);
      gate.complete(
        const Right(FormalStepRespondSuccess(serverMessage: '')),
      );
      await Future.wait([rejecting, accepting]);

      verifyNever(() => acceptFormal(any()));
    });

    test('a different request id is not blocked by one in flight', () async {
      final gate = Completer<Either<Failure, FormalStepRespondOutcome>>();
      when(() => acceptFormal(77)).thenAnswer((_) => gate.future);
      when(() => acceptFormal(78)).thenAnswer(
        (_) async => const Right<Failure, FormalStepRespondOutcome>(
          FormalStepRespondSuccess(serverMessage: ''),
        ),
      );

      final first = cubit.acceptFormalStep(77);
      await Future<void>.delayed(Duration.zero);
      final other = cubit.acceptFormalStep(78);
      gate.complete(
        const Right(FormalStepRespondSuccess(serverMessage: '')),
      );
      await Future.wait([first, other]);

      verify(() => acceptFormal(78)).called(1);
    });
  });

  group('cancelling a case', () {
    void serverSays(CaseCancelOutcome outcome) {
      when(() => cancelCase(42)).thenAnswer(
        (_) async => Right<Failure, CaseCancelOutcome>(outcome),
      );
    }

    // Cancel takes the LIKE id. Accept and reject beside it take
    // pendingFormalStep.id, and all three are ints — the wrong one reaches a
    // real endpoint with a real id and ends someone else's case.
    test('calls cancel with the like id and nothing else', () async {
      serverSays(const CaseCancelSuccess(serverMessage: ''));

      await cubit.cancelCase(42);

      verify(() => cancelCase(42)).called(1);
      verifyNever(() => rejectFormal(any()));
      verifyNever(() => acceptFormal(any()));
      verifyNever(() => requestFormal(any()));
    });

    const outcomes = <CaseCancelOutcome, MatchActionEvent>{
      CaseCancelSuccess(serverMessage: ''): MatchActionEvent.cancelSuccess,
      CaseCancelAlreadyEnded(serverMessage: ''):
          MatchActionEvent.cancelAlreadyEnded,
      CaseCancelNotFound(serverMessage: ''): MatchActionEvent.cancelNotFound,
      CaseCancelFailure(serverMessage: '', errorCode: null):
          MatchActionEvent.cancelFailure,
    };

    for (final entry in outcomes.entries) {
      test('${entry.key.runtimeType} reports ${entry.value.name}', () async {
        serverSays(entry.key);
        await cubit.cancelCase(42);
        expect(cubit.state.event, entry.value);
      });
    }

    // AlreadyEnded is unreachable from the UI until 5d hides the affordance on
    // a case that is not Active, so it is wired and pinned here rather than
    // left as a hole for that sub-step to remember.
    test('a second cancel on an ended case is reported, not swallowed',
        () async {
      serverSays(const CaseCancelAlreadyEnded(serverMessage: ''));
      await cubit.cancelCase(42);
      expect(cubit.state.event, MatchActionEvent.cancelAlreadyEnded);
    });

    test('a transport failure reports cancelFailure', () async {
      when(() => cancelCase(42)).thenAnswer(
        (_) async => const Left<Failure, CaseCancelOutcome>(
          ServerFailure(message: 'boom'),
        ),
      );
      await cubit.cancelCase(42);
      expect(cubit.state.event, MatchActionEvent.cancelFailure);
    });

    // Success refetches because the row does NOT disappear — the case stays in
    // the feed and comes back reading as ended. Without the refetch the card
    // keeps offering the actions of a live case.
    for (final entry in outcomes.entries) {
      final refetches = entry.value != MatchActionEvent.cancelFailure;
      test('${entry.value.name} ${refetches ? "" : "does not "}refetch',
          () async {
        serverSays(entry.key);
        await cubit.cancelCase(42);
        if (refetches) {
          expect(reloads, 1, reason: 'the list was not refetched');
        } else {
          expect(reloads, isZero, reason: 'the list was refetched anyway');
        }
      });
    }

    // Asserts the in-flight state is EMITTED, not merely held. Reading
    // `cubit.state` is not enough: Cubit drops an emit whose state compares
    // equal to the last one, so a field missing from `props` leaves the button
    // without its spinner while `state` still looks correct to a test.
    //
    // The list is loaded first for the same reason — `emit` skips that
    // equality check entirely on a cubit's FIRST emit, which is never how a
    // real cancel arrives. Priming used to be a loadMatches call; this cubit
    // does not own the list, so any emit will do and openJourney is the
    // cheapest one that changes state.
    test('the in-flight state reaches listeners, then clears', () async {
      cubit.openJourney(1);

      final gate = Completer<Either<Failure, CaseCancelOutcome>>();
      when(() => cancelCase(42)).thenAnswer((_) => gate.future);

      final seen = <bool>[];
      final sub = cubit.stream.listen((s) => seen.add(s.isCancelling(42)));
      addTearDown(sub.cancel);

      final pending = cubit.cancelCase(42);
      await Future<void>.delayed(Duration.zero);
      expect(
        seen,
        contains(true),
        reason: 'no state carrying the in-flight id was emitted',
      );

      gate.complete(const Right(CaseCancelSuccess(serverMessage: '')));
      await pending;
      expect(cubit.state.isCancelling(42), isFalse);
    });

    // The guard has to BITE, not just exist. A double-tap on an X that ends a
    // case is the one place a dropped second call matters most.
    test('a second cancel while one is in flight is dropped', () async {
      final gate = Completer<Either<Failure, CaseCancelOutcome>>();
      when(() => cancelCase(42)).thenAnswer((_) => gate.future);

      final first = cubit.cancelCase(42);
      await Future<void>.delayed(Duration.zero);
      final second = cubit.cancelCase(42);
      gate.complete(const Right(CaseCancelSuccess(serverMessage: '')));
      await Future.wait([first, second]);

      verify(() => cancelCase(42)).called(1);
    });

    test('a different card is not blocked by one in flight', () async {
      final gate = Completer<Either<Failure, CaseCancelOutcome>>();
      when(() => cancelCase(42)).thenAnswer((_) => gate.future);
      when(() => cancelCase(43)).thenAnswer(
        (_) async => const Right<Failure, CaseCancelOutcome>(
          CaseCancelSuccess(serverMessage: ''),
        ),
      );

      final first = cubit.cancelCase(42);
      await Future<void>.delayed(Duration.zero);
      final other = cubit.cancelCase(43);
      gate.complete(const Right(CaseCancelSuccess(serverMessage: '')));
      await Future.wait([first, other]);

      verify(() => cancelCase(43)).called(1);
    });
  });

  group('compatibility journey', () {
    test('opening a card records it, and only one at a time', () {
      cubit.openJourney(1);
      expect(cubit.state.isJourneyOpen(1), isTrue);

      cubit.openJourney(2);
      expect(cubit.state.isJourneyOpen(1), isFalse);
      expect(cubit.state.isJourneyOpen(2), isTrue);
    });

    test('null closes whichever is open', () {
      cubit.openJourney(1);
      cubit.openJourney(null);

      expect(cubit.state.openJourneyLikeRequestId, isNull);
    });

    test('closing needs the explicit clear, not a bare null', () {
      const open = MatchActionsState(openJourneyLikeRequestId: 5);
      expect(
        open.copyWith(openJourneyLikeRequestId: null).isJourneyOpen(5),
        isTrue,
        reason: 'a bare null must not be mistaken for "close it"',
      );
      expect(
        open.copyWith(clearOpenJourney: true).openJourneyLikeRequestId,
        isNull,
      );
    });

    test('nothing is open by default', () {
      expect(const MatchActionsState().openJourneyLikeRequestId, isNull);
      expect(const MatchActionsState().isJourneyOpen(1), isFalse);
    });

    // The finding this whole design exists for: the list is torn down and
    // rebuilt on every matches refresh, and an open card held down there would
    // close each time.
    //
    // It used to be checked by round-tripping matchesStatus through the state
    // that also held the journey id. Those are two different cubits now, so
    // the survival is structural — but the sequence a member actually performs
    // is worth pinning at the cubit level, which the copyWith version never
    // covered: open a card, take an action that refetches, card still open.
    test('an open card survives an action that refetches the list', () async {
      cubit.openJourney(5);
      when(() => cancelCase(9)).thenAnswer(
        (_) async => const Right<Failure, CaseCancelOutcome>(
          CaseCancelSuccess(serverMessage: ''),
        ),
      );

      await cubit.cancelCase(9);

      expect(reloads, 1, reason: 'the fixture must actually refetch');
      expect(cubit.state.isJourneyOpen(5), isTrue);
    });

    // Cards rebuild on every matches refresh; re-reporting the card that is
    // already open must not emit and churn the list.
    test('re-opening the same card emits nothing', () async {
      cubit.openJourney(1);
      final emissions = <MatchActionsState>[];
      final sub = cubit.stream.listen(emissions.add);

      cubit.openJourney(1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, isEmpty);
    });

    test('closing when nothing is open emits nothing', () async {
      final emissions = <MatchActionsState>[];
      final sub = cubit.stream.listen(emissions.add);

      cubit.openJourney(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, isEmpty);
    });
  });

  test('photo-exchange action after close does not throw', () async {
    final completer = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
    when(() => acceptPx(99)).thenAnswer((_) => completer.future);

    final pending = cubit.acceptPhotoExchange(99);
    await cubit.close();
    completer.complete(
      const Right<Failure, PhotoExchangeRespondOutcome>(
        PhotoExchangeRespondSuccess(serverMessage: ''),
      ),
    );

    await expectLater(pending, completes);
  });
}
