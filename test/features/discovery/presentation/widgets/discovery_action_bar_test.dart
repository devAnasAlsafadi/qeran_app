import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_action_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns no translations — `context.tr(key)` falls back to the key
/// string, which is enough for these tests (they assert on icons and
/// callbacks, never on user-visible labels).
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<void> _pumpActionBar(
  WidgetTester tester, {
  VoidCallback? onPass,
  VoidCallback? onUndo,
  VoidCallback? onLike,
  void Function(Offset)? onLikeBurst,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: DiscoveryActionBar(
              onPass: onPass,
              onUndo: onUndo,
              onLike: onLike,
              onLikeBurst: onLikeBurst,
            ),
          ),
        ),
      ),
    ),
  );
  // EasyLocalization initializes async — settle so the action bar
  // renders before we inspect it.
  await tester.pumpAndSettle();
}

/// True if a Transform ancestor exists above the named icon. The
/// `_PressableActionButton`'s AnimatedBuilder only wraps its child in
/// a Transform when there's active motion to render, so this doubles
/// as a "press animation is currently engaged" probe.
bool _iconHasTransformAncestor(WidgetTester tester, IconData icon) {
  return find
      .ancestor(
        of: find.byIcon(icon),
        matching: find.byType(Transform),
      )
      .evaluate()
      .isNotEmpty;
}

/// Resolves an action button by its icon (stable per action), then
/// returns the surrounding InkWell whose `onTap` reflects the button's
/// enabled state.
InkWell _inkForIcon(WidgetTester tester, IconData icon) {
  return tester.widget<InkWell>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(InkWell)),
  );
}

/// Tap-target size of the button carrying [icon].
Size _buttonSize(WidgetTester tester, IconData icon) => tester.getSize(
  find.ancestor(of: find.byIcon(icon), matching: find.byType(InkWell)),
);

InkWell _pass(WidgetTester tester) => _inkForIcon(tester, Icons.close_rounded);
InkWell _like(WidgetTester tester) =>
    _inkForIcon(tester, Icons.favorite_rounded);

/// Undo is no longer a disc in the row — it is a labelled pill that exists
/// ONLY while there is a decision to reverse. Presence IS its enabled state.
Finder _undoPill() => find.byIcon(Icons.undo_rounded);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('the decision row is exactly two discs', (tester) async {
    await _pumpActionBar(
      tester,
      onPass: () {},
      onUndo: () {},
      onLike: () {},
    );

    final discs = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(DiscoveryActionBar),
            matching: find.byType(Material),
          ),
        )
        .where((material) => material.shape is CircleBorder)
        .toList();

    // Undo used to make three. It is a pill above the row now, not a peer of
    // the decision.
    expect(discs, hasLength(2));
  });

  testWidgets('skip is outlined so it reads as a control, not an absence', (
    tester,
  ) async {
    await _pumpActionBar(
      tester,
      onPass: () {},
      onUndo: () {},
      onLike: () {},
    );

    CircleBorder shapeFor(IconData icon) =>
        tester
                .widget<Material>(
                  find
                      .ancestor(
                        of: find.byIcon(icon),
                        matching: find.byType(Material),
                      )
                      .first,
                )
                .shape!
            as CircleBorder;

    // A bare X on white read as neutral system chrome beside a fully branded
    // heart. The outline is a token, never a raw hex.
    expect(shapeFor(Icons.close_rounded).side.color, isNot(Colors.transparent));
    expect(shapeFor(Icons.close_rounded).side.width, greaterThan(0));
    // The filled disc needs no outline — its fill already carries the weight.
    expect(shapeFor(Icons.favorite_rounded).side, BorderSide.none);
  });

  testWidgets('the like glyph is the app-wide heart, not a checkmark', (
    tester,
  ) async {
    await _pumpActionBar(tester, onPass: () {}, onUndo: () {}, onLike: () {});

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('skip and like carry equal weight', (tester) async {
    // They are the two halves of one choice, and skip is the MORE permanent of
    // the two — the server records it forever, while a like is a request the
    // other person can still decline. Making skip the smaller, lighter thing
    // inverted weight against consequence.
    await _pumpActionBar(tester, onPass: () {}, onUndo: () {}, onLike: () {});

    final skip = _buttonSize(tester, Icons.close_rounded);
    final like = _buttonSize(tester, Icons.favorite_rounded);

    expect(skip, like);
    expect(skip.width, skip.height);
  });

  testWidgets('skip and like sit at opposite ends, far apart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpActionBar(tester, onPass: () {}, onUndo: () {}, onLike: () {});

    // Opposite decisions must not be neighbours — a slip on skip is the one
    // mistake whose only remedy is another button entirely.
    final skip = tester.getRect(find.byIcon(Icons.close_rounded));
    final like = tester.getRect(find.byIcon(Icons.favorite_rounded));
    expect((skip.center.dx - like.center.dx).abs(), greaterThan(150));
  });

  testWidgets('the two decisions are told apart by fill, not by size', (
    tester,
  ) async {
    await _pumpActionBar(tester, onPass: () {}, onUndo: () {}, onLike: () {});

    Color surface(IconData icon) => tester
        .widget<Material>(
          find
              .ancestor(of: find.byIcon(icon), matching: find.byType(Material))
              .first,
        )
        .color!;

    expect(surface(Icons.favorite_rounded), isNot(surface(Icons.close_rounded)));
  });

  group('DiscoveryActionBar — per-button enable from nullable callbacks', () {
    testWidgets('all callbacks set → both discs enabled, undo offered',
        (tester) async {
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );

      expect(_pass(tester).onTap, isNotNull);
      expect(_like(tester).onTap, isNotNull);
      expect(_undoPill(), findsOneWidget);
    });

    testWidgets(
        'pass/like null (no active card), undo set → only undo is live',
        (tester) async {
      // The bug-fix scenario: deck just exhausted after passing the
      // last profile. Pass and Like must be inert; Undo must remain
      // tappable so the user can recover.
      await _pumpActionBar(
        tester,
        onPass: null,
        onUndo: () {},
        onLike: null,
      );

      expect(_pass(tester).onTap, isNull);
      expect(_like(tester).onTap, isNull);
      expect(_undoPill(), findsOneWidget);
    });

    testWidgets(
        'nothing to rewind → undo is ABSENT, not sitting there greyed out',
        (tester) async {
      // currentIndex == 0. A permanently disabled control on the first card
      // teaches people to ignore it, and a greyed paper disc on a light
      // background barely reads as a state at all.
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: null,
        onLike: () {},
      );

      expect(_pass(tester).onTap, isNotNull);
      expect(_like(tester).onTap, isNotNull);
      expect(_undoPill(), findsNothing);
    });

    testWidgets('all callbacks null → discs disabled, undo absent',
        (tester) async {
      await _pumpActionBar(tester);

      expect(_pass(tester).onTap, isNull);
      expect(_like(tester).onTap, isNull);
      expect(_undoPill(), findsNothing);
    });

    testWidgets('tapping undo invokes only the undo callback', (tester) async {
      var passCalls = 0;
      var undoCalls = 0;
      var likeCalls = 0;

      await _pumpActionBar(
        tester,
        onPass: () => passCalls++,
        onUndo: () => undoCalls++,
        onLike: () => likeCalls++,
      );

      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      expect(undoCalls, 1);
      expect(passCalls, 0);
      expect(likeCalls, 0);
    });

    testWidgets('tapping like invokes only the like callback', (tester) async {
      var likeCalls = 0;
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () => likeCalls++,
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(likeCalls, 1);
    });

    testWidgets('tapping pass invokes only the pass callback', (tester) async {
      var passCalls = 0;
      await _pumpActionBar(
        tester,
        onPass: () => passCalls++,
        onUndo: () {},
        onLike: () {},
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(passCalls, 1);
    });
  });

  group('DiscoveryActionBar — press micro-interactions', () {
    testWidgets(
        'enabled like button engages a press animation at some point',
        (tester) async {
      // Probing exact scale mid-animation is brittle (the gesture
      // recognizer's internal `kPressTimeout` cancels a held tap during
      // `pumpAndSettle`, which then triggers the release animation —
      // scale lands back at 1.0). Instead we verify the looser
      // contract: tapping an enabled button inserts a Transform above
      // the icon at SOME point during the gesture lifecycle.
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );

      // Idle: AnimatedBuilder short-circuits — no Transform.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.favorite_rounded),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      var sawTransform = false;
      for (var i = 0; i < 30 && !sawTransform; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        sawTransform = find
            .ancestor(
              of: find.byIcon(Icons.favorite_rounded),
              matching: find.byType(Transform),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(sawTransform, isTrue,
          reason: 'press animation should engage on enabled tap');

      await tester.pumpAndSettle();
    });

    testWidgets('disabled buttons do NOT animate on press', (tester) async {
      await _pumpActionBar(tester); // all callbacks null

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.favorite_rounded)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // No transform was inserted — AnimatedBuilder short-circuits
      // because disabled buttons skip the animation path.
      final transforms = tester
          .widgetList<Transform>(
            find.ancestor(
              of: find.byIcon(Icons.favorite_rounded),
              matching: find.byType(Transform),
            ),
          )
          .toList();
      expect(transforms, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('rapid tap on enabled like still resolves to scale=1.0',
        (tester) async {
      // Sanity: AnimationController disposal works after a quick tap.
      var likeCalls = 0;
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () => likeCalls++,
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(likeCalls, 2, reason: 'each tap fires the callback');
      // No ticker / leak — pumpAndSettle would assert if any timer
      // were still pending.
    });
  });

  group('DiscoveryActionBar — independent press animations', () {
    /// Holds a press on `iconBeingPressed` long enough for the
    /// press-down animation to make visible progress, then asserts
    /// that ONLY the pressed icon has a Transform ancestor. The other
    /// two buttons must stay visually inert. Uses a held gesture
    /// instead of `tester.tap` because Pass/Undo have no release-
    /// overshoot — a rapid tester.tap completes both `onTapDown` and
    /// `onTapUp` before the press-down can advance past scale = 1.0,
    /// so the release tween's begin == end and no visible motion
    /// occurs (a realistic user tap holds 50+ ms).
    Future<void> assertOnlyOneAnimates(
      WidgetTester tester, {
      required IconData iconBeingPressed,
    }) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(iconBeingPressed)),
      );
      // The Tooltip's LongPressGestureRecognizer competes with the
      // InkWell's tap in the arena — the tap is not accepted (and
      // onTapDown is not fired) until the press deadline expires
      // (kPressTimeout ~ 100 ms). Pump past it so the press-down
      // animation has actually started, then probe.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      expect(
        _iconHasTransformAncestor(tester, iconBeingPressed),
        isTrue,
        reason: 'pressed $iconBeingPressed should be mid-animation',
      );
      for (final other in <IconData>[
        Icons.close_rounded,
        Icons.favorite_rounded,
      ]) {
        if (other == iconBeingPressed) continue;
        expect(
          _iconHasTransformAncestor(tester, other),
          isFalse,
          reason:
              'pressing $iconBeingPressed must not animate $other',
        );
      }

      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('pressing Like only animates Like', (tester) async {
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );
      await assertOnlyOneAnimates(tester,
          iconBeingPressed: Icons.favorite_rounded);
    });

    testWidgets('pressing Pass only animates Pass', (tester) async {
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );
      await assertOnlyOneAnimates(tester,
          iconBeingPressed: Icons.close_rounded);
    });

    // Undo has no equivalent case any more: it is a pill outside the row, not
    // a disc sharing the decision's press vocabulary.
  });

  group('DiscoveryActionBar — flying-mark burst callback', () {
    testWidgets('enabled Like tap fires onLikeBurst with a global Offset',
        (tester) async {
      Offset? receivedOrigin;
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
        onLikeBurst: (origin) => receivedOrigin = origin,
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(receivedOrigin, isNotNull);
      // Origin is in screen-space and within the test surface (which
      // defaults to ~800x600 in flutter_test).
      expect(receivedOrigin!.dx, greaterThan(0));
      expect(receivedOrigin!.dy, greaterThan(0));
    });

    testWidgets('disabled Like does NOT fire onLikeBurst', (tester) async {
      Offset? receivedOrigin;
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: null, // disabled
        onLikeBurst: (origin) => receivedOrigin = origin,
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(receivedOrigin, isNull);
    });

    testWidgets('Pass/Undo taps do NOT fire onLikeBurst', (tester) async {
      var bursts = 0;
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
        onLikeBurst: (_) => bursts++,
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      expect(bursts, 0);
    });
  });

  group('DiscoveryActionBar — Like halo ring', () {
    /// The halo's outer wrapper is a Stack with `clipBehavior:
    /// Clip.none`. Only the Like button instantiates this — Pass /
    /// Undo wrap their Tooltip directly. This finder counts the
    /// Stacks that ARE the halo wrapper (not Stacks elsewhere in the
    /// tree, like the Scaffold's overlay).
    int stacksAboveIcon(WidgetTester tester, IconData icon) {
      return tester
          .widgetList<Stack>(
            find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(Stack),
            ),
          )
          .where((s) => s.clipBehavior == Clip.none)
          .length;
    }

    testWidgets('Like button wraps in Clip.none Stack for the halo',
        (tester) async {
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );

      expect(stacksAboveIcon(tester, Icons.favorite_rounded), 1,
          reason: 'Like wraps in one Clip.none Stack to host the halo');
      expect(stacksAboveIcon(tester, Icons.close_rounded), 0,
          reason: 'Pass has no halo wrapper');
      expect(stacksAboveIcon(tester, Icons.replay_rounded), 0,
          reason: 'Undo has no halo wrapper');
    });

    testWidgets(
        'tapping enabled Like fires the halo (visible Container mid-anim)',
        (tester) async {
      await _pumpActionBar(
        tester,
        onPass: () {},
        onUndo: () {},
        onLike: () {},
      );

      // The halo wrapper Stack's first child is the _HaloRing (an
      // IgnorePointer wrapping an AnimatedBuilder). Before the tap, the
      // ring builder short-circuits to SizedBox.shrink — no Container.
      // Mid-animation, a circle Container appears.
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      var sawHaloContainer = false;
      for (var i = 0; i < 30 && !sawHaloContainer; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        sawHaloContainer = find
            .descendant(
              of: find.byIcon(Icons.favorite_rounded),
              matching: find.byType(Container),
            )
            .evaluate()
            // Halo Container is a SIBLING of the icon, not an ancestor
            // — find the halo Container as a descendant of the
            // wrapping Clip.none Stack.
            .isNotEmpty;
        // Above check works because the icon itself has no Container
        // ancestor; but the halo Container lives in the SAME Stack.
        // A more direct probe: count the IgnorePointer descendants of
        // the wrapping Stack — it's there only during the halo run.
        final stackFinder = find.ancestor(
          of: find.byIcon(Icons.favorite_rounded),
          matching: find.byType(Stack),
        );
        if (stackFinder.evaluate().isNotEmpty) {
          final ignorePointersInsideStack = find.descendant(
            of: stackFinder.first,
            matching: find.byType(IgnorePointer),
          );
          if (ignorePointersInsideStack.evaluate().isNotEmpty) {
            // Check that the IgnorePointer's builder actually emitted
            // a non-shrink child by looking for any Container under
            // the wrapping Stack.
            final containersInStack = find.descendant(
              of: stackFinder.first,
              matching: find.byType(Container),
            );
            sawHaloContainer = containersInStack.evaluate().isNotEmpty;
          }
        }
      }
      expect(sawHaloContainer, isTrue,
          reason: 'halo ring should emit a Container during its run');

      await tester.pumpAndSettle();
    });

    testWidgets('disabled Like does NOT fire the halo', (tester) async {
      await _pumpActionBar(tester); // all callbacks null → all disabled
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();
      final stackFinder = find.ancestor(
        of: find.byIcon(Icons.favorite_rounded),
        matching: find.byType(Stack),
      );
      if (stackFinder.evaluate().isNotEmpty) {
        // Halo wrapper exists, but no Container should have been
        // emitted because the controller never started.
        final containers = find.descendant(
          of: stackFinder.first,
          matching: find.byType(Container),
        );
        expect(containers, findsNothing);
      }
    });
  });
}
