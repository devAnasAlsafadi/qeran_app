import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/block/di/block_injection.dart';
import 'package:qeran/features/block/domain/repositories/community_member_blocker.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _FakeCommunity implements CommunityMemberBlocker {
  final blocked = <String>[];

  @override
  Future<Either<Failure, void>> block(String userId) async {
    blocked.add(userId);
    return const Right(null);
  }
}

/// Q3: a comment's Block goes through Community — whose dev-flag mock
/// answers in memory — never through the block feature's own `POST block`.
void main() {
  late _MockApiConsumer api;
  late _FakeCommunity community;

  setUp(() {
    api = _MockApiConsumer();
    community = _FakeCommunity();
    sl.registerSingleton<ApiConsumer>(api);
    sl.registerSingleton<CommunityMemberBlocker>(community);
    initBlockDependencies();
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {'status': 1, 'message': '', 'data': null});
  });
  tearDown(sl.reset);

  test('from Community: through Community, never this feature', () async {
    await sl<BlockActionCubit>(param1: BlockOrigin.community).block('u-5');

    expect(community.blocked, ['u-5']);
    verifyNever(() => api.post(any(), body: any(named: 'body')));
  });

  test('from a profile: POST block, as before', () async {
    await sl<BlockActionCubit>(param1: BlockOrigin.profile).block('u-5');

    verify(() => api.post('block', body: {'targetUserId': 'u-5'})).called(1);
    expect(community.blocked, isEmpty);
  });
}
