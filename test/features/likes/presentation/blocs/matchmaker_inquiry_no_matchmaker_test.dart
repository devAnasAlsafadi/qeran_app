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

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

class _MockShareProfile extends Mock implements ShareProfileUseCase {}

class _MockSendText extends Mock implements SendTextMessageUseCase {}

class _MockChatMessage extends Mock implements ChatMessage {}

MatchCard _card({String? conversationId}) => MatchCard(
  likeRequestId: 42,
  otherUserId: 'candidate-id',
  otherUserName: 'Candidate',
  images: const [],
  stage: MatchStage.waitingForPhotoExchange,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: conversationId,
);

/// An inquiry with no one to ask — never assigned, or hers was deleted — is
/// the calm «جاري تعيين خطّابتك», not an error; both cases the same.
void main() {
  late _MockGetMyMatchmaker getMyMatchmaker;
  late _MockShareProfile shareProfile;
  late _MockSendText sendText;
  late MatchmakerInquiryCubit cubit;

  void serverSays(MyMatchmakerOutcome outcome) => when(
    () => getMyMatchmaker(),
  ).thenAnswer((_) async => Right<Failure, MyMatchmakerOutcome>(outcome));

  void sharesInto(int conversationId, {required bool ok}) =>
      when(
        () => shareProfile(
          conversationId: conversationId,
          sharedUserId: 'candidate-id',
        ),
      ).thenAnswer(
        (_) async => ok
            ? Right<Failure, ShareProfileOutcome>(
                ShareProfileSuccess(message: _MockChatMessage()),
              )
            : const Right<Failure, ShareProfileOutcome>(
                ShareProfileConversationNotFound(serverMessage: ''),
              ),
      );

  setUp(() {
    getMyMatchmaker = _MockGetMyMatchmaker();
    shareProfile = _MockShareProfile();
    sendText = _MockSendText();
    when(
      () => sendText(
        conversationId: any(named: 'conversationId'),
        content: any(named: 'content'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, SendTextOutcome>(
        SendTextSuccess(message: _MockChatMessage()),
      ),
    );
    cubit = MatchmakerInquiryCubit(
      getMyMatchmaker: getMyMatchmaker,
      shareProfile: shareProfile,
      sendText: sendText,
    );
  });

  tearDown(() => cubit.close());

  test('no conversation on the card, none assigned: the calm notice', () async {
    serverSays(const MyMatchmakerNotAssigned(serverMessage: ''));

    await cubit.send(_card(), 'inquiry');

    expect(cubit.state.event, InquiryEvent.noMatchmaker);
    expect(cubit.state.isSent(42), isFalse);
    verifyNever(
      () => shareProfile(
        conversationId: any(named: 'conversationId'),
        sharedUserId: any(named: 'sharedUserId'),
      ),
    );
  });

  test(
    'a card naming a deleted matchmaker\'s conversation: the same notice',
    () async {
      sharesInto(9, ok: false);
      serverSays(const MyMatchmakerNotAssigned(serverMessage: ''));

      await cubit.send(_card(conversationId: '9'), 'inquiry');

      expect(cubit.state.event, InquiryEvent.noMatchmaker);
    },
  );

  // The look-up only asks whether anyone is there; it never moves the
  // inquiry into another conversation the card didn't name.
  test('a failed share with her still there stays a failure', () async {
    sharesInto(9, ok: false);
    serverSays(
      const MyMatchmakerAssigned(
        info: MatchmakerInfo(
          matchmakerId: 'm',
          name: 'M',
          profileImageUrl: null,
          conversationId: 12,
        ),
      ),
    );

    await cubit.send(_card(conversationId: '9'), 'inquiry');

    expect(cubit.state.event, InquiryEvent.failure);
    verifyNever(
      () => shareProfile(conversationId: 12, sharedUserId: 'candidate-id'),
    );
  });

  test('a card that shares fine never asks who her matchmaker is', () async {
    sharesInto(9, ok: true);

    await cubit.send(_card(conversationId: '9'), 'inquiry');

    expect(cubit.state.event, InquiryEvent.success);
    verifyNever(() => getMyMatchmaker());
  });

  test('a look-up that fails is a failure, not the calm notice', () async {
    when(() => getMyMatchmaker()).thenAnswer(
      (_) async =>
          const Left<Failure, MyMatchmakerOutcome>(ServerFailure(message: 'x')),
    );

    await cubit.send(_card(), 'inquiry');

    expect(cubit.state.event, InquiryEvent.failure);
  });
}
