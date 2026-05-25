import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_state.dart';

class _MockGetMm extends Mock implements GetMyMatchmakerUseCase {}

class _MockShare extends Mock implements ShareProfileUseCase {}

const _info = MatchmakerInfo(
  matchmakerId: 'mm',
  name: 'أم محمد',
  profileImageUrl: null,
  conversationId: 42,
);

final _msg = ChatMessage(
  serverId: 1,
  clientTempId: null,
  conversationId: 42,
  senderId: 'me',
  senderName: 'Me',
  content: '[profile:x]',
  sharedProfile: null,
  isRead: false,
  sentAt: DateTime.now(),
  status: MessageSendStatus.sent,
);

void main() {
  late _MockGetMm getMm;
  late _MockShare share;
  late ShareWithMatchmakerCubit cubit;

  setUp(() {
    getMm = _MockGetMm();
    share = _MockShare();
    cubit = ShareWithMatchmakerCubit(
      getMyMatchmaker: getMm,
      shareProfile: share,
    );
  });

  tearDown(() => cubit.close());

  test('initial state is unresolved + no matchmaker', () {
    expect(cubit.state.resolved, isFalse);
    expect(cubit.state.hasMatchmaker, isFalse);
  });

  test('resolveMatchmaker assigned → ready with conversationId', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    await cubit.resolveMatchmaker();
    expect(cubit.state.resolved, isTrue);
    expect(cubit.state.conversationId, 42);
    expect(cubit.state.hasMatchmaker, isTrue);
  });

  test('resolveMatchmaker not-assigned → resolved with null id', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerNotAssigned(serverMessage: 'no'),
      ),
    );
    await cubit.resolveMatchmaker();
    expect(cubit.state.resolved, isTrue);
    expect(cubit.state.hasMatchmaker, isFalse);
  });

  test('share without matchmaker fires noMatchmaker event', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerNotAssigned(serverMessage: 'no'),
      ),
    );
    await cubit.resolveMatchmaker();
    await cubit.share('peer-id');
    expect(cubit.state.event, ShareEvent.noMatchmaker);
    expect(cubit.state.eventVersion, 1);
  });

  test('share success → success event + isSharing false', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    when(() => share(conversationId: 42, sharedUserId: 'peer-id'))
        .thenAnswer(
      (_) async => Right<Failure, ShareProfileOutcome>(
        ShareProfileSuccess(message: _msg),
      ),
    );
    await cubit.resolveMatchmaker();
    await cubit.share('peer-id');
    expect(cubit.state.event, ShareEvent.success);
    expect(cubit.state.isSharing, isFalse);
  });

  test('share rate-limited surfaces rateLimited event', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    when(() => share(conversationId: 42, sharedUserId: 'peer-id'))
        .thenAnswer(
      (_) async => const Right<Failure, ShareProfileOutcome>(
        ShareProfileRateLimited(serverMessage: '429'),
      ),
    );
    await cubit.resolveMatchmaker();
    await cubit.share('peer-id');
    expect(cubit.state.event, ShareEvent.rateLimited);
  });

  test('share transport failure → failure event', () async {
    when(() => getMm()).thenAnswer(
      (_) async => const Right<Failure, MyMatchmakerOutcome>(
        MyMatchmakerAssigned(info: _info),
      ),
    );
    when(() => share(conversationId: 42, sharedUserId: 'peer-id'))
        .thenAnswer(
      (_) async => const Left<Failure, ShareProfileOutcome>(
        ServerFailure(message: 'errors.timeout'),
      ),
    );
    await cubit.resolveMatchmaker();
    await cubit.share('peer-id');
    expect(cubit.state.event, ShareEvent.failure);
  });
}
