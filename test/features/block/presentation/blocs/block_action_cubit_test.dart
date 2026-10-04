import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// One block, through whichever call its origin was given (Q3). Gone and
/// blocked read the same — the app never tells them apart.
void main() {
  final blocked = <String>[];
  late Either<Failure, void> answer;
  late BlockActionCubit cubit;

  setUp(() {
    blocked.clear();
    answer = const Right(null);
    cubit = BlockActionCubit(
      block: (id) async {
        blocked.add(id);
        return answer;
      },
    );
  });
  tearDown(() => cubit.close());

  test('blocked: the caller removes them, with the block toast', () async {
    await cubit.block('u-5');

    expect(blocked, ['u-5']);
    expect(cubit.state.outcome, BlockActionOutcome.success);
    expect(cubit.state.blockedUserId, 'u-5');
    expect(cubit.state.messageKey, LocaleKeys.block_success);
  });

  test('TARGET_USER_NOT_FOUND removes them too, neutrally', () async {
    answer = const Left(
      CodedServerFailure(message: 'x', errorCode: 'TARGET_USER_NOT_FOUND'),
    );

    await cubit.block('u-5');

    expect(cubit.state.outcome, BlockActionOutcome.success);
    expect(cubit.state.blockedUserId, 'u-5');
    expect(cubit.state.messageKey, LocaleKeys.block_user_unavailable);
  });

  test('any other failure: nothing removed, a generic error', () async {
    answer = const Left(OfflineFailure());

    await cubit.block('u-5');

    expect(cubit.state.outcome, BlockActionOutcome.failure);
    expect(cubit.state.blockedUserId, isNull);
    expect(cubit.state.messageKey, LocaleKeys.errors_generic);
  });

  test('a second tap while blocking blocks nobody more', () async {
    final pending = Completer<Either<Failure, void>>();
    final slow = BlockActionCubit(
      block: (id) {
        blocked.add(id);
        return pending.future;
      },
    );
    addTearDown(slow.close);

    final first = slow.block('u-5');
    await slow.block('u-5');
    pending.complete(const Right(null));
    await first;

    expect(blocked, ['u-5']);
  });
}
