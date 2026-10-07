import '../entities/picked_image.dart';
import '../ports/media_inspector.dart';

/// What a picked image really is (plan §3.3): ready to send, or null when
/// the server wouldn't take it (C10).
class InspectPickedImageUseCase {
  final MediaInspector _inspector;
  const InspectPickedImageUseCase(this._inspector);

  Future<PickedImage?> call(String path) => _inspector.inspectImage(path);
}
