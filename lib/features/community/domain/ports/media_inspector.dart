import '../entities/picked_image.dart';
import '../entities/picked_video.dart';

/// What a picked file really is, read from its first bytes and never from
/// its name: Android's picker re-encodes a HEIC to JPEG and keeps the name
/// `scaled_IMG.heic` (plan §3.3).
abstract class MediaInspector {
  /// A JPEG or PNG ready to send, or null for anything else (a HEIC that
  /// wasn't converted, an unknown type, a file that can't be read).
  Future<PickedImage?> inspectImage(String path);

  /// MP4 or QuickTime, from the file's `ftyp` box; null for anything else
  /// (3GP included) or a file that can't be read.
  Future<VideoContainer?> videoContainerOf(String path);
}
