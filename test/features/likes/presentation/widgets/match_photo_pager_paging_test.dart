import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';

import 'match_photo_pager_harness.dart';

/// Where the pager OPENS, and what it forgets when it moves on. Neither is an
/// access rule, but both are the kind of thing that reads as one on a device:
/// landing on the wrong photo looks like a leak, and a page that keeps its
/// zoom looks like the previous photo persisting.
void main() {
  group('the pager opens on the tapped photo', () {
    for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
      testWidgets('$direction — index 1 of 5 reads 2 / 5', (tester) async {
        // Five images opened at 1: a flipped index reads 4 / 5. With three it
        // would read 2 / 3 either way and the mistake would go unnoticed.
        final five = [
          for (var i = 0; i < 5; i++)
            MatchImage(
              id: 'p$i',
              url: 'https://cdn.test/p$i.jpg',
              isProfile: i == 0,
              isBlurred: false,
            ),
        ];
        await tester.pumpWidget(
          host(
            state: const PhotoViewState(phase: PhotoViewPhase.viewing),
            list: five,
            initialIndex: 1,
            direction: direction,
          ),
        );
        await tester.pump();

        expect(find.text('2 / 5'), findsOneWidget);
      });
    }
  });

  group('zoom', () {
    // Asserting the scale after the swipe SETTLES would prove nothing: the
    // page it left is disposed by then, so a rebuilt one reads 1 whether or
    // not anything reset it. The reset has to be caught while the page it
    // applies to is still on screen, sliding away.
    testWidgets('a page left zoomed lets its zoom go on the way out', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.viewing),
          list: images(),
        ),
      );
      await tester.pump();

      InteractiveViewer? viewerFor(String id) {
        final finder = find.descendant(
          of: find.byKey(ValueKey<String>('match-photo-page-$id')),
          matching: find.byType(InteractiveViewer),
        );
        if (finder.evaluate().isEmpty) return null;
        return tester.widget<InteractiveViewer>(finder);
      }

      viewerFor('i0')!.transformationController!.value =
          Matrix4.diagonal3Values(2, 2, 1);
      await tester.pump();
      expect(
        viewerFor('i0')!.transformationController!.value.getMaxScaleOnAxis(),
        2,
      );

      await tester.fling(find.byType(PageView), const Offset(600, 0), 1200);

      // Pump forward until the pager has committed to the next page, while the
      // outgoing one is still mounted.
      var caught = false;
      for (var i = 0; i < 12 && !caught; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final outgoing = viewerFor('i0');
        if (outgoing != null && find.text('2 / 3').evaluate().isNotEmpty) {
          expect(
            outgoing.transformationController!.value.getMaxScaleOnAxis(),
            1,
            reason: 'the page being left must drop its zoom while it is still '
                'on screen, not merely be rebuilt clean later',
          );
          caught = true;
        }
      }
      expect(
        caught,
        isTrue,
        reason: 'never observed the outgoing page while it was still alive — '
            'the assertion above never ran',
      );
      await tester.pumpAndSettle();
    });
  });
}
