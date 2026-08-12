import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_editable_answers_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_user_actions_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_image_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/reject_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/request_image_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/update_text_answer_usecase.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_answer_save_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_answer_save_state.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_user_actions_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_user_actions_state.dart';

const _unauthorized = CodedServerFailure(
  message: 'not assigned',
  errorCode: 'UNAUTHORIZED',
);

class _FailingAnswersRepository implements MatchmakerEditableAnswersRepository {
  @override
  Future<Either<Failure, String>> updateTextAnswer({
    required String userId,
    required int questionId,
    required String textAnswer,
  }) async => const Left(_unauthorized);
}

class _FailingActionsRepository implements MatchmakerUserActionsRepository {
  @override
  Future<Either<Failure, String>> approveImage({
    required String userId,
    required String imageId,
  }) async => const Left(_unauthorized);

  @override
  Future<Either<Failure, String>> approve(String userId) async =>
      const Left(_unauthorized);

  @override
  Future<Either<Failure, String>> reject({
    required String userId,
    required String reason,
  }) async => const Left(_unauthorized);

  @override
  Future<Either<Failure, String>> requestImage(String userId) async =>
      const Left(_unauthorized);
}

void main() {
  test('text-answer save classifies UNAUTHORIZED', () async {
    final cubit = MatchmakerAnswerSaveCubit(
      userId: 'u1',
      updateTextAnswer: UpdateTextAnswerUseCase(_FailingAnswersRepository()),
    );

    await cubit.save(questionId: 2, textAnswer: 'answer');

    expect(cubit.state.outcome, AnswerSaveOutcome.failure);
    expect(cubit.state.errorKind, AnswerSaveErrorKind.unauthorized);
    expect(cubit.state.inFlightQuestionId, isNull);
    await cubit.close();
  });

  test('request-image classifies UNAUTHORIZED', () async {
    final repository = _FailingActionsRepository();
    final cubit = MatchmakerUserActionsCubit(
      userId: 'u1',
      approve: ApproveUserUseCase(repository),
      reject: RejectUserUseCase(repository),
      requestImage: RequestImageUserUseCase(repository),
      approveImage: ApproveUserImageUseCase(repository),
    );

    await cubit.requestImage();

    expect(cubit.state.outcome, MatchmakerActionOutcome.failure);
    expect(cubit.state.errorKind, MatchmakerActionErrorKind.unauthorized);
    expect(cubit.state.inFlight, isNull);
    await cubit.close();
  });

  test(
    'approve-image classifies UNAUTHORIZED and clears image progress',
    () async {
      final repository = _FailingActionsRepository();
      final cubit = MatchmakerUserActionsCubit(
        userId: 'u1',
        approve: ApproveUserUseCase(repository),
        reject: RejectUserUseCase(repository),
        requestImage: RequestImageUserUseCase(repository),
        approveImage: ApproveUserImageUseCase(repository),
      );

      await cubit.approveImage('image-7');

      expect(cubit.state.outcome, MatchmakerActionOutcome.failure);
      expect(cubit.state.errorKind, MatchmakerActionErrorKind.unauthorized);
      expect(cubit.state.inFlight, isNull);
      expect(cubit.state.inFlightImageId, isNull);
      await cubit.close();
    },
  );
}
