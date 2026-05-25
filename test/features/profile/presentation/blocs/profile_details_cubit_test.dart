import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/profile/domain/entities/other_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_fetch_outcome.dart';
import 'package:qeran/features/profile/domain/usecases/get_profile_by_id_usecase.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_details/profile_details_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_details/profile_details_state.dart';

class _MockGetProfileById extends Mock implements GetProfileByIdUseCase {}

const _seed = OtherProfile(
  id: 'guid',
  name: 'Noor',
  age: null,
  matchingScore: 0,
  images: [],
  placements: [],
);

const _hydrated = OtherProfile(
  id: 'guid',
  name: 'Noor',
  age: 27,
  matchingScore: 78.5,
  images: [],
  placements: [],
);

void main() {
  late _MockGetProfileById uc;
  late ProfileDetailsCubit cubit;

  setUp(() {
    uc = _MockGetProfileById();
    cubit = ProfileDetailsCubit(getProfileById: uc);
  });

  tearDown(() => cubit.close());

  test('initial state is ProfileDetailsInitial', () {
    expect(cubit.state, isA<ProfileDetailsInitial>());
  });

  test('init with seed → Loaded with hydrated profile', () async {
    when(() => uc('guid')).thenAnswer(
      (_) async => const Right<Failure, ProfileFetchOutcome>(
        ProfileFetched(_hydrated),
      ),
    );
    await cubit.init(userId: 'guid', seed: _seed);
    expect(cubit.state, isA<ProfileDetailsLoaded>());
    expect((cubit.state as ProfileDetailsLoaded).profile.age, 27);
  });

  test('init without seed → Loaded after hydration', () async {
    when(() => uc('guid')).thenAnswer(
      (_) async => const Right<Failure, ProfileFetchOutcome>(
        ProfileFetched(_hydrated),
      ),
    );
    await cubit.init(userId: 'guid');
    expect(cubit.state, isA<ProfileDetailsLoaded>());
  });

  test('PROFILE_NOT_FOUND → ProfileDetailsNotFound with version bump',
      () async {
    when(() => uc('guid')).thenAnswer(
      (_) async => const Right<Failure, ProfileFetchOutcome>(
        ProfileNotFoundOutcome(serverMessage: 'gone'),
      ),
    );
    await cubit.init(userId: 'guid');
    expect(cubit.state, isA<ProfileDetailsNotFound>());
    expect((cubit.state as ProfileDetailsNotFound).eventVersion, 1);
  });

  test('transport failure with seed retains seed inside Failure', () async {
    when(() => uc('guid')).thenAnswer(
      (_) async => const Left<Failure, ProfileFetchOutcome>(
        ServerFailure(message: 'errors.timeout'),
      ),
    );
    await cubit.init(userId: 'guid', seed: _seed);
    expect(cubit.state, isA<ProfileDetailsFailure>());
    expect((cubit.state as ProfileDetailsFailure).seed, _seed);
  });

  test('refresh keeps seed in Loading then resolves to Loaded', () async {
    when(() => uc('guid')).thenAnswer(
      (_) async => const Right<Failure, ProfileFetchOutcome>(
        ProfileFetched(_hydrated),
      ),
    );
    await cubit.init(userId: 'guid', seed: _seed);
    await cubit.refresh('guid');
    expect(cubit.state, isA<ProfileDetailsLoaded>());
    expect((cubit.state as ProfileDetailsLoaded).profile.age, 27);
  });
}
