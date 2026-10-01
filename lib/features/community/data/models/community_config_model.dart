import '../../domain/entities/community_config.dart';
import '../json_parsers.dart';

/// Wire model for `GET community/config` (contract §8). Every field is read
/// as sent; a missing one stays null (or empty, or false for
/// `videoEnabled`) — never replaced by a number of our own.
class CommunityConfigModel {
  final int? commentMaxLength;
  final int? postTextMaxLength;
  final int? maxImagesPerPost;
  final int? maxImageSizeBytes;
  final List<String> allowedImageTypes;
  final List<String> allowedVideoTypes;
  final int? maxVideoDurationSeconds;
  final int? maxVideoSizeBytes;
  final Map<String, dynamic>? videoTarget;
  final bool videoEnabled;

  const CommunityConfigModel({
    required this.commentMaxLength,
    required this.postTextMaxLength,
    required this.maxImagesPerPost,
    required this.maxImageSizeBytes,
    required this.allowedImageTypes,
    required this.allowedVideoTypes,
    required this.maxVideoDurationSeconds,
    required this.maxVideoSizeBytes,
    required this.videoTarget,
    required this.videoEnabled,
  });

  factory CommunityConfigModel.fromJson(Map<String, dynamic> json) =>
      CommunityConfigModel(
        commentMaxLength: parseNullableInt(json['commentMaxLength']),
        postTextMaxLength: parseNullableInt(json['postTextMaxLength']),
        maxImagesPerPost: parseNullableInt(json['maxImagesPerPost']),
        maxImageSizeBytes: parseNullableInt(json['maxImageSizeBytes']),
        allowedImageTypes: parseLowerStringList(json['allowedImageTypes']),
        allowedVideoTypes: parseLowerStringList(json['allowedVideoTypes']),
        maxVideoDurationSeconds:
            parseNullableInt(json['maxVideoDurationSeconds']),
        maxVideoSizeBytes: parseNullableInt(json['maxVideoSizeBytes']),
        videoTarget: parseNullableMap(json['videoTarget']),
        videoEnabled: parseBool(json['videoEnabled']),
      );

  CommunityConfig toEntity() => CommunityConfig(
        commentMaxLength: commentMaxLength,
        postTextMaxLength: postTextMaxLength,
        maxImagesPerPost: maxImagesPerPost,
        maxImageSizeBytes: maxImageSizeBytes,
        allowedImageTypes: allowedImageTypes,
        allowedVideoTypes: allowedVideoTypes,
        maxVideoDurationSeconds: maxVideoDurationSeconds,
        maxVideoSizeBytes: maxVideoSizeBytes,
        videoTarget: switch (videoTarget) {
          final Map<String, dynamic> t => CommunityVideoTarget(
              maxHeight: parseNullableInt(t['maxHeight']),
              bitrateKbps: parseNullableInt(t['bitrateKbps']),
              codec: parseNullableString(t['codec']),
            ),
          null => null,
        },
        videoEnabled: videoEnabled,
      );
}
