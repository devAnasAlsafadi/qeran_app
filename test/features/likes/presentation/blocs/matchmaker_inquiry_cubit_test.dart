import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/blocs/matchmaker_inquiry_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/matchmaker_inquiry_state.dart';

/// The stage-0 inquiry, moved here with the flow when it left `LikesCubit`.
///
/// These are the same assertions that ran inside the likes cubit's suite; only
/// the cubit under test and the names of its outcomes changed. Nothing about
/// what an inquiry does was re-decided by the move.

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

class _MockShareProfile extends Mock implements ShareProfileUseCase {}

class _MockSendText extends Mock implements SendTextMessageUseCase {}

class _MockChatMessage extends Mock implements ChatMessage {}

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
  late _MockGetMyMatchmaker getMyMatchmaker;
  late _MockShareProfile shareProfile;
  late _MockSendText sendText;
  late MatchmakerInquiryCubit cubit;

  setUp(() {
    getMyMatchmaker = _MockGetMyMatchmaker();
    shareProfile = _MockShareProfile();
    sendText = _MockSendText();
    cubit = MatchmakerInquiryCubit(
      getMyMatchmaker: getMyMatchmaker,
      shareProfile: shareProfile,
      sendText: sendText,
    );
  });

  tearDown(() => cubit.close());

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

      await cubit.send(_stageZeroMatch, 'inquiry');

      expect(cubit.state.event, InquiryEvent.success);
      expect(cubit.state.isSent(42), isTrue);
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

    await cubit.send(_stageZeroMatch, 'inquiry');
    await cubit.send(_stageZeroMatch, 'inquiry');

    expect(cubit.state.event, InquiryEvent.alreadySent);
    verify(
      () => sendText(conversationId: 17, content: 'inquiry'),
    ).called(1);
  });

  // ── Guards on what this step newly wrote ─────────────────────────────────
  //
  // The state class, its props and the event mapping are new code, not moved
  // code, and mutation testing found all four of these unprotected.

  void resolvesTo(int conversationId) {
    when(() => getMyMatchmaker()).thenAnswer(
      (_) async => Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(
          info: MatchmakerInfo(
            matchmakerId: 'm',
            name: 'M',
            profileImageUrl: null,
            conversationId: conversationId,
          ),
        ),
      ),
    );
  }

  test('a failed share reports failure, not success', () async {
    resolvesTo(17);
    when(
      () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
    ).thenAnswer(
      (_) async => const Left<Failure, ShareProfileOutcome>(
        ServerFailure(message: 'nope'),
      ),
    );

    await cubit.send(_stageZeroMatch, 'inquiry');

    expect(cubit.state.event, InquiryEvent.failure);
    // And it must NOT be remembered as sent, or the member could never retry.
    expect(cubit.state.isSent(42), isFalse);
    verifyNever(
      () => sendText(
        conversationId: any(named: 'conversationId'),
        content: any(named: 'content'),
      ),
    );
  });

  // The comment on that branch says a rate limit means the same profile was
  // shared recently and the accompanying text is still required. A documented
  // decision with no test behind it is one refactor from being "simplified"
  // into treating a rate limit as a failure.
  test('a rate-limited share still sends the inquiry text', () async {
    resolvesTo(17);
    when(
      () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
    ).thenAnswer(
      (_) async => const Right<Failure, ShareProfileOutcome>(
        ShareProfileRateLimited(serverMessage: ''),
      ),
    );
    when(() => sendText(conversationId: 17, content: 'inquiry')).thenAnswer(
      (_) async =>
          Right<Failure, SendTextOutcome>(SendTextSuccess(message: _MockChatMessage())),
    );

    await cubit.send(_stageZeroMatch, 'inquiry');

    verify(() => sendText(conversationId: 17, content: 'inquiry')).called(1);
    expect(cubit.state.event, InquiryEvent.success);
  });

  test('a second send while one is in flight is dropped', () async {
    resolvesTo(17);
    final gate = Completer<Either<Failure, ShareProfileOutcome>>();
    when(
      () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
    ).thenAnswer((_) => gate.future);
    when(() => sendText(conversationId: 17, content: 'inquiry')).thenAnswer(
      (_) async =>
          Right<Failure, SendTextOutcome>(SendTextSuccess(message: _MockChatMessage())),
    );

    final first = cubit.send(_stageZeroMatch, 'inquiry');
    await Future<void>.delayed(Duration.zero);
    final second = cubit.send(_stageZeroMatch, 'inquiry');
    gate.complete(
      Right<Failure, ShareProfileOutcome>(
        ShareProfileSuccess(message: _MockChatMessage()),
      ),
    );
    await Future.wait([first, second]);

    verify(
      () => shareProfile(conversationId: 17, sharedUserId: 'candidate-id'),
    ).called(1);
  });

  // Both id sets must take part in equality. Cubit DROPS an emit whose state
  // compares equal to the last one, so a set left out of `props` leaves the
  // button without its spinner while `state` still reads correctly to anyone
  // inspecting it directly.
  //
  // Asserted on the state class rather than through the cubit on purpose: this
  // is a property of `props`, and checking it by watching emits would also be
  // measuring Cubit's first-emit exemption and the mock plumbing around it.
  test('both id sets take part in equality', () {
    const base = MatchmakerInquiryState();
    expect(base.copyWith(inFlightLikeIds: const {1}), isNot(base));
    expect(base.copyWith(sentLikeIds: const {1}), isNot(base));
    expect(base.copyWith(event: InquiryEvent.failure), isNot(base));
    expect(base.copyWith(eventVersion: 1), isNot(base));
  });
}
