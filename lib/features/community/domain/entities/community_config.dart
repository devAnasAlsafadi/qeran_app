import 'package:equatable/equatable.dart';

/// The server's Community limits (`GET community/config`, contract §8). They
/// change without an app release, so **no limit is ever hard-coded**: every
/// check and every number in the copy reads this.
///
/// A limit the server didn't send is null, and the app then leaves that check
/// to the server rather than invent a number. [videoEnabled] is false unless
/// the server says true — the video option is never offered unbacked.
class CommunityConfig extends Equatable {
  final int? commentMaxLength;
  final int? postTextMaxLength;
  final int? maxImagesPerPost;
  final int? maxImageSizeBytes;

  /// File extensions, lower case, without the dot (`jpg`, `png`, `mp4`…).
  final List<String> allowedImageTypes;
  final List<String> allowedVideoTypes;
  final int? maxVideoDurationSeconds;
  final int? maxVideoSizeBytes;
  final CommunityVideoTarget? videoTarget;
  final bool videoEnabled;

  const CommunityConfig({
    this.commentMaxLength,
    this.postTextMaxLength,
    this.maxImagesPerPost,
    this.maxImageSizeBytes,
    this.allowedImageTypes = const [],
    this.allowedVideoTypes = const [],
    this.maxVideoDurationSeconds,
    this.maxVideoSizeBytes,
    this.videoTarget,
    this.videoEnabled = false,
  });

  @override
  List<Object?> get props => [
        commentMaxLength,
        postTextMaxLength,
        maxImagesPerPost,
        maxImageSizeBytes,
        allowedImageTypes,
        allowedVideoTypes,
        maxVideoDurationSeconds,
        maxVideoSizeBytes,
        videoTarget,
        videoEnabled,
      ];
}

/// What on-device compression aims for before upload (D22): the longest side
/// at most [maxHeight], about [bitrateKbps], in [codec].
class CommunityVideoTarget extends Equatable {
  final int? maxHeight;
  final int? bitrateKbps;
  final String? codec;

  const CommunityVideoTarget({this.maxHeight, this.bitrateKbps, this.codec});

  @override
  List<Object?> get props => [maxHeight, bitrateKbps, codec];
}
