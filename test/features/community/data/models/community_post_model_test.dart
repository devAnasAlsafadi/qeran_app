import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/models/community_post_model.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';

import '../../fixtures/community_fixtures.dart';

CommunityPost parse(Map<String, dynamic> json) =>
    CommunityPostModel.fromJson(json).toEntity();

void main() {
  group('CommunityPostModel', () {
    test('a text post: every field, createdAt in UTC, no media', () {
      final p = parse(post());

      expect(p.id, 123);
      expect(p.text, 'الاستخارة والاستشارة');
      expect(p.media, const CommunityNoMedia());
      expect(p.likeCount, 128);
      expect(p.likedByMe, isFalse);
      expect(p.commentCount, 14);
      expect(p.createdAt?.toUtc(), DateTime.utc(2026, 9, 30, 8, 15));
      expect(p.canDelete, isFalse);
      expect(p.status, CommunityPostStatus.published);
    });

    test('the matchmaker author keeps her unblurred avatar path', () {
      final a = parse(post()).author;

      expect(a.id, 'mm-1');
      expect(a.displayName, 'هدى');
      expect(a.isMatchmaker, isTrue);
      expect(a.profileImageUrl, '/api/community/avatars/mm-1');
    });

    test('images keep her order and their thumbnail, width and height', () {
      final p = parse(post(media: [
        imageMedia(width: 1080, height: 1350),
        imageMedia(width: 1600, height: 900),
      ]));

      final set = p.media as CommunityImageSet;
      expect(set.images.map((i) => i.width), [1080, 1600]);
      expect(set.images.first.url, '/api/community/media/img-1080');
      expect(set.images.first.thumbnailUrl, '/api/community/media/img-1080/thumb');
      expect(set.images.last.height, 900);
    });

    test('a signed video: url, poster, hls, size after rotation, expiry', () {
      final v = (parse(post(media: [videoMedia()])).media as CommunitySingleVideo)
          .video;

      expect(v.url, endsWith('/play_720p.mp4'));
      expect(v.posterUrl, endsWith('/thumbnail.jpg'));
      expect(v.hlsUrl, endsWith('/playlist.m3u8'));
      expect((v.width, v.height), (1080, 1920));
      expect(v.duration, const Duration(seconds: 44));
      expect(v.urlExpiresAt?.toUtc(), DateTime.utc(2026, 10, 1, 14, 30));
    });

    test('a video that is not ready yet has a null url', () {
      final p = parse(post(media: [videoMedia(url: null)], status: 'Processing'));

      expect((p.media as CommunitySingleVideo).video.url, isNull);
      expect(p.status, CommunityPostStatus.processing);
    });

    test('images and a video together (never sent) → the video alone', () {
      final p = parse(post(media: [imageMedia(), videoMedia()]));

      expect(p.media, isA<CommunitySingleVideo>());
    });

    test('an unknown media type and an image without a url are dropped', () {
      final p = parse(post(media: [
        {'type': 'Audio', 'url': '/x'},
        {...imageMedia(), 'url': null},
        imageMedia(width: 1080, height: 1080),
      ]));

      expect((p.media as CommunityImageSet).images, hasLength(1));
    });

    test('ids sent as strings and a missing createdAt are tolerated', () {
      final p = parse({...post(), 'id': '77', 'createdAt': null});

      expect(p.id, 77);
      expect(p.createdAt, isNull);
    });
  });

  group('CommunityPostStatus.fromWire', () {
    test('the three built values, any case', () {
      expect(CommunityPostStatus.fromWire('Published'),
          CommunityPostStatus.published);
      expect(CommunityPostStatus.fromWire('processing'),
          CommunityPostStatus.processing);
      expect(CommunityPostStatus.fromWire('FAILED'), CommunityPostStatus.failed);
    });

    test('missing or new values are unknown, never published', () {
      expect(CommunityPostStatus.fromWire(null), CommunityPostStatus.unknown);
      expect(CommunityPostStatus.fromWire('Archived'),
          CommunityPostStatus.unknown);
    });
  });
}
