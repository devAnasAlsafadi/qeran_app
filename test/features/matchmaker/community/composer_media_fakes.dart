import 'package:qeran/core/domain/upload.dart';
import 'package:qeran/features/community/domain/entities/picked_image.dart';
import 'package:qeran/features/community/domain/entities/picked_video.dart';
import 'package:qeran/features/community/domain/ports/media_inspector.dart';
import 'package:qeran/features/community/domain/ports/video_compressor.dart';
import 'package:qeran/features/matchmaker/community/presentation/services/community_media_picker.dart';

/// Every file is a 100-byte JPEG unless [files] says otherwise (null: not
/// a type the server takes).
class FakeInspector implements MediaInspector {
  final files = <String, PickedImage?>{};

  @override
  Future<PickedImage?> inspectImage(String path) async =>
      files.containsKey(path) ? files[path] : jpeg(path);

  /// Every video is an MP4 unless [videos] says otherwise.
  final videos = <String, VideoContainer?>{};

  @override
  Future<VideoContainer?> videoContainerOf(String path) async =>
      videos.containsKey(path) ? videos[path] : VideoContainer.mp4;
}

/// A picked JPEG at [path], [size] bytes.
PickedImage jpeg(String path, {int size = 100}) => PickedImage(
  file: UploadFile(
    path: path,
    fileName: 'image.jpg',
    contentType: 'image/jpeg',
  ),
  format: ImageFormat.jpeg,
  sizeBytes: size,
);

/// The phone's picker over scripted answers; [limits] keeps each gallery
/// pick's limit.
class FakePicker implements CommunityMediaPicker {
  List<String> gallery = const [];
  String? camera;
  MediaAccessDenied? refuses;
  final limits = <int?>[];

  @override
  Future<List<String>> pickImages({int? limit}) async {
    limits.add(limit);
    if (refuses case final refusal?) throw refusal;
    return gallery;
  }

  @override
  Future<String?> captureImage() async {
    if (refuses case final refusal?) throw refusal;
    return camera;
  }

  String? video;
  String? recording;

  /// Each recording's cap.
  final caps = <Duration?>[];

  @override
  Future<String?> pickVideo() async {
    if (refuses case final refusal?) throw refusal;
    return video;
  }

  @override
  Future<String?> recordVideo({Duration? maxDuration}) async {
    caps.add(maxDuration);
    if (refuses case final refusal?) throw refusal;
    return recording;
  }
}

/// A vertical 30 s clip of 10 MB, unless [infos] says otherwise (null: it
/// can't be read).
class FakeCompressor implements VideoCompressor {
  final infos = <String, VideoFileInfo?>{};

  @override
  Future<VideoFileInfo?> inspect(String path) async =>
      infos.containsKey(path) ? infos[path] : clip();

  @override
  Future<CompressedVideo?> compress(
    String path, {
    void Function(double progress)? onProgress,
    UploadCancel? cancel,
  }) async => null;
}

/// A clip's facts: [seconds] long, [width] × [height], [bytes] big.
VideoFileInfo clip({
  double seconds = 30,
  int width = 1080,
  int height = 1920,
  int bytes = 10 * 1024 * 1024,
}) => VideoFileInfo(
  duration: Duration(milliseconds: (seconds * 1000).round()),
  width: width,
  height: height,
  sizeBytes: bytes,
);
