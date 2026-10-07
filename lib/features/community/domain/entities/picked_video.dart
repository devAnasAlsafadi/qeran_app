import '../ports/video_compressor.dart';

/// A video container the server takes, as the file's bytes say (plan §3.3).
enum VideoContainer {
  mp4(extension: 'mp4', mimeType: 'video/mp4'),
  quickTime(extension: 'mov', mimeType: 'video/quicktime');

  const VideoContainer({required this.extension, required this.mimeType});

  final String extension;

  /// What 6.8's `contentType` says.
  final String mimeType;

  /// Whether config's `allowedVideoTypes` (lower case, no dot) takes it.
  bool allowedBy(List<String> types) => types.contains(extension);
}

/// Her picked video as the composer holds it: the file, its container, and
/// its facts (length, display size, bytes), read before anything is sent.
class PickedVideo {
  final String path;
  final VideoContainer container;
  final VideoFileInfo info;

  const PickedVideo({
    required this.path,
    required this.container,
    required this.info,
  });

  /// Whole seconds, rounded to the nearest, as checked and sent (S4).
  int get durationSeconds => (info.duration.inMilliseconds / 1000).round();
}
