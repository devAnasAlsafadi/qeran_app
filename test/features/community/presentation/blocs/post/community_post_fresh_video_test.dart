import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';

import '../../../fixtures/community_post_fixtures.dart';
import 'post_cubit_harness.dart';

/// S19: the post screen's video link, read again with the post.
void main() {
  test('the fresh copy of the post, and its video', () async {
    final stale = testPost(media: CommunitySingleVideo(testVideo()));
    final video = testVideo(urlExpiresAt: DateTime.utc(2100));
    final h = PostHarness(post: stale);
    addTearDown(h.dispose);
    h.readAnswers(Right(testPost(media: CommunitySingleVideo(video))));

    expect(await h.cubit.freshVideo(), video);
    expect(h.post.media, CommunitySingleVideo(video));
  });
}
