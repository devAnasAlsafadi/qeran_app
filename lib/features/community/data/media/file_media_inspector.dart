import 'dart:io';

import 'package:qeran/core/domain/upload.dart';

import '../../domain/entities/picked_image.dart';
import '../../domain/entities/picked_video.dart';
import '../../domain/ports/media_inspector.dart';

/// [MediaInspector] over the file itself: its first eight bytes say what it
/// is, its length how big.
class FileMediaInspector implements MediaInspector {
  const FileMediaInspector();

  @override
  Future<PickedImage?> inspectImage(String path) async {
    try {
      final file = File(path);
      final format = imageFormatOf(await _head(file));
      if (format == null) return null;
      return PickedImage(
        file: UploadFile(
          path: path,
          fileName: 'image.${format.extension}',
          contentType: format.mimeType,
        ),
        format: format,
        sizeBytes: await file.length(),
      );
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<VideoContainer?> videoContainerOf(String path) async {
    try {
      return videoContainerFrom(await _head(File(path), 12));
    } on FileSystemException {
      return null;
    }
  }

  Future<List<int>> _head(File file, [int length = 8]) async {
    final bytes = <int>[];
    await for (final chunk in file.openRead(0, length)) {
      bytes.addAll(chunk);
    }
    return bytes;
  }
}

const _jpeg = [0xFF, 0xD8, 0xFF];
const _png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// JPEG (`FF D8 FF`) or PNG (its eight-byte signature); null for anything
/// else, a HEIC's `ftyp` box included.
ImageFormat? imageFormatOf(List<int> head) {
  bool startsWith(List<int> signature) =>
      head.length >= signature.length &&
      Iterable.generate(signature.length).every((i) => head[i] == signature[i]);
  if (startsWith(_jpeg)) return ImageFormat.jpeg;
  if (startsWith(_png)) return ImageFormat.png;
  return null;
}

/// An ISO media file's `ftyp` box names its brand at bytes 8–11: `qt  ` is
/// QuickTime (a MOV); 3GP brands are refused; any other brand (`isom`,
/// `mp42`, `avc1`…) is MP4. No `ftyp` at bytes 4–7: not a video we take.
VideoContainer? videoContainerFrom(List<int> head) {
  if (head.length < 12) return null;
  if (String.fromCharCodes(head.sublist(4, 8)) != 'ftyp') return null;
  final brand = String.fromCharCodes(head.sublist(8, 12));
  if (brand == 'qt  ') return VideoContainer.quickTime;
  if (brand.startsWith('3g')) return null;
  return VideoContainer.mp4;
}
