import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/reset_skipped_profiles_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';

DiscoveryProfile _p(String id) => DiscoveryProfile(
  id: id,
  name: 'name-$id',
  age: 25,
  images: const [],
  matchingScore: 0,
  placements: const [],
);

/// Page 1 is [first]; with [more], page 2 exists and is recorded when asked.
class _Fetch implements FetchDiscoveryPageUseCase {
  _Fetch(this.first, {this.more = false});

  final List<DiscoveryProfile> first;
  final bool more;
  final List<int> pages = [];

  @override
  Future<Either<Failure, DiscoveryPage>> call({
    int page = 1,
    int pageSize = 10,
    Map<String, String>? filterParams,
  }) async {
    pages.add(page);
    return Right(
      DiscoveryPage(
        profiles: page == 1 ? first : [_p('z')],
        pageNumber: page,
        pageSize: 10,
        totalCount: first.length + (more ? 1 : 0),
        totalPages: more ? 2 : 1,
      ),
    );
  }
}

class _Like implements LikeProfileUseCase {
  @override
  Future<Either<Failure, LikeOutcome>> call(String profileId) async =>
      const Right(LikeAccepted(likeId: '1'));
}

class _Pass implements PassProfileUseCase {
  @override
  Future<Either<Failure, Unit>> call(String profileId) async =>
      const Right(unit);
}

class _Reset implements ResetSkippedProfilesUseCase {
  @override
  Future<Either<Failure, int>> call() async => const Right(0);
}

/// A member blocked from a Suggestions card (run 6): the card leaves the deck
/// and the next becomes current, with no reload.
void main() {
  DiscoveryLoaded deck(List<String> ids, int at) => DiscoveryLoaded(
    profiles: [for (final id in ids) _p(id)],
    currentIndex: at,
    currentPage: 1,
    totalPages: 1,
  );

  List<String> ids(DiscoveryLoaded s) => [for (final p in s.profiles) p.id];

  test('the blocked card goes; the next one is current', () {
    final after = deck(['a', 'b', 'c'], 1).without('b');

    expect(ids(after), ['a', 'c']);
    expect(after.current?.id, 'c');
  });

  test('a copy behind the current card goes too; the current one stays', () {
    final after = deck(['a', 'b', 'a', 'c'], 3).without('a');

    expect(ids(after), ['b', 'c']);
    expect(after.current?.id, 'c');
  });

  test('a copy later in the deck goes too', () {
    expect(ids(deck(['a', 'b', 'c', 'b'], 1).without('b')), ['a', 'c']);
  });

  group('the cubit', () {
    Future<DiscoveryCubit> loaded(_Fetch fetch) async {
      final cubit = DiscoveryCubit(
        fetchPage: fetch,
        likeProfile: _Like(),
        passProfile: _Pass(),
        resetSkipped: _Reset(),
      );
      await cubit.loadInitial();
      return cubit;
    }

    test('Undo after a block walks back past them, never to them', () async {
      final cubit = await loaded(_Fetch([_p('a'), _p('b'), _p('c')]));
      cubit.pass(); // a → b
      await pumpEventQueue();

      cubit.drop('b');
      expect((cubit.state as DiscoveryLoaded).current?.id, 'c');

      cubit.undo();
      expect((cubit.state as DiscoveryLoaded).current?.id, 'a');
      await cubit.close();
    });

    test('blocking the last loaded card asks for the next page', () async {
      final fetch = _Fetch([_p('a')], more: true);
      final cubit = await loaded(fetch);
      fetch.pages.clear();

      cubit.drop('a');
      await pumpEventQueue();

      expect(fetch.pages, [2]);
      expect((cubit.state as DiscoveryLoaded).current?.id, 'z');
      await cubit.close();
    });
  });
}
