import '../entities/picked_video.dart';
import '../ports/media_inspector.dart';
import '../ports/video_compressor.dart';

/// What a picked video really is (plan §3.3): its container from its bytes,
/// then its length, display size and bytes from the file. Null when the
/// server wouldn't take it or it can't be read (C10).
class InspectPickedVideoUseCase {
  final MediaInspector _inspector;
  final VideoCompressor _compressor;

  const InspectPickedVideoUseCase(this._inspector, this._compressor);

  Future<PickedVideo?> call(String path) async {
    final container = await _inspector.videoContainerOf(path);
    if (container == null) return null;
    final info = await _compressor.inspect(path);
    if (info == null) return null;
    return PickedVideo(path: path, container: container, info: info);
  }
}
