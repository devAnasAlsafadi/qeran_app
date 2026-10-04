import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';

import '../../../fixtures/community_post_fixtures.dart';
import 'feed_cubit_harness.dart';

/// S19: a card's lapsed video link, read again through the feed.
void main() {
  late FeedHarness h;

  setUp(() => h = FeedHarness());
  tearDown(() => h.dispose());

  test("the post's video, read again", () async {
    final video = testVideo(urlExpiresAt: DateTime.utc(2100));
    when(() => h.getPost(4)).thenAnswer(
      (_) async => Right(testPost(id: 4, media: CommunitySingleVideo(video))),
    );

    expect(await h.cubit.freshVideo(4), video);
  });

  test("a read that fails, or a post with no video: none", () async {
    when(
      () => h.getPost(4),
    ).thenAnswer((_) async => const Left(OfflineFailure()));
    expect(await h.cubit.freshVideo(4), isNull);

    when(() => h.getPost(5)).thenAnswer((_) async => Right(testPost(id: 5)));
    expect(await h.cubit.freshVideo(5), isNull);
  });
}
