import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/models/community_config_model.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';

import '../../fixtures/community_fixtures.dart';

void main() {
  group('CommunityConfigModel', () {
    test('every built limit is read as sent', () {
      final c = CommunityConfigModel.fromJson(config()).toEntity();

      expect(c.commentMaxLength, 500);
      expect(c.postTextMaxLength, 2000);
      expect(c.maxImagesPerPost, 10);
      expect(c.maxImageSizeBytes, 5242880);
      expect(c.allowedImageTypes, ['jpg', 'jpeg', 'png']);
      expect(c.allowedVideoTypes, ['mp4', 'mov']);
      expect(c.maxVideoDurationSeconds, 60);
      expect(c.maxVideoSizeBytes, 104857600);
      expect(
        c.videoTarget,
        const CommunityVideoTarget(maxHeight: 1280, bitrateKbps: 2500, codec: 'h264'),
      );
      expect(c.videoEnabled, isTrue);
    });

    test('videoEnabled false (until Bunny is set up) is kept', () {
      final c = CommunityConfigModel.fromJson(config(videoEnabled: false))
          .toEntity();

      expect(c.videoEnabled, isFalse);
    });

    test('nothing is invented for a missing field', () {
      final c = CommunityConfigModel.fromJson(const {}).toEntity();

      expect(c, const CommunityConfig());
      expect(c.commentMaxLength, isNull);
      expect(c.videoTarget, isNull);
      expect(c.allowedImageTypes, isEmpty);
      expect(c.videoEnabled, isFalse);
    });

    test('file types are trimmed and lower-cased, blanks dropped', () {
      final c = CommunityConfigModel.fromJson({
        'allowedImageTypes': [' JPG ', 'png', '', null],
      }).toEntity();

      expect(c.allowedImageTypes, ['jpg', 'png']);
    });
  });
}
