import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/domain/entities/like_action_outcome.dart';
import 'package:qeran/features/likes/domain/entities/like_requests_data.dart';
import 'package:qeran/features/likes/domain/entities/likes_tab.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_outcome.dart';
import 'package:qeran/features/likes/domain/usecases/accept_like_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/accept_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_incoming_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_matches_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_outgoing_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_like_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_state.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';

class _MockIncoming extends Mock implements GetIncomingLikesUseCase {}

class _MockOutgoing extends Mock implements GetOutgoingLikesUseCase {}

class _MockAccept extends Mock implements AcceptLikeUseCase {}

class _MockReject extends Mock implements RejectLikeUseCase {}

class _MockGetMatches extends Mock implements GetMatchesUseCase {}

class _MockRequestPx extends Mock implements RequestPhotoExchangeUseCase {}

class _MockAcceptPx extends Mock implements AcceptPhotoExchangeUseCase {}

class _MockRejectPx extends Mock implements RejectPhotoExchangeUseCase {}

class _MockShareProfile extends Mock implements ShareProfileUseCase {}

class _MockSendText extends Mock implements SendTextMessageUseCase {}

const _empty = LikeRequestsData(
  pending: [],
  archived: [],
  requiresSubscription: false,
);

const List<MatchCard> _noMatches = <MatchCard>[];

void main() {
  late _MockIncoming incoming;
  late _MockOutgoing outgoing;
  late _MockAccept accept;
  late _MockReject reject;
  late _MockGetMatches getMatches;
  late _MockRequestPx requestPx;
  late _MockAcceptPx acceptPx;
  late _MockRejectPx rejectPx;
  late _MockShareProfile shareProfile;
  late _MockSendText sendText;
  late LikesCubit cubit;

  setUp(() {
    incoming = _MockIncoming();
    outgoing = _MockOutgoing();
    accept = _MockAccept();
    reject = _MockReject();
    getMatches = _MockGetMatches();
    requestPx = _MockRequestPx();
    acceptPx = _MockAcceptPx();
    rejectPx = _MockRejectPx();
    shareProfile = _MockShareProfile();
    sendText = _MockSendText();
    cubit = LikesCubit(
      getIncoming: incoming,
      getOutgoing: outgoing,
      acceptLike: accept,
      rejectLike: reject,
      getMatches: getMatches,
      requestPhotoExchange: requestPx,
      acceptPhotoExchange: acceptPx,
      rejectPhotoExchange: rejectPx,
      shareProfile: shareProfile,
      sendText: sendText,
    );
  });

  tearDown(() => cubit.close());

  test('loadOutgoing success → status loaded + data set', () async {
    when(() => outgoing())
        .thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

    await cubit.loadOutgoing();

    expect(cubit.state.outgoingStatus, LikesAsyncStatus.loaded);
    expect(cubit.state.outgoing, _empty);
    expect(cubit.state.outgoingErrorKey, isNull);
  });

  test('loadOutgoing failure → status failure + error key', () async {
    when(() => outgoing()).thenAnswer(
      (_) async => const Left<Failure, LikeRequestsData>(
        ServerFailure(message: 'errors.unexpected'),
      ),
    );

    await cubit.loadOutgoing();

    expect(cubit.state.outgoingStatus, LikesAsyncStatus.failure);
    expect(cubit.state.outgoingErrorKey, 'errors.unexpected');
  });

  test('switchTab to received triggers loadIncoming exactly once', () async {
    when(() => incoming())
        .thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

    cubit.switchTab(LikesTab.received);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.received);
    expect(cubit.state.incomingStatus, LikesAsyncStatus.loaded);
    verify(() => incoming()).called(1);
  });

  test('switchTab to matches triggers loadMatches exactly once', () async {
    when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.matches);
    expect(cubit.state.matchesStatus, LikesAsyncStatus.loaded);
    verify(() => getMatches()).called(1);
  });

  test('switchTab back-and-forth does not re-fetch a tab that is loaded',
      () async {
    when(() => incoming())
        .thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
    when(() => outgoing())
        .thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
    when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

    cubit.switchTab(LikesTab.received);
    await Future<void>.delayed(Duration.zero);
    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);
    cubit.switchTab(LikesTab.sent);
    await Future<void>.delayed(Duration.zero);
    cubit.switchTab(LikesTab.received);
    await Future<void>.delayed(Duration.zero);
    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);

    verify(() => incoming()).called(1);
    verify(() => outgoing()).called(1);
    verify(() => getMatches()).called(1);
  });

  test('refresh on matches tab delegates to loadMatches', () async {
    when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);
    await cubit.refresh();

    verify(() => getMatches()).called(2);
    verifyNever(() => incoming());
    verifyNever(() => outgoing());
  });

  test('close before usecase completes does not throw', () async {
    final completer = Completer<Either<Failure, LikeRequestsData>>();
    when(() => outgoing()).thenAnswer((_) => completer.future);

    final pending = cubit.loadOutgoing();
    await cubit.close();
    completer.complete(const Right<Failure, LikeRequestsData>(_empty));

    await expectLater(pending, completes);
  });

  group('acceptLike', () {
    test('success → emits acceptSuccess, reloads incoming, invalidates matches',
        () async {
      when(() => accept(42)).thenAnswer((_) async =>
          const Right<Failure, LikeActionOutcome>(
            LikeActionSuccess(serverMessage: 'تم القبول'),
          ));
      when(() => incoming()).thenAnswer(
          (_) async => const Right<Failure, LikeRequestsData>(_empty));

      await cubit.acceptLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.acceptSuccess);
      expect(cubit.state.matchesStatus, LikesAsyncStatus.initial,
          reason: 'matches slot is invalidated so next visit refetches');
      verify(() => accept(42)).called(1);
      verify(() => incoming()).called(1);
    });

    test('requiresSubscription → paywall event, NO refresh, NO invalidation',
        () async {
      when(() => accept(7)).thenAnswer((_) async =>
          const Right<Failure, LikeActionOutcome>(
            LikeActionRequiresSubscription(
                serverMessage: 'الاشتراك مطلوب لقبول الإعجابات'),
          ));

      await cubit.acceptLike(7);

      expect(
          cubit.state.actionEvent, LikesActionEvent.acceptRequiresSubscription);
      verifyNever(() => incoming());
    });

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, LikeActionOutcome>>();
      when(() => accept(5)).thenAnswer((_) => gate.future);
      when(() => incoming()).thenAnswer(
          (_) async => const Right<Failure, LikeRequestsData>(_empty));

      final first = cubit.acceptLike(5);
      expect(cubit.state.isAccepting(5), isTrue);
      final second = cubit.acceptLike(5);
      await second;
      gate.complete(const Right<Failure, LikeActionOutcome>(
          LikeActionSuccess(serverMessage: 'ok')));
      await first;

      verify(() => accept(5)).called(1);
    });
  });

  group('rejectLike', () {
    test('success → emits rejectSuccess + refresh', () async {
      when(() => reject(42)).thenAnswer((_) async =>
          const Right<Failure, LikeActionOutcome>(
            LikeActionSuccess(serverMessage: 'تم الرفض'),
          ));
      when(() => incoming()).thenAnswer(
          (_) async => const Right<Failure, LikeRequestsData>(_empty));

      await cubit.rejectLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.rejectSuccess);
      verify(() => incoming()).called(1);
    });
  });

  group('requestPhotoExchange', () {
    test('success → emits success event + loadMatches refresh', () async {
      when(() => requestPx(10)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRequestOutcome>(
              PhotoExchangeRequestSuccess(requestId: 7, serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.requestPhotoExchange(10);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRequestSuccess);
      verify(() => requestPx(10)).called(1);
      verify(() => getMatches()).called(1);
    });

    test('alreadyPending → event + refresh', () async {
      when(() => requestPx(11)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRequestOutcome>(
              PhotoExchangeRequestAlreadyPending(serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.requestPhotoExchange(11);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRequestAlreadyPending);
      verify(() => getMatches()).called(1);
    });

    test('requiresSubscription → paywall event, NO refresh', () async {
      when(() => requestPx(12)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRequestOutcome>(
              PhotoExchangeRequestRequiresSubscription(serverMessage: '')));

      await cubit.requestPhotoExchange(12);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRequestRequiresSubscription);
      verifyNever(() => getMatches());
    });

    test('transport failure → failure event, NO refresh', () async {
      when(() => requestPx(13)).thenAnswer((_) async =>
          const Left<Failure, PhotoExchangeRequestOutcome>(
              ServerFailure(message: 'errors.generic')));

      await cubit.requestPhotoExchange(13);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRequestFailure);
      verifyNever(() => getMatches());
    });

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRequestOutcome>>();
      when(() => requestPx(20)).thenAnswer((_) => gate.future);
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      final first = cubit.requestPhotoExchange(20);
      expect(cubit.state.isPhotoExchangeRequesting(20), isTrue);
      final second = cubit.requestPhotoExchange(20);
      await second;
      gate.complete(const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestSuccess(requestId: 1, serverMessage: '')));
      await first;

      verify(() => requestPx(20)).called(1);
    });
  });

  group('acceptPhotoExchange', () {
    test('success → emits acceptSuccess + refresh', () async {
      when(() => acceptPx(30)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRespondOutcome>(
              PhotoExchangeRespondSuccess(serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.acceptPhotoExchange(30);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeAcceptSuccess);
      verify(() => getMatches()).called(1);
    });

    test('expired → respondExpired event + refresh', () async {
      when(() => acceptPx(31)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRespondOutcome>(
              PhotoExchangeRespondExpired(serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.acceptPhotoExchange(31);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRespondExpired);
      verify(() => getMatches()).called(1);
    });

    test('rapid duplicate taps blocked while accept is in flight', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
      when(() => acceptPx(40)).thenAnswer((_) => gate.future);
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      final first = cubit.acceptPhotoExchange(40);
      expect(cubit.state.isPhotoExchangeAccepting(40), isTrue);
      // Reject for the same id should also be blocked by the
      // combined isPhotoExchangeResponding guard.
      final racing = cubit.rejectPhotoExchange(40);
      await racing;
      gate.complete(const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondSuccess(serverMessage: '')));
      await first;

      verify(() => acceptPx(40)).called(1);
      verifyNever(() => rejectPx(40));
    });
  });

  group('rejectPhotoExchange', () {
    test('success → emits rejectSuccess + refresh', () async {
      when(() => rejectPx(50)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRespondOutcome>(
              PhotoExchangeRespondSuccess(serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.rejectPhotoExchange(50);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRejectSuccess);
      verify(() => getMatches()).called(1);
    });

    test('notFound → respondNotFound event + refresh', () async {
      when(() => rejectPx(51)).thenAnswer((_) async =>
          const Right<Failure, PhotoExchangeRespondOutcome>(
              PhotoExchangeRespondNotFound(serverMessage: '')));
      when(() => getMatches()).thenAnswer(
          (_) async => const Right<Failure, List<MatchCard>>(_noMatches));

      await cubit.rejectPhotoExchange(51);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRespondNotFound);
      verify(() => getMatches()).called(1);
    });

    test('transport failure → respondFailure, NO refresh', () async {
      when(() => rejectPx(52)).thenAnswer((_) async =>
          const Left<Failure, PhotoExchangeRespondOutcome>(
              ServerFailure(message: 'errors.generic')));

      await cubit.rejectPhotoExchange(52);

      expect(cubit.state.actionEvent,
          LikesActionEvent.photoExchangeRespondFailure);
      verifyNever(() => getMatches());
    });
  });

  test('photo-exchange action after close does not throw', () async {
    final completer = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
    when(() => acceptPx(99)).thenAnswer((_) => completer.future);

    final pending = cubit.acceptPhotoExchange(99);
    await cubit.close();
    completer.complete(const Right<Failure, PhotoExchangeRespondOutcome>(
        PhotoExchangeRespondSuccess(serverMessage: '')));

    await expectLater(pending, completes);
  });
}
