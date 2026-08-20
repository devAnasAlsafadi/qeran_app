import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_empty_reason.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_page.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/discovery/domain/usecases/fetch_discovery_page_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/like_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/pass_profile_usecase.dart';
import 'package:qeran/features/discovery/domain/usecases/reset_skipped_profiles_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

class MockFetchPage extends Mock implements FetchDiscoveryPageUseCase {}

class MockLike extends Mock implements LikeProfileUseCase {}

class MockPass extends Mock implements PassProfileUseCase {}

class MockReset extends Mock implements ResetSkippedProfilesUseCase {}

class MockProfileGateCubit extends Mock implements ProfileGateCubit {}

DiscoveryProfile _profile(String id) => DiscoveryProfile(
  id: id,
  name: 'name-$id',
  age: 25,
  images: const [],
  matchingScore: 0,
  placements: const [],
);

DiscoveryPage _page({
  required int pageNumber,
  required int totalPages,
  required List<String> profileIds,
  DiscoveryEmptyReason? reason,
}) => DiscoveryPage(
  profiles: profileIds.map(_profile).toList(),
  pageNumber: pageNumber,
  pageSize: 10,
  totalCount: profileIds.length,
  totalPages: totalPages,
  reason: reason,
);

void main() {
  late MockFetchPage fetch;
  late MockLike like;
  late MockPass pass;
  late MockReset resetSkipped;
  late MockProfileGateCubit mockGate;
  late DiscoveryCubit cubit;

  setUp(() {
    fetch = MockFetchPage();
    like = MockLike();
    pass = MockPass();
    resetSkipped = MockReset();
    mockGate = MockProfileGateCubit();
    when(() => mockGate.isGated).thenReturn(false);
    sl.registerLazySingleton<ProfileGateCubit>(() => mockGate);
    cubit = DiscoveryCubit(
      fetchPage: fetch,
      likeProfile: like,
      passProfile: pass,
      resetSkipped: resetSkipped,
    );
  });

  tearDown(() async {
    await cubit.close();
    await sl.unregister<ProfileGateCubit>();
  });

  // ──────────────────────────────────────────────────────────────────
  // loadInitial
  // ──────────────────────────────────────────────────────────────────
  group('loadInitial', () {
    test('terminal state is Loaded on success', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 2, profileIds: const ['a', 'b']),
        ),
      );

      await cubit.loadInitial();

      expect(cubit.state, isA<DiscoveryLoaded>());
      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.profiles.map((p) => p.id), ['a', 'b']);
      expect(loaded.currentIndex, 0);
      expect(loaded.hasMore, isTrue);
    });

    test('emits Loading synchronously before the terminal state', () {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      // Do NOT await — verify the synchronous emit before the use case
      // resolves.
      cubit.loadInitial();

      expect(cubit.state, isA<DiscoveryLoading>());
    });

    test('terminal state is Failure on Left', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            const Left<Failure, DiscoveryPage>(ServerFailure(message: 'boom')),
      );

      await cubit.loadInitial();

      expect(cubit.state, isA<DiscoveryFailure>());
      expect((cubit.state as DiscoveryFailure).message, 'boom');
    });

    test(
      'terminal state is DiscoveryDailyLimit on DailyViewsExceededFailure',
      () async {
        final resetAt = DateTime.utc(2026, 7, 18);
        when(
          () => fetch(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer(
          (_) async => Left<Failure, DiscoveryPage>(
            DailyViewsExceededFailure(resetAt: resetAt),
          ),
        );

        await cubit.loadInitial();

        expect(cubit.state, isA<DiscoveryDailyLimit>());
        expect((cubit.state as DiscoveryDailyLimit).resetAt, resetAt);
      },
    );

    test('empty page → Loaded with empty profiles list', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const [])),
      );

      await cubit.loadInitial();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.isEmpty, isTrue);
      expect(loaded.isExhausted, isTrue);
      expect(loaded.hasMore, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // like / pass
  // ──────────────────────────────────────────────────────────────────
  group('like', () {
    Future<void> primeWithTwoProfiles() async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );
      await cubit.loadInitial();
    }

    test('success advances currentIndex and clears actionError', () async {
      await primeWithTwoProfiles();
      when(() => like(any())).thenAnswer(
        (_) async =>
            const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 1);
      expect(loaded.actionError, isNull);
      verify(() => like('a')).called(1);
    });

    test('failure sets actionError + bumps version, no advance', () async {
      await primeWithTwoProfiles();
      when(() => like(any())).thenAnswer(
        (_) async => const Left<Failure, LikeOutcome>(
          ServerFailure(message: 'rate-limited'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 0);
      expect(loaded.actionError, 'rate-limited');
      expect(loaded.actionErrorVersion, 1);
    });

    test('consecutive failures bump version each time', () async {
      await primeWithTwoProfiles();
      when(() => like(any())).thenAnswer(
        (_) async => const Left<Failure, LikeOutcome>(
          ServerFailure(message: 'rate-limited'),
        ),
      );

      await cubit.like();
      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.actionErrorVersion, 2);
    });

    test('no-op when state is not Loaded', () async {
      // state is DiscoveryInitial
      await cubit.like();
      verifyNever(() => like(any()));
      expect(cubit.state, isA<DiscoveryInitial>());
    });

    test('no-op when deck is exhausted', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const [])),
      );
      await cubit.loadInitial();

      await cubit.like();

      verifyNever(() => like(any()));
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // like — typed LikeOutcome branching (Phase 2)
  // ──────────────────────────────────────────────────────────────────
  group('like — typed outcomes', () {
    Future<void> prime() async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );
      await cubit.loadInitial();
    }

    test(
      'LikeAccepted advances and calls onLikeSuccess exactly once',
      () async {
        var callbackHits = 0;
        cubit = DiscoveryCubit(
          fetchPage: fetch,
          likeProfile: like,
          passProfile: pass,
          resetSkipped: resetSkipped,
          onLikeSuccess: () => callbackHits++,
        );
        await prime();
        when(() => like(any())).thenAnswer(
          (_) async =>
              const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '42')),
        );

        await cubit.like();

        final loaded = cubit.state as DiscoveryLoaded;
        expect(loaded.currentIndex, 1);
        expect(loaded.actionFailureKind, isNull);
        expect(loaded.actionError, isNull);
        expect(callbackHits, 1);
      },
    );

    test('LikePaywall keeps the card and emits paywall kind', () async {
      var callbackHits = 0;
      cubit = DiscoveryCubit(
        fetchPage: fetch,
        likeProfile: like,
        passProfile: pass,
        resetSkipped: resetSkipped,
        onLikeSuccess: () => callbackHits++,
      );
      await prime();
      when(() => like(any())).thenAnswer(
        (_) async => const Right<Failure, LikeOutcome>(
          LikePaywall(serverMessage: 'استنفدت'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 0); // not advanced
      expect(loaded.actionFailureKind, LikeFailureKind.paywall);
      expect(loaded.actionError, 'استنفدت');
      expect(loaded.actionErrorVersion, 1);
      expect(callbackHits, 0);
    });

    test('LikeAlreadyPending advances + emits alreadyPending kind', () async {
      await prime();
      when(() => like(any())).thenAnswer(
        (_) async => const Right<Failure, LikeOutcome>(
          LikeAlreadyPending(serverMessage: 'طلب قائم'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 1);
      expect(loaded.actionFailureKind, LikeFailureKind.alreadyPending);
      expect(loaded.actionError, 'طلب قائم');
    });

    test('LikeGenderMismatch advances + emits genderMismatch kind', () async {
      await prime();
      when(() => like(any())).thenAnswer(
        (_) async => const Right<Failure, LikeOutcome>(
          LikeGenderMismatch(serverMessage: 'نفس الجنس'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 1);
      expect(loaded.actionFailureKind, LikeFailureKind.genderMismatch);
    });

    test('LikeUserUnavailable advances + emits userUnavailable kind', () async {
      await prime();
      when(() => like(any())).thenAnswer(
        (_) async => const Right<Failure, LikeOutcome>(
          LikeUserUnavailable(serverMessage: 'غير موجود'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 1);
      expect(loaded.actionFailureKind, LikeFailureKind.userUnavailable);
    });

    test('Left(Failure) keeps the card and emits network kind', () async {
      var callbackHits = 0;
      cubit = DiscoveryCubit(
        fetchPage: fetch,
        likeProfile: like,
        passProfile: pass,
        resetSkipped: resetSkipped,
        onLikeSuccess: () => callbackHits++,
      );
      await prime();
      when(() => like(any())).thenAnswer(
        (_) async => const Left<Failure, LikeOutcome>(
          ServerFailure(message: 'connection lost'),
        ),
      );

      await cubit.like();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 0);
      expect(loaded.actionFailureKind, LikeFailureKind.network);
      expect(loaded.actionError, 'connection lost');
      expect(callbackHits, 0);
    });

    test(
      'Left(OfflineFailure) keeps the card and emits offline kind',
      () async {
        await prime();
        when(() => like(any())).thenAnswer(
          (_) async => const Left<Failure, LikeOutcome>(OfflineFailure()),
        );

        await cubit.like();

        final loaded = cubit.state as DiscoveryLoaded;
        expect(loaded.currentIndex, 0);
        expect(loaded.actionFailureKind, LikeFailureKind.offline);
      },
    );

    test('duplicate like while in-flight is ignored', () async {
      await prime();
      final completer = Completer<Either<Failure, LikeOutcome>>();
      when(() => like(any())).thenAnswer((_) => completer.future);

      final first = cubit.like();
      final second = cubit.like(); // should no-op via _mutationInFlight

      completer.complete(
        const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
      );
      await Future.wait([first, second]);

      verify(() => like('a')).called(1); // exactly one API call
    });

    test(
      'advanceGate defers the advance emit until the gate completes',
      () async {
        await prime();
        when(() => like(any())).thenAnswer(
          (_) async =>
              const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
        );

        final gate = Completer<void>();
        final pending = cubit.like(advanceGate: gate.future);
        // Yield so the API future resolves but the gate await blocks.
        await Future<void>.delayed(Duration.zero);
        expect((cubit.state as DiscoveryLoaded).currentIndex, 0);

        gate.complete();
        await pending;
        expect((cubit.state as DiscoveryLoaded).currentIndex, 1);
      },
    );
  });

  group('pass — optimistic', () {
    Future<void> primeTwoCards() async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );
      await cubit.loadInitial();
    }

    test('success advances currentIndex', () async {
      await primeTwoCards();
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      await cubit.pass();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentIndex, 1);
      verify(() => pass('a')).called(1);
    });

    test('advance is synchronous (does not wait for the API future)', () async {
      await primeTwoCards();
      // Hold the network call open. The advance must happen anyway.
      final completer = Completer<Either<Failure, Unit>>();
      when(() => pass(any())).thenAnswer((_) => completer.future);

      await cubit.pass();

      expect((cubit.state as DiscoveryLoaded).currentIndex, 1);
      // Clean up so the test framework doesn't dangle.
      completer.complete(const Right<Failure, Unit>(unit));
    });

    test(
      'transport failure does NOT emit actionError (silent log only)',
      () async {
        await primeTwoCards();
        when(() => pass(any())).thenAnswer(
          (_) async =>
              const Left<Failure, Unit>(ServerFailure(message: 'offline')),
        );

        await cubit.pass();
        // Let the background then-callback resolve so it sees the Left.
        await Future<void>.delayed(Duration.zero);

        final loaded = cubit.state as DiscoveryLoaded;
        expect(loaded.currentIndex, 1); // still advanced
        expect(loaded.actionError, isNull); // silent — no UI surface
        expect(loaded.actionFailureKind, isNull);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // undo
  // ──────────────────────────────────────────────────────────────────
  group('undo', () {
    Future<void> primeAtIndex1() async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 1,
            profileIds: const ['a', 'b', 'c'],
          ),
        ),
      );
      await cubit.loadInitial();
      when(() => like(any())).thenAnswer(
        (_) async =>
            const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
      );
      await cubit.like(); // currentIndex now 1
    }

    test('decrements currentIndex by 1', () async {
      await primeAtIndex1();
      cubit.undo();
      expect((cubit.state as DiscoveryLoaded).currentIndex, 0);
    });

    test('clamps at 0 when already at start', () async {
      // load + don't advance
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );
      await cubit.loadInitial();

      cubit.undo();
      expect((cubit.state as DiscoveryLoaded).currentIndex, 0);
    });

    test(
      'recovers the last profile after passing the only card in the deck',
      () async {
        // 1-profile deck. Passing it exhausts the deck — undo must still
        // bring it back. Regression guard for the action-bar `enabled`
        // cascade bug.
        when(
          () => fetch(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer(
          (_) async => Right(
            _page(pageNumber: 1, totalPages: 1, profileIds: const ['solo']),
          ),
        );
        when(
          () => pass(any()),
        ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

        await cubit.loadInitial();
        await cubit.pass();

        var loaded = cubit.state as DiscoveryLoaded;
        expect(loaded.isExhausted, isTrue);
        expect(loaded.currentIndex, 1);
        expect(loaded.current, isNull);

        cubit.undo();

        loaded = cubit.state as DiscoveryLoaded;
        expect(loaded.isExhausted, isFalse);
        expect(loaded.currentIndex, 0);
        expect(loaded.current?.id, 'solo');
      },
    );

    test('clears actionError', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );
      await cubit.loadInitial();
      when(() => like(any())).thenAnswer(
        (_) async => const Left<Failure, LikeOutcome>(
          ServerFailure(message: 'rate-limited'),
        ),
      );
      await cubit.like();
      // currentIndex still 0 but actionError set — undo from here

      // advance via pass success so we can undo
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
      await cubit.pass();
      // index is 1, but actionError was already cleared by pass success.
      // Set it again, then undo.
      when(() => like(any())).thenAnswer(
        (_) async => const Left<Failure, LikeOutcome>(
          ServerFailure(message: 'oops-again'),
        ),
      );
      await cubit.like();
      expect((cubit.state as DiscoveryLoaded).actionError, 'oops-again');

      cubit.undo();
      expect((cubit.state as DiscoveryLoaded).actionError, isNull);
      expect((cubit.state as DiscoveryLoaded).currentIndex, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Prefetch
  // ──────────────────────────────────────────────────────────────────
  group('prefetch', () {
    test('triggers when within 3 cards of end + appends profiles', () async {
      // Page 1: 5 profiles (a..e), totalPages=2.
      // Threshold = profiles.length - 3 = 2 → advance to index 2 triggers.
      when(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 2,
            profileIds: const ['a', 'b', 'c', 'd', 'e'],
          ),
        ),
      );
      when(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 2, totalPages: 2, profileIds: const ['f', 'g']),
        ),
      );
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      await cubit.loadInitial();
      await cubit.pass(); // index 0 → 1
      await cubit.pass(); // index 1 → 2 — triggers prefetch

      // Wait for the prefetch to settle.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.profiles.map((p) => p.id), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
      ]);
      expect(loaded.currentPage, 2);
      expect(loaded.isPrefetching, isFalse);
      verify(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).called(1);
    });

    test('does NOT trigger when !hasMore', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 1,
            profileIds: const ['a', 'b', 'c'],
          ),
        ),
      );
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      await cubit.loadInitial();
      await cubit.pass();
      await cubit.pass();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Page 1 was the only fetch.
      verify(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).called(1);
      verifyNever(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      );
    });

    test('failure → prefetchError set; no profiles appended', () async {
      when(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 2,
            profileIds: const ['a', 'b', 'c', 'd'],
          ),
        ),
      );
      when(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, DiscoveryPage>(
          ServerFailure(message: 'offline'),
        ),
      );
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      await cubit.loadInitial();
      // Threshold = 4 - 3 = 1; advance to index 1 triggers prefetch.
      await cubit.pass();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.profiles.length, 4); // no appends
      expect(loaded.prefetchError, 'offline');
      expect(loaded.isPrefetching, isFalse);
    });

    test(
      'late prefetch result cannot overwrite a newer filtered deck',
      () async {
        final oldPageTwo = Completer<Either<Failure, DiscoveryPage>>();
        var pageOneCalls = 0;
        when(
          () => fetch(
            page: 1,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer((_) async {
          pageOneCalls++;
          return Right(
            _page(
              pageNumber: 1,
              totalPages: pageOneCalls == 1 ? 2 : 1,
              profileIds: pageOneCalls == 1
                  ? List<String>.generate(
                      DiscoveryCubit.prefetchThreshold + 1,
                      (i) => 'old$i',
                    )
                  : const ['new'],
            ),
          );
        });
        when(
          () => fetch(
            page: 2,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer((_) => oldPageTwo.future);
        when(
          () => pass(any()),
        ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

        await cubit.loadInitial();
        await cubit.pass(); // Starts the old page-2 prefetch.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        verify(
          () => fetch(
            page: 2,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).called(1);

        await cubit.applyFilters(const {'QuestionFilters[99]': 'new'});
        oldPageTwo.complete(
          Right(
            _page(pageNumber: 2, totalPages: 2, profileIds: const ['stale']),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect((cubit.state as DiscoveryLoaded).profiles.map((p) => p.id), [
          'new',
        ]);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // refresh
  // ──────────────────────────────────────────────────────────────────
  group('refresh', () {
    test('resets to page 1, discards previous deck', () async {
      var callCount = 0;
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return Right(
          _page(
            pageNumber: 1,
            totalPages: 1,
            profileIds: callCount == 1 ? const ['a'] : const ['x', 'y'],
          ),
        );
      });

      await cubit.loadInitial();
      await cubit.refresh();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.profiles.map((p) => p.id), ['x', 'y']);
      expect(loaded.currentIndex, 0);
    });

    test(
      'late result from an older reload cannot overwrite the newest deck',
      () async {
        final first = Completer<Either<Failure, DiscoveryPage>>();
        final second = Completer<Either<Failure, DiscoveryPage>>();
        var calls = 0;
        when(
          () => fetch(
            page: 1,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer((_) {
          calls++;
          return calls == 1 ? first.future : second.future;
        });

        final initial = cubit.loadInitial();
        await Future<void>.delayed(Duration.zero);
        final refreshed = cubit.refresh();
        await Future<void>.delayed(Duration.zero);

        second.complete(
          Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['new'])),
        );
        await refreshed;

        first.complete(
          Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['old'])),
        );
        await initial;

        expect((cubit.state as DiscoveryLoaded).profiles.map((p) => p.id), [
          'new',
        ]);
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // applyFilters + filter-preserving pagination
  // ──────────────────────────────────────────────────────────────────
  group('applyFilters', () {
    test('reloads from page 1 with the given filterParams', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      const filters = {
        'RangeFrom[5]': '160',
        'RangeTo[5]': '180',
        'QuestionFilters[18]': 'Single',
      };
      await cubit.applyFilters(filters);

      // Page 1 must be fetched with EXACTLY those filter params.
      verify(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: filters,
        ),
      ).called(1);
    });

    test('null clears filters; subsequent fetches pass null', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      // First apply with filters, then clear.
      await cubit.applyFilters(const {'QuestionFilters[11]': 'SA'});
      await cubit.applyFilters(null);

      // The second reload sends null (no filter constraint).
      verify(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: null,
        ),
      ).called(greaterThanOrEqualTo(1));
    });

    test('empty map is treated as "no filters"', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      await cubit.applyFilters(const {});

      verify(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: null,
        ),
      ).called(1);
    });
  });

  group('prefetch preserves active filters', () {
    test('page 2 fetch carries the same filterParams as page 1', () async {
      const filters = {
        'RangeFrom[1]': '25',
        'RangeTo[1]': '35',
        'QuestionFilters[11]': 'SA',
      };

      when(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 2,
            profileIds: const ['a', 'b', 'c', 'd', 'e'],
          ),
        ),
      );
      when(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 2, totalPages: 2, profileIds: const ['f', 'g']),
        ),
      );
      when(
        () => pass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

      await cubit.applyFilters(filters);
      await cubit.pass(); // 0 → 1
      await cubit.pass(); // 1 → 2, threshold met, prefetch fires

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // The prefetch must carry the SAME filterParams instance as page 1.
      verify(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: filters,
        ),
      ).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // lifecycle — regression for "Cannot emit new states after close"
  // ──────────────────────────────────────────────────────────────────
  group('lifecycle (closed-before-emit guards)', () {
    test('loadInitial: close before fetch completes does not throw', () async {
      final completer = Completer<Either<Failure, DiscoveryPage>>();
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer((_) => completer.future);

      // Fire the load but do not await — keep the fetch in flight.
      final pending = cubit.loadInitial();

      // Simulate the screen disposing mid-flight (rapid back-nav).
      await cubit.close();

      // Late server response arrives after close. Without the
      // isClosed guard inside _loadFirstPage, the fold below would
      // throw StateError: Cannot emit new states after calling close.
      completer.complete(
        Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      await expectLater(pending, completes);
    });

    test('like: close before usecase completes does not throw', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );
      await cubit.loadInitial();

      final completer = Completer<Either<Failure, LikeOutcome>>();
      when(() => like(any())).thenAnswer((_) => completer.future);

      final pending = cubit.like();
      await cubit.close();

      completer.complete(
        const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
      );

      await expectLater(pending, completes);
    });

    test(
      'prefetch: close before second-page fetch completes does not throw',
      () async {
        // Prime with profile count == prefetchThreshold so the next pass()
        // triggers _prefetch immediately.
        final ids = List<String>.generate(
          DiscoveryCubit.prefetchThreshold + 1,
          (i) => 'p$i',
        );
        when(
          () => fetch(
            page: 1,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer(
          (_) async =>
              Right(_page(pageNumber: 1, totalPages: 2, profileIds: ids)),
        );
        when(
          () => pass(any()),
        ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
        await cubit.loadInitial();

        // Page-2 fetch is the one we hold pending.
        final completer = Completer<Either<Failure, DiscoveryPage>>();
        when(
          () => fetch(
            page: 2,
            pageSize: any(named: 'pageSize'),
            filterParams: any(named: 'filterParams'),
          ),
        ).thenAnswer((_) => completer.future);

        await cubit.pass(); // advance → triggers prefetch (unawaited)
        await cubit.close();

        completer.complete(
          Right(_page(pageNumber: 2, totalPages: 2, profileIds: const ['x'])),
        );

        // Let any microtask scheduled by the prefetch fold run.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        // Reaching here without a StateError is the assertion.
      },
    );
  });

  // ──────────────────────────────────────────────────────────────────
  // empty reason: what the server reports vs what the client infers
  // ──────────────────────────────────────────────────────────────────
  group('empty reason', () {
    void stubPass() => when(
      () => pass(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    test('loadInitial stores the reason the page reported', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 1,
            profileIds: const [],
            reason: DiscoveryEmptyReason.noMatchesForFilters,
          ),
        ),
      );

      await cubit.loadInitial();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, DiscoveryEmptyReason.noMatchesForFilters);
      expect(loaded.filtersMatchedNobody, isTrue);
      expect(loaded.hasSeenEveryone, isFalse);
    });

    test('a page that reports nothing leaves the reason null', () async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      await cubit.loadInitial();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, isNull);
      expect(loaded.hasSeenEveryone, isFalse);
    });

    // Broadening a filter must not leave the old query's verdict on screen.
    // `applyFilters` routes through `_loadFirstPage`, which BUILDS a new
    // DiscoveryLoaded rather than copying — so there is nothing to inherit.
    test('a fresh filter query cannot inherit the previous query reason', () async {
      final responses = <DiscoveryPage>[
        _page(
          pageNumber: 1,
          totalPages: 1,
          profileIds: const [],
          reason: DiscoveryEmptyReason.noMatchesForFilters,
        ),
        _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
      ];
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer((_) async => Right(responses.removeAt(0)));

      await cubit.loadInitial();
      expect(
        (cubit.state as DiscoveryLoaded).currentReason,
        DiscoveryEmptyReason.noMatchesForFilters,
      );

      await cubit.applyFilters({'q': 'wider'});

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, isNull);
      expect(loaded.filtersMatchedNobody, isFalse);
    });

    test('a prefetched page carries its own reason into state', () async {
      stubPass();
      when(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 2, profileIds: const ['a', 'b']),
        ),
      );
      when(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 2,
            totalPages: 2,
            profileIds: const [],
            reason: DiscoveryEmptyReason.seenAll,
          ),
        ),
      );

      await cubit.loadInitial();
      await cubit.pass(); // within the threshold → fires the prefetch
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, DiscoveryEmptyReason.seenAll);
      expect(loaded.hasSeenEveryone, isTrue);
    });

    // The half `??` alone cannot do, and the reason `resetReason` exists.
    test('a prefetched page with no reason clears the stored one', () async {
      stubPass();
      when(
        () => fetch(
          page: 1,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(
            pageNumber: 1,
            totalPages: 2,
            profileIds: const ['a', 'b'],
            reason: DiscoveryEmptyReason.noMatchesForFilters,
          ),
        ),
      );
      when(
        () => fetch(
          page: 2,
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 2, totalPages: 2, profileIds: const ['c']),
        ),
      );

      await cubit.loadInitial();
      await cubit.pass();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, isNull);
      expect(loaded.filtersMatchedNobody, isFalse);
    });

    // The headline case the whole arc exists for: the server handed over
    // profiles, so it reports NO reason and never learns what happened next.
    // Only the client can see the deck run dry.
    test('swiping a single-page deck dry is detected with no server reason', () async {
      stubPass();
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const ['a'])),
      );

      await cubit.loadInitial();
      expect((cubit.state as DiscoveryLoaded).hasSeenEveryone, isFalse);

      await cubit.pass();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.currentReason, isNull, reason: 'server said nothing');
      expect(loaded.sawEveryLoadedProfile, isTrue);
      expect(loaded.hasSeenEveryone, isTrue);
    });
  });

  // "Start over" restores skipped profiles. The three outcomes are deliberately
  // NOT collapsed: restoring somebody reloads (the cards are the feedback),
  // restoring nobody must SAY so (a silent reload of an unchanged deck reads as
  // a broken button), and a failure goes down the ordinary error channel.
  group('resetSeen', () {
    Future<void> primeExhausted() async {
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async =>
            Right(_page(pageNumber: 1, totalPages: 1, profileIds: const [])),
      );
      await cubit.loadInitial();
    }

    test('a restored count reloads the deck and toasts nothing', () async {
      await primeExhausted();
      when(() => resetSkipped()).thenAnswer(
        (_) async => const Right<Failure, int>(115),
      );
      // Second fetch returns the profiles the reset put back.
      when(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer(
        (_) async => Right(
          _page(pageNumber: 1, totalPages: 1, profileIds: const ['a', 'b']),
        ),
      );

      await cubit.resetSeen();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.profiles.map((p) => p.id), ['a', 'b']);
      expect(loaded.resetNotice, isNull, reason: 'the cards are the feedback');
      expect(loaded.isResettingSeen, isFalse);
    });

    test('zero restored notices the user and does NOT reload', () async {
      await primeExhausted();
      when(
        () => resetSkipped(),
      ).thenAnswer((_) async => const Right<Failure, int>(0));

      await cubit.resetSeen();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.resetNotice, DiscoveryResetNotice.nothingToRestore);
      expect(loaded.resetNoticeVersion, 1);
      expect(loaded.isResettingSeen, isFalse);
      // Exactly the priming call — no reload of a deck that cannot have changed.
      verify(
        () => fetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).called(1);
    });

    // Equatable would dedupe two identical notices, and the listener would
    // swallow the second — so a user tapping twice must see two toasts.
    test('a repeated no-op bumps the notice version', () async {
      await primeExhausted();
      when(
        () => resetSkipped(),
      ).thenAnswer((_) async => const Right<Failure, int>(0));

      await cubit.resetSeen();
      await cubit.resetSeen();

      expect((cubit.state as DiscoveryLoaded).resetNoticeVersion, 2);
    });

    // Reset owns its channel outright. Borrowing `actionError` would route the
    // failure through the like listener, which renders a generic "something
    // went wrong" by design and would discard this action's own copy.
    test('failure reports on the reset channel, not actionError', () async {
      await primeExhausted();
      when(() => resetSkipped()).thenAnswer(
        (_) async => const Left<Failure, int>(ServerFailure(message: 'boom')),
      );

      await cubit.resetSeen();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.resetNotice, DiscoveryResetNotice.failed);
      expect(loaded.resetNoticeVersion, 1);
      expect(loaded.isResettingSeen, isFalse);
      expect(loaded.actionError, isNull, reason: 'not the like channel');
      expect(loaded.actionFailureKind, isNull);
    });

    test('an offline failure is told apart from a server failure', () async {
      await primeExhausted();
      when(() => resetSkipped()).thenAnswer(
        (_) async => const Left<Failure, int>(OfflineFailure()),
      );

      await cubit.resetSeen();

      expect(
        (cubit.state as DiscoveryLoaded).resetNotice,
        DiscoveryResetNotice.offline,
      );
    });

    // A failed reset then a successful no-op must both be announced.
    test('a failure then a no-op bumps the version twice', () async {
      await primeExhausted();
      when(() => resetSkipped()).thenAnswer(
        (_) async => const Left<Failure, int>(ServerFailure(message: 'boom')),
      );
      await cubit.resetSeen();

      when(
        () => resetSkipped(),
      ).thenAnswer((_) async => const Right<Failure, int>(0));
      await cubit.resetSeen();

      final loaded = cubit.state as DiscoveryLoaded;
      expect(loaded.resetNotice, DiscoveryResetNotice.nothingToRestore);
      expect(loaded.resetNoticeVersion, 2);
    });

    test('the state flags the request while it is in flight', () async {
      await primeExhausted();
      final completer = Completer<Either<Failure, int>>();
      when(() => resetSkipped()).thenAnswer((_) => completer.future);

      final pending = cubit.resetSeen();
      expect((cubit.state as DiscoveryLoaded).isResettingSeen, isTrue);

      completer.complete(const Right(0));
      await pending;

      expect((cubit.state as DiscoveryLoaded).isResettingSeen, isFalse);
    });

    // The button is disabled while in flight, but a double-tap can still land
    // in the same frame; the guard is what stops two resets racing.
    test('a second tap while in flight is ignored', () async {
      await primeExhausted();
      final completer = Completer<Either<Failure, int>>();
      when(() => resetSkipped()).thenAnswer((_) => completer.future);

      final first = cubit.resetSeen();
      await cubit.resetSeen();

      completer.complete(const Right(0));
      await first;

      verify(() => resetSkipped()).called(1);
    });

    test('closing before the reset resolves does not throw', () async {
      await primeExhausted();
      final completer = Completer<Either<Failure, int>>();
      when(() => resetSkipped()).thenAnswer((_) => completer.future);

      final pending = cubit.resetSeen();
      await cubit.close();
      completer.complete(const Right(0));
      await pending;
      // Reaching here without a StateError is the assertion.
    });
  });
}
