import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';
import 'package:qeran/features/likes/presentation/widgets/match_photo_page.dart';

import 'match_photo_pager_harness.dart';

/// What the pager is allowed to FETCH. Asserted on the URLs image providers
/// actually hold, so a page that finds some other route to an original still
/// fails these.
void main() {
  group('a locked window blocks every page', () {
    // `consumed` is the dangerous one: the member HAS opened these photos
    // once, so the originals are the most likely thing still lying around.
    for (final phase in [
      PhotoViewPhase.available,
      PhotoViewPhase.consumed,
      PhotoViewPhase.failure,
      PhotoViewPhase.loading,
    ]) {
      testWidgets('$phase — no original is requested by any page', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(state: PhotoViewState(phase: phase), list: images()),
        );
        await tester.pump();

        expect(
          requestedUrls(tester).intersection(originals),
          isEmpty,
          reason: 'phase $phase must not fetch original bytes for ANY page',
        );
      });
    }

    testWidgets('swiping to a page does not unlock it', (tester) async {
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.consumed),
          list: images(),
        ),
      );
      await tester.pump();
      await swipeForward(tester, TextDirection.rtl);

      expect(
        requestedUrls(tester).intersection(originals),
        isEmpty,
        reason: 'the page a swipe LANDS on is the one the old tile gate could '
            'never refuse — it must still be locked',
      );
    });
  });

  group('per-image blur is honoured page by page', () {
    // With no accepted exchange the scope stands back and the server's own
    // per-image flags decide, so one page may be clear and the next blurred.
    testWidgets('a blurred page shows its blurred rendition, not the original', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.unavailable),
          list: images(secondIsBlurred: true),
        ),
      );
      await tester.pump();
      await swipeForward(tester, TextDirection.rtl);
      await tester.pump();

      final urls = requestedUrls(tester);
      expect(
        urls,
        contains(blurred1),
        reason: 'the server rendition is what a blurred page may show',
      );
      expect(
        urls,
        isNot(contains(original1)),
        reason: 'swiping onto a blurred photo must not fetch its original',
      );
    });

    testWidgets('a clear page in the same list still shows', (tester) async {
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.unavailable),
          list: images(secondIsBlurred: true),
        ),
      );
      await tester.pump();

      expect(
        requestedUrls(tester),
        contains(original0),
        reason: 'the blur is per image — locking the whole pager instead would '
            'pass the test above for the wrong reason',
      );
    });
  });

  group('expiry mid-swipe', () {
    // At rest this pager holds exactly ONE page, so asserting "every page is
    // locked" while parked proves nothing — it would pass with no enforcement
    // at all. Two pages coexist only DURING the flight between them, so that
    // is where the window has to be caught.
    testWidgets('locks BOTH pages while a swipe is still in flight', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.viewing),
          list: images(),
          initialIndex: 1,
        ),
      );
      await tester.pump();

      await tester.fling(find.byType(PageView), const Offset(600, 0), 1200);
      await tester.pump(const Duration(milliseconds: 16));

      // Sanity, and the thing that makes the assertion below mean anything:
      // two pages really are live and really are showing their originals.
      expect(
        find.byType(MatchPhotoPage),
        findsNWidgets(2),
        reason: 'the mid-flight window is the only moment two pages exist',
      );
      expect(
        requestedUrls(tester).intersection(originals),
        hasLength(2),
        reason: 'both live pages hold an original before the window ends',
      );

      // The window ends with the swipe still travelling.
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.consumed),
          list: images(),
          initialIndex: 1,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byType(MatchPhotoPage),
        findsNWidgets(2),
        reason: 'still mid-flight — otherwise this proves nothing again',
      );
      expect(
        requestedUrls(tester).intersection(originals),
        isEmpty,
        reason: 'BOTH pages must re-lock. A policy snapshot taken per page '
            'would leave the one sliding away still holding its original',
      );
      await tester.pumpAndSettle();
    });

    testWidgets('closes the viewer once the window ends', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.viewing),
          list: images(),
          onClose: () => closed++,
        ),
      );
      await tester.pump();
      expect(closed, 0);

      await tester.pumpWidget(
        host(
          state: const PhotoViewState(phase: PhotoViewPhase.consumed),
          list: images(),
          onClose: () => closed++,
        ),
      );
      await tester.pumpAndSettle();

      expect(closed, 1, reason: 'fired, and fired only once');
    });
  });
}
