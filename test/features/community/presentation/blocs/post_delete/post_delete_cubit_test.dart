import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/usecases/delete_community_post_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/post_delete/post_delete_cubit.dart';

class _MockDelete extends Mock implements DeleteCommunityPostUseCase {}

void main() {
  late _MockDelete delete;
  late PostDeleteCubit cubit;
  setUp(() {
    delete = _MockDelete();
    cubit = PostDeleteCubit(deletePost: delete);
  });
  tearDown(() => cubit.close());

  test('deleting, then deleted: her post is leaving the whole time', () async {
    final answer = Completer<Either<Failure, Unit>>();
    when(() => delete(5)).thenAnswer((_) => answer.future);

    final deleting = cubit.delete(5);
    expect(cubit.state.status, PostDeleteStatus.deleting);
    expect(cubit.state.leaving, isTrue);
    answer.complete(const Right(unit));
    await deleting;

    expect(cubit.state.status, PostDeleteStatus.deleted);
    expect(cubit.state.leaving, isTrue);
  });

  test('a second tap while one is on its way sends nothing more', () async {
    final answer = Completer<Either<Failure, Unit>>();
    when(() => delete(5)).thenAnswer((_) => answer.future);

    final first = cubit.delete(5);
    await cubit.delete(5);
    answer.complete(const Right(unit));
    await first;

    verify(() => delete(5)).called(1);
  });

  test('two failures in a row are two answers, so each is said', () async {
    when(() => delete(5)).thenAnswer((_) async => const Left(OfflineFailure()));

    await cubit.delete(5);
    final first = cubit.state;
    await cubit.delete(5);

    expect(cubit.state.status, PostDeleteStatus.failed);
    expect(cubit.state.leaving, isFalse);
    expect(cubit.state, isNot(first));
  });
}
