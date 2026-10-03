import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/widgets/paginated_list.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/domain/entities/community_page.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../fixtures/community_post_fixtures.dart';
import '../blocs/feed/feed_cubit_harness.dart';
import 'feed_screen_rig.dart';

const _gateCopy = {
  ProfileStatus.pendingReview:
      'Your profile is under review. You can read '
      'now; liking and commenting open once it’s approved.',
  ProfileStatus.hidden: 'Your profile is hidden, so you can read only.',
  ProfileStatus.rejected:
      'Your profile was declined — contact your '
      'matchmaker. You can read only.',
};

void main() {
  late FeedHarness h;
  setUpAll(initShippedStrings);
  setUp(() async {
    h = FeedHarness();
    h.page(1, [testPost(id: 1)], totalPages: 2);
    await h.cubit.load();
  });
  tearDown(() => h.dispose());

  testWidgets('B8: the next page loading', (tester) async {
    final never = Completer<Either<Failure, CommunityPage<CommunityPost>>>();
    when(() => h.getFeed(page: 2)).thenAnswer((_) => never.future);
    await pumpFeed(tester, h);

    unawaited(h.cubit.loadMore());
    // The new state lands in a microtask; the frame after it shows it.
    await tester.pump();
    await tester.pump();

    expect(find.byType(LoadMoreFooter), findsOneWidget);
  });

  testWidgets('B9: the next page failed, and its retry asks again', (
    tester,
  ) async {
    h.pageFails(2);
    await h.cubit.loadMore();
    await pumpFeed(tester, h);
    expect(find.text('Couldn’t load more.'), findsOneWidget);
    expect(
      tester.getCenter(find.text('Retry')).dy,
      closeTo(tester.getCenter(find.text('Couldn’t load more.')).dy, 2),
      reason: "Retry stays on the message's line",
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    verify(() => h.getFeed(page: 2)).called(2);
  });

  group('B11: the gate notice, exactly when the member is gated (S10)', () {
    for (final MapEntry(key: status, value: text) in _gateCopy.entries) {
      testWidgets('${status.name}: its own words', (tester) async {
        await pumpFeed(tester, h, gate: status);

        expect(find.text(text), findsOneWidget);
      });
    }

    for (final status in [ProfileStatus.visible, ProfileStatus.unknown, null]) {
      testWidgets('${status?.name ?? 'not known yet'}: no notice', (
        tester,
      ) async {
        await pumpFeed(tester, h, gate: status);

        for (final text in _gateCopy.values) {
          expect(find.text(text), findsNothing);
        }
      });
    }
  });

  testWidgets('B12: gated, Like is dimmed, says why and sends nothing', (
    tester,
  ) async {
    await pumpFeed(tester, h, gate: ProfileStatus.pendingReview);

    final dimmer = tester.widget<Opacity>(
      find.ancestor(
        of: find.byIcon(Icons.favorite_border_rounded),
        matching: find.byType(Opacity),
      ),
    );
    expect(dimmer.opacity, 0.4);
    await tester.tap(find.text('Like'));
    await tester.pump();

    expect(
      find.text('You can like once your profile is approved.'),
      findsOneWidget,
    );
    verifyNever(() => h.setLike(any(), liked: any(named: 'liked')));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('B13: a like that fails is taken back, with a toast', (
    tester,
  ) async {
    h.likeAnswers(1, const Left(ServerFailure(message: 'x')));
    await pumpFeed(tester, h);

    await tester.tap(find.text('Like'));
    await tester.pump();

    expect(
      find.text('Couldn’t save your like. Please try again.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  group('J1: an iPhone SE (375 × 667), gated, nothing overflows', () {
    for (final locale in feedLocales.keys) {
      testWidgets(locale.languageCode, (tester) async {
        h.page(1, [
          testPost(id: 2, author: ummAbdulrahman, likeCount: 1240),
          testPost(id: 1, media: CommunityImageSet([testImage()])),
        ]);
        await h.cubit.refresh();
        await pumpFeed(
          tester,
          h,
          locale: locale,
          gate: ProfileStatus.pendingReview,
          size: const Size(375, 667),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
