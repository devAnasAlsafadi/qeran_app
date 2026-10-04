import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_documents.dart';
import 'package:qeran/features/community/data/models/community_guidelines_model.dart';
import 'package:qeran/features/community/domain/entities/community_guidelines.dart';
import 'package:qeran/features/community/domain/entities/guidelines_acceptance.dart';
import 'package:qeran/features/community/domain/usecases/accept_community_guidelines_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_community_guidelines_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/guidelines/community_guidelines_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/guidelines/community_guidelines_state.dart';

class _MockGet extends Mock implements GetCommunityGuidelinesUseCase {}

class _MockAccept extends Mock implements AcceptCommunityGuidelinesUseCase {}

/// The seed's text at [version].
CommunityGuidelines guidelinesAt(int version) =>
    CommunityGuidelinesModel.fromJson({
      ...communityMockGuidelines(),
      'version': version,
    }).toEntity();

/// The guidelines step (D7, F5, W3).
void main() {
  late _MockGet getGuidelines;
  late _MockAccept accept;
  late int acceptedCalls;
  late CommunityGuidelinesCubit cubit;

  setUp(() {
    getGuidelines = _MockGet();
    accept = _MockAccept();
    acceptedCalls = 0;
    cubit = CommunityGuidelinesCubit(
      getGuidelines: getGuidelines,
      accept: accept,
      onAccepted: () => acceptedCalls++,
    );
  });

  tearDown(() => cubit.close());

  void reads(List<Either<Failure, CommunityGuidelines>> answers) =>
      when(() => getGuidelines()).thenAnswer((_) async => answers.removeAt(0));

  test('the text arrives, and only then can it be agreed to', () async {
    reads([Right(guidelinesAt(1))]);
    expect(cubit.state.canAccept, isFalse);

    await cubit.load();

    expect(cubit.state.status, CommunityGuidelinesStatus.ready);
    expect(cubit.state.guidelines!.sections, hasLength(5));
    expect(cubit.state.canAccept, isTrue);
  });

  test('a failed read can be tried again', () async {
    reads([const Left(OfflineFailure()), Right(guidelinesAt(1))]);

    await cubit.load();
    expect(cubit.state.status, CommunityGuidelinesStatus.failed);
    expect(cubit.state.canAccept, isFalse);

    await cubit.load();
    expect(cubit.state.status, CommunityGuidelinesStatus.ready);
  });

  test('agreeing sends the version read, and tells the app', () async {
    reads([Right(guidelinesAt(3))]);
    when(
      () => accept(3),
    ).thenAnswer((_) async => const Right(GuidelinesAcceptance.accepted));
    await cubit.load();

    await cubit.accept();

    verify(() => accept(3)).called(1);
    expect(acceptedCalls, 1);
    expect(cubit.state.event, CommunityGuidelinesEvent.accepted);
    // Still "accepting" while the step closes: no second send.
    expect(cubit.state.canAccept, isFalse);
    await cubit.accept();
    verifyNever(() => accept(any()));
  });

  test('a failed agreement says so, and can be sent again', () async {
    reads([Right(guidelinesAt(1))]);
    when(() => accept(1)).thenAnswer((_) async => const Left(OfflineFailure()));
    await cubit.load();

    await cubit.accept();

    expect(cubit.state.event, CommunityGuidelinesEvent.acceptFailed);
    expect(cubit.state.canAccept, isTrue);
    expect(acceptedCalls, 0);
  });

  test('text changed meanwhile: the new one is shown, and asked '
      'again (W3)', () async {
    reads([Right(guidelinesAt(1)), Right(guidelinesAt(2))]);
    when(
      () => accept(1),
    ).thenAnswer((_) async => const Right(GuidelinesAcceptance.outdated));
    await cubit.load();

    await cubit.accept();

    expect(cubit.state.guidelines!.version, 2);
    expect(cubit.state.canAccept, isTrue);
    expect(cubit.state.event, CommunityGuidelinesEvent.none);
    expect(acceptedCalls, 0);
  });
}
