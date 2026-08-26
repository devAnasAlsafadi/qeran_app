import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/domain/entities/like_action_outcome.dart';
import 'package:qeran/features/likes/domain/entities/like_requests_data.dart';
import 'package:qeran/features/likes/domain/entities/likes_tab.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_outcome.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_outcome.dart';
import 'package:qeran/features/likes/domain/usecases/accept_like_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/accept_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_incoming_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_matches_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_outgoing_likes_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_like_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_state.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

class _MockIncoming extends Mock implements GetIncomingLikesUseCase {}

class _MockOutgoing extends Mock implements GetOutgoingLikesUseCase {}

class _MockAccept extends Mock implements AcceptLikeUseCase {}

class _MockReject extends Mock implements RejectLikeUseCase {}

class _MockGetMatches extends Mock implements GetMatchesUseCase {}

class _MockRequestPx extends Mock implements RequestPhotoExchangeUseCase {}

class _MockAcceptPx extends Mock implements AcceptPhotoExchangeUseCase {}

class _MockRejectPx extends Mock implements RejectPhotoExchangeUseCase {}

class _MockRequestFormalStep extends Mock
    implements RequestFormalStepUseCase {}

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

class _MockShareProfile extends Mock implements ShareProfileUseCase {}

class _MockSendText extends Mock implements SendTextMessageUseCase {}

class _MockProfileGate extends Mock implements ProfileGateCubit {}

class _MockChatMessage extends Mock implements ChatMessage {}

const _empty = LikeRequestsData(
  pending: [],
  archived: [],
  requiresSubscription: false,
);

const List<MatchCard> _noMatches = <MatchCard>[];

const _stageZeroMatch = MatchCard(
  likeRequestId: 42,
  otherUserId: 'candidate-id',
  otherUserName: 'Candidate',
  images: [],
  stage: MatchStage.waitingForPhotoExchange,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
);

void main() {
  late _MockIncoming incoming;
  late _MockOutgoing outgoing;
  late _MockAccept accept;
  late _MockReject reject;
  late _MockGetMatches getMatches;
  late _MockRequestPx requestPx;
  late _MockAcceptPx acceptPx;
  late _MockRejectPx rejectPx;
  late _MockRequestFormalStep requestFormal;
  late _MockGetMyMatchmaker getMyMatchmaker;
  late _MockShareProfile shareProfile;
  late _MockSendText sendText;
  late _MockProfileGate profileGate;
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
    requestFormal = _MockRequestFormalStep();
    getMyMatchmaker = _MockGetMyMatchmaker();
    shareProfile = _MockShareProfile();
    sendText = _MockSendText();
    profileGate = _MockProfileGate();
    when(() => profileGate.isGated).thenReturn(false);
    cubit = LikesCubit(
      getIncoming: incoming,
      getOutgoing: outgoing,
      acceptLike: accept,
      rejectLike: reject,
      getMatches: getMatches,
      requestPhotoExchange: requestPx,
      acceptPhotoExchange: acceptPx,
      rejectPhotoExchange: rejectPx,
      requestFormalStep: requestFormal,
      getMyMatchmaker: getMyMatchmaker,
      shareProfile: shareProfile,
      sendText: sendText,
      profileGate: profileGate,
    );
  });

  tearDown(() => cubit.close());

  test('loadOutgoing success → status loaded + data set', () async {
    when(
      () => outgoing(),
    ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

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
    when(
      () => incoming(),
    ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

    cubit.switchTab(LikesTab.received);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.received);
    expect(cubit.state.incomingStatus, LikesAsyncStatus.loaded);
    verify(() => incoming()).called(1);
  });

  test('switchTab to matches triggers loadMatches exactly once', () async {
    when(() => getMatches()).thenAnswer(
      (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
    );

    cubit.switchTab(LikesTab.matches);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.activeTab, LikesTab.matches);
    expect(cubit.state.matchesStatus, LikesAsyncStatus.loaded);
    verify(() => getMatches()).called(1);
  });

  test(
    'switchTab back-and-forth does not re-fetch a tab that is loaded',
    () async {
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
      when(
        () => outgoing(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

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
    },
  );

  test('refresh on matches tab delegates to loadMatches', () async {
    when(() => getMatches()).thenAnswer(
      (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
    );

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
    test(
      'success → emits acceptSuccess, reloads incoming, invalidates matches',
      () async {
        when(() => accept(42)).thenAnswer(
          (_) async => const Right<Failure, LikeActionOutcome>(
            LikeActionSuccess(serverMessage: 'تم القبول'),
          ),
        );
        when(() => incoming()).thenAnswer(
          (_) async => const Right<Failure, LikeRequestsData>(_empty),
        );

        await cubit.acceptLike(42);

        expect(cubit.state.actionEvent, LikesActionEvent.acceptSuccess);
        expect(
          cubit.state.matchesStatus,
          LikesAsyncStatus.initial,
          reason: 'matches slot is invalidated so next visit refetches',
        );
        verify(() => accept(42)).called(1);
        verify(() => incoming()).called(1);
      },
    );

    test(
      'requiresSubscription → paywall event, NO refresh, NO invalidation',
      () async {
        when(() => accept(7)).thenAnswer(
          (_) async => const Right<Failure, LikeActionOutcome>(
            LikeActionRequiresSubscription(
              serverMessage: 'الاشتراك مطلوب لقبول الإعجابات',
            ),
          ),
        );

        await cubit.acceptLike(7);

        expect(
          cubit.state.actionEvent,
          LikesActionEvent.acceptRequiresSubscription,
        );
        verifyNever(() => incoming());
      },
    );

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, LikeActionOutcome>>();
      when(() => accept(5)).thenAnswer((_) => gate.future);
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

      final first = cubit.acceptLike(5);
      expect(cubit.state.isAccepting(5), isTrue);
      final second = cubit.acceptLike(5);
      await second;
      gate.complete(
        const Right<Failure, LikeActionOutcome>(
          LikeActionSuccess(serverMessage: 'ok'),
        ),
      );
      await first;

      verify(() => accept(5)).called(1);
    });
  });

  group('rejectLike', () {
    test('success → emits rejectSuccess + refresh', () async {
      when(() => reject(42)).thenAnswer(
        (_) async => const Right<Failure, LikeActionOutcome>(
          LikeActionSuccess(serverMessage: 'تم الرفض'),
        ),
      );
      when(
        () => incoming(),
      ).thenAnswer((_) async => const Right<Failure, LikeRequestsData>(_empty));

      await cubit.rejectLike(42);

      expect(cubit.state.actionEvent, LikesActionEvent.rejectSuccess);
      verify(() => incoming()).called(1);
    });
  });

  group('requestPhotoExchange', () {
    test('success → emits success event + loadMatches refresh', () async {
      when(() => requestPx(10)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestSuccess(requestId: 7, serverMessage: ''),
        ),
      );
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.requestPhotoExchange(10);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRequestSuccess,
      );
      verify(() => requestPx(10)).called(1);
      verify(() => getMatches()).called(1);
    });

    test('alreadyPending → event + refresh', () async {
      when(() => requestPx(11)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestAlreadyPending(serverMessage: ''),
        ),
      );
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.requestPhotoExchange(11);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRequestAlreadyPending,
      );
      verify(() => getMatches()).called(1);
    });

    test('requiresSubscription → paywall event, NO refresh', () async {
      when(() => requestPx(12)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestRequiresSubscription(serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(12);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRequestRequiresSubscription,
      );
      verifyNever(() => getMatches());
    });

    test('limitReached → limit-reached event, NO refresh', () async {
      when(() => requestPx(14)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRequestOutcome>(
          PhotoExchangeRequestLimitReached(serverMessage: ''),
        ),
      );

      await cubit.requestPhotoExchange(14);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRequestLimitReached,
      );
      verifyNever(() => getMatches());
    });

    test('transport failure → failure event, NO refresh', () async {
      when(() => requestPx(13)).thenAnswer(
        (_) async => const Left<Failure, PhotoExchangeRequestOutcome>(
          ServerFailure(message: 'errors.generic'),
        ),
      );

      await cubit.requestPhotoExchange(13);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRequestFailure,
      );
      verifyNever(() => getMatches());
    });

    test('rapid duplicate taps while in-flight → ignored', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRequestOutcome>>();
      when(() => requestPx(20)).thenAnswer((_) => gate.future);
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      final first = cubit.requestPhotoExchange(20);
      expect(cubit.state.isPhotoExchangeRequesting(20), isTrue);
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
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.acceptPhotoExchange(30);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeAcceptSuccess,
      );
      verify(() => getMatches()).called(1);
    });

    test('expired → respondExpired event + refresh', () async {
      when(() => acceptPx(31)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondExpired(serverMessage: ''),
        ),
      );
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.acceptPhotoExchange(31);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRespondExpired,
      );
      verify(() => getMatches()).called(1);
    });

    test('rapid duplicate taps blocked while accept is in flight', () async {
      final gate = Completer<Either<Failure, PhotoExchangeRespondOutcome>>();
      when(() => acceptPx(40)).thenAnswer((_) => gate.future);
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      final first = cubit.acceptPhotoExchange(40);
      expect(cubit.state.isPhotoExchangeAccepting(40), isTrue);
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
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.rejectPhotoExchange(50);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRejectSuccess,
      );
      verify(() => getMatches()).called(1);
    });

    test('notFound → respondNotFound event + refresh', () async {
      when(() => rejectPx(51)).thenAnswer(
        (_) async => const Right<Failure, PhotoExchangeRespondOutcome>(
          PhotoExchangeRespondNotFound(serverMessage: ''),
        ),
      );
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

      await cubit.rejectPhotoExchange(51);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRespondNotFound,
      );
      verify(() => getMatches()).called(1);
    });

    test('transport failure → respondFailure, NO refresh', () async {
      when(() => rejectPx(52)).thenAnswer(
        (_) async => const Left<Failure, PhotoExchangeRespondOutcome>(
          ServerFailure(message: 'errors.generic'),
        ),
      );

      await cubit.rejectPhotoExchange(52);

      expect(
        cubit.state.actionEvent,
        LikesActionEvent.photoExchangeRespondFailure,
      );
      verifyNever(() => getMatches());
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

  group('matchmaker profile + message flow', () {
    test(
      'stage-0 inquiry resolves missing conversation then shares and texts',
      () async {
        when(() => getMyMatchmaker()).thenAnswer(
          (_) async => const Right<Failure, MyMatchmakerOutcome>(
            MyMatchmakerAssigned(
              info: MatchmakerInfo(
                matchmakerId: 'matchmaker-id',
                name: 'Matchmaker',
                profileImageUrl: null,
                conversationId: 17,
              ),
            ),
          ),
        );
        when(
          () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
        ).thenAnswer(
          (_) async => Right<Failure, ShareProfileOutcome>(
            ShareProfileSuccess(message: _MockChatMessage()),
          ),
        );
        when(() => sendText(conversationId: 17, content: 'inquiry')).thenAnswer(
          (_) async => Right<Failure, SendTextOutcome>(
            SendTextSuccess(message: _MockChatMessage()),
          ),
        );

        await cubit.sendInquiry(_stageZeroMatch, 'inquiry');

        expect(cubit.state.actionEvent, LikesActionEvent.inquirySuccess);
        expect(cubit.state.isInquirySent(42), isTrue);
        verify(
          () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
        ).called(1);
        verify(
          () => sendText(conversationId: 17, content: 'inquiry'),
        ).called(1);
      },
    );

    // The sent button stays tappable on purpose, so this path is now
    // reachable from the UI rather than dead code. It must NOT post a second
    // copy of the same message — the screen reads `inquiryAlreadySent` the
    // same way it reads success, and opens the chat.
    test('a second tap opens the chat instead of sending again', () async {
      when(() => getMyMatchmaker()).thenAnswer(
        (_) async => const Right<Failure, MyMatchmakerOutcome>(
          MyMatchmakerAssigned(
            info: MatchmakerInfo(
              matchmakerId: 'matchmaker-id',
              name: 'Matchmaker',
              profileImageUrl: null,
              conversationId: 17,
            ),
          ),
        ),
      );
      when(
        () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
      ).thenAnswer(
        (_) async => Right<Failure, ShareProfileOutcome>(
          ShareProfileSuccess(message: _MockChatMessage()),
        ),
      );
      when(() => sendText(conversationId: 17, content: 'inquiry')).thenAnswer(
        (_) async => Right<Failure, SendTextOutcome>(
          SendTextSuccess(message: _MockChatMessage()),
        ),
      );

      await cubit.sendInquiry(_stageZeroMatch, 'inquiry');
      await cubit.sendInquiry(_stageZeroMatch, 'inquiry');

      expect(cubit.state.actionEvent, LikesActionEvent.inquiryAlreadySent);
      verify(
        () => sendText(conversationId: 17, content: 'inquiry'),
      ).called(1);
    });
  });

  group('sendFormalStep', () {
    void serverSays(FormalStepRequestOutcome outcome) {
      when(() => requestFormal(43)).thenAnswer(
        (_) async => Right<Failure, FormalStepRequestOutcome>(outcome),
      );
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );
    }

    // The removal that defines this method: asking the other member to begin
    // the formal step tells the MATCHMAKER nothing, because she has no role
    // until they approve. It used to post a profile card and a text to her.
    test('shares nothing into the matchmaker chat', () async {
      serverSays(
        const FormalStepRequestSuccess(requestId: 9, serverMessage: ''),
      );

      await cubit.sendFormalStep(43);

      expect(cubit.state.actionEvent, LikesActionEvent.formalStepSuccess);
      verifyNever(() => getMyMatchmaker());
      verifyNever(
        () => shareProfile(
          conversationId: any(named: 'conversationId'),
          sharedUserId: any(named: 'sharedUserId'),
        ),
      );
      verifyNever(
        () => sendText(
          conversationId: any(named: 'conversationId'),
          content: any(named: 'content'),
        ),
      );
    });

    const outcomes = <FormalStepRequestOutcome, LikesActionEvent>{
      FormalStepRequestSuccess(requestId: null, serverMessage: ''):
          LikesActionEvent.formalStepSuccess,
      FormalStepRequestAlreadyPending(serverMessage: ''):
          LikesActionEvent.formalStepAlreadyPending,
      FormalStepRequestNotAllowed(serverMessage: ''):
          LikesActionEvent.formalStepNotAllowed,
      FormalStepRequestCaseEnded(serverMessage: ''):
          LikesActionEvent.formalStepCaseEnded,
      FormalStepRequestProfileUnderReview(serverMessage: ''):
          LikesActionEvent.formalStepUnderReview,
      FormalStepRequestFailure(serverMessage: '', errorCode: null):
          LikesActionEvent.formalStepFailure,
    };

    test('every outcome reaches an event of its own', () {
      expect(outcomes.values.toSet().length, outcomes.length);
    });

    for (final entry in outcomes.entries) {
      test('${entry.key.runtimeType} reports ${entry.value.name}', () async {
        serverSays(entry.key);

        await cubit.sendFormalStep(43);

        expect(cubit.state.actionEvent, entry.value);
      });
    }

    // Every REFUSAL means the card acted on a stale view, so the list is
    // refetched for those too, not only on success. Under-review and a
    // transport failure say nothing about the case, so they leave it alone.
    test('refreshes on success and on every refusal, not on the rest', () async {
      const refresh = {
        LikesActionEvent.formalStepSuccess,
        LikesActionEvent.formalStepAlreadyPending,
        LikesActionEvent.formalStepNotAllowed,
        LikesActionEvent.formalStepCaseEnded,
      };
      for (final entry in outcomes.entries) {
        serverSays(entry.key);
        await cubit.sendFormalStep(43);

        // verify() throws rather than reporting zero when nothing matched,
        // so the two cases have to be asked differently.
        if (refresh.contains(entry.value)) {
          verify(() => getMatches()).called(1);
        } else {
          verifyNever(() => getMatches());
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

      expect(cubit.state.actionEvent, LikesActionEvent.formalStepFailure);
      verifyNever(() => getMatches());
    });

    // The pre-gate exists so an unapproved member does not spend a round trip
    // learning what the app already knows.
    test('an unapproved profile never reaches the server', () async {
      when(() => profileGate.isGated).thenReturn(true);

      await cubit.sendFormalStep(43);

      expect(cubit.state.actionEvent, LikesActionEvent.formalStepUnderReview);
      verifyNever(() => requestFormal(any()));
    });

    test('a second tap while the first is in flight is dropped', () async {
      final gate = Completer<Either<Failure, FormalStepRequestOutcome>>();
      when(() => requestFormal(43)).thenAnswer((_) => gate.future);
      when(() => getMatches()).thenAnswer(
        (_) async => const Right<Failure, List<MatchCard>>(_noMatches),
      );

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

    // Cards rebuild on every matches refresh; re-reporting the card that is
    // already open must not emit and churn the list.
    test('re-opening the same card emits nothing', () async {
      cubit.openJourney(1);
      final emissions = <LikesState>[];
      final sub = cubit.stream.listen(emissions.add);

      cubit.openJourney(1);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, isEmpty);
    });

    test('closing when nothing is open emits nothing', () async {
      final emissions = <LikesState>[];
      final sub = cubit.stream.listen(emissions.add);

      cubit.openJourney(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, isEmpty);
    });
  });
}
