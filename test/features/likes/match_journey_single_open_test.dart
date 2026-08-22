import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_disclosure.dart';
import 'package:qeran/features/likes/presentation/blocs/likes_state.dart';
import 'package:qeran/features/likes/presentation/widgets/match_journey_scope.dart';

/// One card open at a time. The scope is the whole mechanism, and the state
/// behind it lives in the cubit — see `openJourneyLikeRequestId` there for
/// why it is not held in the list.
Widget _twoCards({
  required int? openId,
  required void Function(int, bool) onOpenChanged,
}) => MaterialApp(
  home: Scaffold(
    body: MatchJourneyScope(
      openLikeRequestId: openId,
      onOpenChanged: onOpenChanged,
      child: Builder(
        builder: (context) {
          final scope = MatchJourneyScope.maybeOf(context)!;
          return Column(
            children: [
              for (final id in [1, 2])
                QeranDisclosure(
                  expanded: scope.isOpen(id),
                  onExpandedChanged: (open) => scope.onOpenChanged(id, open),
                  summary: Text('summary$id'),
                  child: Text('body$id'),
                ),
            ],
          );
        },
      ),
    ),
  ),
);

void main() {
  group('MatchJourneyScope', () {
    test('only the named card reads as open', () {
      const scope = MatchJourneyScope(
        openLikeRequestId: 7,
        onOpenChanged: _noop,
        child: SizedBox(),
      );

      expect(scope.isOpen(7), isTrue);
      expect(scope.isOpen(8), isFalse);
    });

    test('nothing is open when the id is null', () {
      const scope = MatchJourneyScope(
        openLikeRequestId: null,
        onOpenChanged: _noop,
        child: SizedBox(),
      );

      expect(scope.isOpen(7), isFalse);
    });

    // Cards rebuild constantly as matches refresh; only a change of WHICH one
    // is open should push a rebuild through the scope.
    test('it notifies only when the open card changes', () {
      const a = MatchJourneyScope(
        openLikeRequestId: 1,
        onOpenChanged: _noop,
        child: SizedBox(),
      );
      const same = MatchJourneyScope(
        openLikeRequestId: 1,
        onOpenChanged: _noop,
        child: SizedBox(),
      );
      const other = MatchJourneyScope(
        openLikeRequestId: 2,
        onOpenChanged: _noop,
        child: SizedBox(),
      );

      expect(a.updateShouldNotify(same), isFalse);
      expect(other.updateShouldNotify(a), isTrue);
    });
  });

  group('coordination', () {
    testWidgets('opening one closes the other', (tester) async {
      int? open;
      Future<void> pump() => tester.pumpWidget(
        _twoCards(
          openId: open,
          onOpenChanged: (id, isOpen) => open = isOpen ? id : null,
        ),
      );

      await pump();
      await tester.tap(find.text('summary1'));
      await pump();
      await tester.pumpAndSettle();
      expect(find.text('body1'), findsOneWidget);
      expect(find.text('body2'), findsNothing);

      await tester.tap(find.text('summary2'));
      await pump();
      await tester.pumpAndSettle();
      expect(find.text('body1'), findsNothing);
      expect(find.text('body2'), findsOneWidget);
    });

    testWidgets('tapping the open one closes it and leaves none open', (
      tester,
    ) async {
      int? open = 1;
      await tester.pumpWidget(
        _twoCards(
          openId: open,
          onOpenChanged: (id, isOpen) => open = isOpen ? id : null,
        ),
      );

      await tester.tap(find.text('summary1'));
      await tester.pumpWidget(
        _twoCards(openId: open, onOpenChanged: (_, _) {}),
      );
      await tester.pumpAndSettle();

      expect(open, isNull);
      expect(find.text('body1'), findsNothing);
      expect(find.text('body2'), findsNothing);
    });
  });

  // The finding this whole design exists for: `loadMatches` emits `loading`
  // before it fetches, so the list is torn down and rebuilt on every refresh.
  // State held there would close the open card; state on the cubit survives.
  group('surviving a refresh', () {
    const openState = LikesState(
      matchesStatus: LikesAsyncStatus.loaded,
      openJourneyLikeRequestId: 5,
    );

    test('the open card outlives a loading cycle', () {
      final loading = openState.copyWith(
        matchesStatus: LikesAsyncStatus.loading,
      );
      final reloaded = loading.copyWith(matchesStatus: LikesAsyncStatus.loaded);

      expect(loading.isJourneyOpen(5), isTrue);
      expect(reloaded.isJourneyOpen(5), isTrue);
    });

    test('closing needs the explicit clear, not a null', () {
      expect(
        openState.copyWith(openJourneyLikeRequestId: null).isJourneyOpen(5),
        isTrue,
        reason: 'a bare null must not be mistaken for "close it"',
      );
      expect(
        openState.copyWith(clearOpenJourney: true).openJourneyLikeRequestId,
        isNull,
      );
    });

    test('nothing is open by default', () {
      expect(const LikesState().openJourneyLikeRequestId, isNull);
      expect(const LikesState().isJourneyOpen(1), isFalse);
    });
  });
}

void _noop(int id, bool open) {}
