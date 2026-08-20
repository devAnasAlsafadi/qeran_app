import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
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
import 'package:qeran/features/discovery/presentation/widgets/discovery_deck_animation_controller.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_deck_animator.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

class _MockFetchPage extends Mock implements FetchDiscoveryPageUseCase {}

class _MockLike extends Mock implements LikeProfileUseCase {}

class _MockPass extends Mock implements PassProfileUseCase {}

class _MockReset extends Mock implements ResetSkippedProfilesUseCase {}

class _MockProfileGateCubit extends Mock implements ProfileGateCubit {}

DiscoveryProfile _profile(String id) => DiscoveryProfile(
  id: id,
  name: 'name-$id',
  age: 25,
  images: const [],
  matchingScore: 0,
  placements: const [],
);

DiscoveryPage _page(List<String> ids) => DiscoveryPage(
  profiles: ids.map(_profile).toList(),
  pageNumber: 1,
  pageSize: 10,
  totalCount: ids.length,
  totalPages: 1,
);

class _Harness extends StatefulWidget {
  final DiscoveryCubit cubit;
  final DiscoveryDeckAnimationController controller;
  final String initialKey;
  const _Harness({
    required this.cubit,
    required this.controller,
    required this.initialKey,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late String _key = widget.initialKey;

  void swapKey(String next) => setState(() => _key = next);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<DiscoveryCubit>.value(
          value: widget.cubit,
          child: DeckAnimationScope(
            notifier: widget.controller,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1),
              child: KeyedSubtree(
                key: ValueKey<String>(_key),
                child: const DiscoveryDeckAnimator(
                  child: SizedBox(width: 200, height: 200),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  late _MockFetchPage fetch;
  late _MockLike like;
  late _MockPass pass;
  late _MockProfileGateCubit mockGate;
  late DiscoveryCubit cubit;
  late DiscoveryDeckAnimationController controller;

  setUp(() async {
    fetch = _MockFetchPage();
    like = _MockLike();
    pass = _MockPass();
    mockGate = _MockProfileGateCubit();
    when(() => mockGate.isGated).thenReturn(false);
    sl.registerLazySingleton<ProfileGateCubit>(() => mockGate);
    when(
      () => fetch(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        filterParams: any(named: 'filterParams'),
      ),
    ).thenAnswer((_) async => Right(_page(const ['A'])));
    when(() => like(any())).thenAnswer(
      (_) async => const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
    );
    when(
      () => pass(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    cubit = DiscoveryCubit(
      fetchPage: fetch,
      likeProfile: like,
      passProfile: pass,
      resetSkipped: _MockReset(),
    );
    await cubit.loadInitial();
    controller = DiscoveryDeckAnimationController();
  });

  tearDown(() async {
    await cubit.close();
    controller.dispose();
    await sl.unregister<ProfileGateCubit>();
  });

  testWidgets(
    'triggerLike runs to completion then calls cubit.like exactly once',
    (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      // Animator's didChangeDependencies binds the handlers.
      await tester.pump();

      final future = controller.triggerLike();
      await tester.pumpAndSettle();
      await future;

      verify(() => like('A')).called(1);
      verifyNever(() => pass(any()));
      expect(controller.isAnimating, isFalse);
    },
  );

  testWidgets(
    'triggerPass runs to completion then calls cubit.pass exactly once',
    (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      final future = controller.triggerPass();
      await tester.pumpAndSettle();
      await future;

      verify(() => pass('A')).called(1);
      verifyNever(() => like(any()));
      expect(controller.isAnimating, isFalse);
    },
  );

  testWidgets(
    'external profile change mid-animation cancels: cubit.like NOT called',
    (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      // Start the like animation (300 ms total). We deliberately do NOT
      // await — the disposed ticker's future would never let us settle
      // and the assertion target is on mock-call presence, not future
      // resolution.
      // ignore: unawaited_futures
      controller.triggerLike();
      // Advance partway so the exit animation is mid-flight.
      await tester.pump(const Duration(milliseconds: 60));

      // Swap the animator's parent key — AnimatedSwitcher unmounts the
      // old animator before its _runLikeSequence can commit to the cubit.
      final harness = tester.state<_HarnessState>(find.byType(_Harness));
      harness.swapKey('B');
      // One frame to process the setState, then a tick past the 1 ms
      // AnimatedSwitcher transition so the old animator is fully gone.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5));

      verifyNever(() => like(any()));
      expect(
        controller.isAnimating,
        isFalse,
        reason: 'animator.dispose calls controller.reset()',
      );
    },
  );

  testWidgets('rapid double triggerLike calls cubit.like exactly once', (
    tester,
  ) async {
    await tester.pumpWidget(
      _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
    );
    await tester.pump();

    final first = controller.triggerLike();
    final second = controller.triggerLike(); // bails immediately
    await tester.pumpAndSettle();
    await Future.wait([first, second]);

    verify(() => like('A')).called(1);
  });

  // ── Drag integration tests ─────────────────────────────────────────
  //
  // These exercise the full controller → animator path: simulated drag
  // events through the controller's drag methods, then assert the
  // cubit was/wasn't called after the resulting snap / eject animation
  // completes. Screen width is pinned via setSurfaceSize so the
  // distance threshold (0.35 × width) is predictable.

  group('drag → snap / eject', () {
    // Drag amounts chosen to be safely above 0.35 × (any reasonable
    // test surface width — default flutter_test is 800, max common is
    // ~1080). `setSurfaceSize` in setUp isn't reliable here, so we
    // sidestep it with values that pass the threshold either way.
    const bigDragPx = 500.0;
    const smallDragPx = 40.0;

    /// No-op kept so removing it doesn't churn the rest of the file.
    /// Each test originally pinned the surface to 500×800 — see git
    /// history for the prior approach. We now rely on absolute drag
    /// magnitudes that beat the 0.35 × width threshold on any common
    /// surface.
    Future<void> pinSurface(WidgetTester tester) async {}

    testWidgets('small drag → snap back, cubit NOT called', (tester) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(smallDragPx); // well below threshold
      controller.onDragUpdate(smallDragPx);
      // NOTE: `onDragEnd` awaits the snap/eject animation, which only
      // advances when pump() runs frames. Awaiting onDragEnd before
      // pumping deadlocks the test. Capture the future, pump, then
      // await the (now-resolved) future.
      final future = controller.onDragEnd(velocity: 0);
      await tester.pumpAndSettle();
      await future;

      verifyNever(() => like(any()));
      verifyNever(() => pass(any()));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('drag right past distance threshold → cubit.like once', (
      tester,
    ) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(bigDragPx);
      final future = controller.onDragEnd(velocity: 0);
      await tester.pumpAndSettle();
      await future;

      verify(() => like('A')).called(1);
      verifyNever(() => pass(any()));
    });

    testWidgets('drag left past distance threshold → cubit.pass once', (
      tester,
    ) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(-bigDragPx);
      final future = controller.onDragEnd(velocity: 0);
      await tester.pumpAndSettle();
      await future;

      verify(() => pass('A')).called(1);
      verifyNever(() => like(any()));
    });

    testWidgets('high-velocity right fling (small offset) → cubit.like', (
      tester,
    ) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(30); // below distance threshold
      final future = controller.onDragEnd(velocity: 1500); // above 800 vel
      await tester.pumpAndSettle();
      await future;

      verify(() => like('A')).called(1);
    });

    testWidgets('high-velocity left fling (small offset) → cubit.pass', (
      tester,
    ) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(-30);
      final future = controller.onDragEnd(velocity: -1500);
      await tester.pumpAndSettle();
      await future;

      verify(() => pass('A')).called(1);
    });

    testWidgets('drag events during in-flight eject are ignored', (
      tester,
    ) async {
      await pinSurface(tester);
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      // Kick off the eject — capture so we can await after pumping.
      controller.onDragStart();
      controller.onDragUpdate(bigDragPx);
      final ejectFuture = controller.onDragEnd(velocity: 0);
      await tester.pump(const Duration(milliseconds: 50));

      // Competing gesture mid-eject — controller must gate everything.
      // The second onDragEnd returns immediately because isAnimating
      // is true, so awaiting it is safe.
      controller.onDragStart();
      controller.onDragUpdate(-100);
      await controller.onDragEnd(velocity: -1500);

      await tester.pumpAndSettle();
      await ejectFuture;

      // Only the original right-eject's like commit fires; the
      // competing left-fling is dropped.
      verify(() => like('A')).called(1);
      verifyNever(() => pass(any()));
    });

    testWidgets(
      'profile changes mid-eject → cubit NOT called for old profile',
      (tester) async {
        await pinSurface(tester);
        await tester.pumpWidget(
          _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
        );
        await tester.pump();

        controller.onDragStart();
        controller.onDragUpdate(bigDragPx);
        // ignore: unawaited_futures
        controller.onDragEnd(velocity: 0);
        // Mid-eject.
        await tester.pump(const Duration(milliseconds: 30));

        final harness = tester.state<_HarnessState>(find.byType(_Harness));
        harness.swapKey('B');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 5));

        verifyNever(() => like(any()));
        expect(controller.isAnimating, isFalse);
      },
    );
  });

  // ── dispose-safety regression ─────────────────────────────────────
  //
  // Like exit causes the AnimatedSwitcher to unmount the old animator
  // and mount a new one. The old animator's dispose() must NOT write to
  // deckProgress (writing to a ValueNotifier while the widget tree is
  // locked caused "setState called when widget tree was locked" crashes).

  testWidgets('Like exit does not throw FlutterError from dispose()', (
    tester,
  ) async {
    // Wire a cubit-driven harness so the AnimatedSwitcher actually swaps
    // cards when the cubit advances (the static-key _Harness wouldn't
    // trigger dispose on the old animator).
    final localFetch = _MockFetchPage();
    final localLike = _MockLike();
    final localPass = _MockPass();
    when(
      () => localFetch(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        filterParams: any(named: 'filterParams'),
      ),
    ).thenAnswer((_) async => Right(_page(const ['A', 'B'])));
    when(() => localLike(any())).thenAnswer(
      (_) async => const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
    );
    when(
      () => localPass(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    final localCubit = DiscoveryCubit(
      fetchPage: localFetch,
      likeProfile: localLike,
      passProfile: localPass,
      resetSkipped: _MockReset(),
    );
    await localCubit.loadInitial();
    final localController = DiscoveryDeckAnimationController();
    addTearDown(() async {
      await localCubit.close();
      localController.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<DiscoveryCubit>.value(
            value: localCubit,
            child: DeckAnimationScope(
              notifier: localController,
              child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                builder: (context, state) {
                  if (state is! DiscoveryLoaded ||
                      state.isEmpty ||
                      state.isExhausted) {
                    return const SizedBox.shrink();
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1),
                    child: KeyedSubtree(
                      key: ValueKey<String>(state.current!.id),
                      child: const DiscoveryDeckAnimator(
                        child: SizedBox(width: 200, height: 200),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Run a full Like exit — the old animator is disposed mid-animation.
    // Should complete without any FlutterError.
    final likeFuture = localController.triggerLike();
    await tester.pumpAndSettle();
    await likeFuture;

    expect(localController.isAnimating, isFalse);
    verify(() => localLike('A')).called(1);
  });

  // ── deckProgress tracking ──────────────────────────────────────────
  //
  // Verifies that the animator drives controller.deckProgress correctly
  // during drag, eject, and snap-back so the peek-card layer reacts.

  group('deckProgress tracking', () {
    testWidgets('deckProgress is 0.0 at idle after mount', (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();
      expect(controller.deckProgress.value, 0.0);
    });

    testWidgets('deckProgress rises on right drag', (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(200.0);
      await tester.pump();

      expect(controller.deckProgress.value, greaterThan(0.0));
      expect(controller.deckProgress.value, lessThanOrEqualTo(1.0));
    });

    testWidgets('deckProgress rises on left drag', (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(-200.0);
      await tester.pump();

      expect(controller.deckProgress.value, greaterThan(0.0));
    });

    testWidgets('deckProgress returns to 0 after snap-back', (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      controller.onDragStart();
      controller.onDragUpdate(40.0); // below eject threshold
      final snapFuture = controller.onDragEnd(velocity: 0);
      await tester.pumpAndSettle();
      await snapFuture;

      expect(controller.deckProgress.value, closeTo(0.0, 0.01));
    });

    testWidgets('deckProgress is positive mid-Like exit', (tester) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      // ignore: unawaited_futures
      controller.triggerLike();
      // The first pump fires the very first ticker tick at elapsed=0 ms
      // (Flutter sets _startTime on the first tick, so elapsed is always 0
      // on that frame regardless of the Duration passed). A second pump
      // advances to the real elapsed time.
      await tester.pump(); // first tick: elapsed = 0
      await tester.pump(const Duration(milliseconds: 180)); // elapsed = 180 ms

      // easeInCubic at 180/260 keeps the card visibly mid-exit.
      expect(controller.deckProgress.value, greaterThan(0.1));
    });

    testWidgets('deckProgress stays in [0,1] after a full eject cycle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Harness(cubit: cubit, controller: controller, initialKey: 'A'),
      );
      await tester.pump();

      // Large drag → eject. deckProgress should track 0→1 and stay bounded.
      controller.onDragStart();
      controller.onDragUpdate(500.0);
      final ejectFuture = controller.onDragEnd(velocity: 0);
      await tester.pumpAndSettle();
      await ejectFuture;

      expect(controller.deckProgress.value, inInclusiveRange(0.0, 1.0));
    });
  });

  // ── Undo integration tests ─────────────────────────────────────────
  //
  // Undo wiring requires the AnimatedSwitcher's key to update when the
  // cubit's currentIndex changes — the prior `_Harness` is keyed on a
  // static string, so we use a separate cubit-driven harness here.

  group('undo entry animation', () {
    late _MockFetchPage undoFetch;
    late _MockLike undoLike;
    late _MockPass undoPass;
    late DiscoveryCubit undoCubit;
    late DiscoveryDeckAnimationController undoController;

    Future<void> setUpDeck(List<String> ids) async {
      undoFetch = _MockFetchPage();
      undoLike = _MockLike();
      undoPass = _MockPass();
      when(
        () => undoFetch(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          filterParams: any(named: 'filterParams'),
        ),
      ).thenAnswer((_) async => Right(_page(ids)));
      when(() => undoLike(any())).thenAnswer(
        (_) async =>
            const Right<Failure, LikeOutcome>(LikeAccepted(likeId: '1')),
      );
      when(
        () => undoPass(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
      undoCubit = DiscoveryCubit(
        fetchPage: undoFetch,
        likeProfile: undoLike,
        passProfile: undoPass,
        resetSkipped: _MockReset(),
      );
      await undoCubit.loadInitial();
      undoController = DiscoveryDeckAnimationController();
    }

    tearDown(() async {
      await undoCubit.close();
      undoController.dispose();
    });

    Future<void> pumpCubitHarness(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<DiscoveryCubit>.value(
              value: undoCubit,
              child: DeckAnimationScope(
                notifier: undoController,
                child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                  builder: (context, state) {
                    if (state is! DiscoveryLoaded ||
                        state.isEmpty ||
                        state.isExhausted) {
                      return const SizedBox.shrink();
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1),
                      child: KeyedSubtree(
                        key: ValueKey<String>(state.current!.id),
                        child: const DiscoveryDeckAnimator(
                          child: SizedBox(width: 200, height: 200),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'undo does not throw "setState during build" (regression: _updateDeckProgress in didChangeDependencies)',
      (tester) async {
        // _maybeStartUndoEntry() called _updateDeckProgress() which wrote to
        // deckProgress.value during SchedulerPhase.persistentCallbacks → crash.
        // Fix: _setDeckProgress() defers the write via addPostFrameCallback.
        await setUpDeck(const ['A', 'B']);
        await pumpCubitHarness(tester);
        await tester.pump();

        final likeFuture = undoController.triggerLike();
        await tester.pumpAndSettle();
        await likeFuture;

        final undoFuture = undoController.triggerUndo(
          onUndoCall: undoCubit.undo,
        );
        // If the crash fires, pumpAndSettle propagates a FlutterError and
        // the test fails before reaching this line.
        await tester.pumpAndSettle();
        await undoFuture;

        expect((undoCubit.state as DiscoveryLoaded).current?.id, 'A');
        expect(undoController.isAnimating, isFalse);
      },
    );

    testWidgets('undo after Pass returns from left and recovers profile', (
      tester,
    ) async {
      await setUpDeck(const ['A', 'B']);
      await pumpCubitHarness(tester);
      await tester.pump();

      // Pass A — controller records direction -1, cubit advances to B.
      final passFuture = undoController.triggerPass();
      await tester.pumpAndSettle();
      await passFuture;
      expect(undoController.lastExitDirection, -1);
      expect((undoCubit.state as DiscoveryLoaded).current?.id, 'B');

      // Undo — should bring back A from the left.
      final undoFuture = undoController.triggerUndo(onUndoCall: undoCubit.undo);
      await tester.pumpAndSettle();
      await undoFuture;

      expect((undoCubit.state as DiscoveryLoaded).current?.id, 'A');
      expect(undoController.isAnimating, isFalse);
      expect(undoController.pendingUndoDirection, 0);
    });

    testWidgets('undo after Like returns from right and recovers profile', (
      tester,
    ) async {
      await setUpDeck(const ['A', 'B']);
      await pumpCubitHarness(tester);
      await tester.pump();

      final likeFuture = undoController.triggerLike();
      await tester.pumpAndSettle();
      await likeFuture;
      expect(undoController.lastExitDirection, 1);

      final undoFuture = undoController.triggerUndo(onUndoCall: undoCubit.undo);
      await tester.pumpAndSettle();
      await undoFuture;

      expect((undoCubit.state as DiscoveryLoaded).current?.id, 'A');
      expect(undoController.isAnimating, isFalse);
    });

    testWidgets('undo while another animation is running is ignored', (
      tester,
    ) async {
      await setUpDeck(const ['A', 'B']);
      await pumpCubitHarness(tester);
      await tester.pump();

      // Kick off a Like exit; mid-flight, try to undo.
      // ignore: unawaited_futures
      undoController.triggerLike();
      await tester.pump(const Duration(milliseconds: 30));

      var undoFired = false;
      final undoFuture = undoController.triggerUndo(
        onUndoCall: () {
          undoFired = true;
          undoCubit.undo();
        },
      );

      await tester.pumpAndSettle();
      await undoFuture;

      // Undo bailed (isAnimating was true). The Like still committed.
      expect(undoFired, isFalse);
      // After Like, current is B; undo didn't fire so we're still on B.
      expect((undoCubit.state as DiscoveryLoaded).current?.id, 'B');
    });

    testWidgets('undo after passing the last card recovers the profile', (
      tester,
    ) async {
      // 1-profile deck → passing exhausts. The undo button is enabled
      // in production (per the prior edge-case fix); the controller
      // must still drive the entry animation when no animator is
      // currently mounted at the moment undo is tapped.
      await setUpDeck(const ['A']);
      await pumpCubitHarness(tester);
      await tester.pump();

      final passFuture = undoController.triggerPass();
      await tester.pumpAndSettle();
      await passFuture;
      expect((undoCubit.state as DiscoveryLoaded).isExhausted, isTrue);

      // Now exhausted — animator is unmounted. Undo via the controller.
      final undoFuture = undoController.triggerUndo(onUndoCall: undoCubit.undo);
      await tester.pumpAndSettle();
      await undoFuture;

      final after = undoCubit.state as DiscoveryLoaded;
      expect(after.isExhausted, isFalse);
      expect(after.current?.id, 'A');
      expect(undoController.isAnimating, isFalse);
    });

    testWidgets('external state change mid-undo-entry resolves cleanly', (
      tester,
    ) async {
      // External state change AFTER the new animator mounts for undo
      // entry, BEFORE the entry animation finishes. dispose's
      // completeUndo guard must unblock the controller.
      await setUpDeck(const ['A', 'B']);
      await pumpCubitHarness(tester);
      await tester.pump();

      // Pass A → state on B; lastExitDirection = -1.
      final passFuture = undoController.triggerPass();
      await tester.pumpAndSettle();
      await passFuture;

      // Start undo (entry animation begins).
      // ignore: unawaited_futures
      undoController.triggerUndo(onUndoCall: undoCubit.undo);
      await tester.pump();
      // Mid-entry, force a refresh — replaces the deck via cubit.
      await tester.pump(const Duration(milliseconds: 30));
      // ignore: unawaited_futures
      undoCubit.refresh();
      await tester.pumpAndSettle();

      // Animator must have cleaned up; no stuck busy flag.
      expect(undoController.isAnimating, isFalse);
      expect(undoController.pendingUndoDirection, 0);
    });
  });
}
