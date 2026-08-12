import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../../../../likes/presentation/widgets/like_blurred_image.dart';

/// Hero tag shared between an upload thumbnail and its full-screen preview.
///
/// Keyed on the file path, not the slot index: removing a photo re-indexes the
/// remaining slots, and an index-based tag would fly the wrong image.
String uploadPhotoHeroTag(String path) => 'upload_photo_$path';

/// Hero tag for a photo that already lives on the server, keyed on its
/// stable id rather than its URL — a re-signed or re-hosted URL must not
/// break the flight.
String serverPhotoHeroTag(String imageId) => 'server_photo_$imageId';

/// Full-screen check of one of the user's own photos (QER-77).
///
/// Works for both sources: a file just picked on-device and a photo already
/// uploaded. These are the user's OWN photos on their OWN screen, so there
/// is no blur and no consent gate here — that belongs to the mutual
/// photo-exchange flow, which is a different surface with different rules.
class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen._({
    required this.heroTag,
    this.file,
    this.imageUrl,
    this.memoryOnly = false,
  });

  /// Preview a locally staged file.
  factory PhotoPreviewScreen({Key? key, required File file}) =>
      PhotoPreviewScreen._(heroTag: uploadPhotoHeroTag(file.path), file: file);

  /// Preview a photo hosted by the API. The bytes need the session bearer
  /// token, so it goes through the same authenticated loader the rest of
  /// the app uses rather than a bare Image.network.
  ///
  /// [memoryOnly] must be set for anything under the one-time photo-view
  /// policy: this route is pushed ABOVE the `PhotoViewScope`, so the inherited
  /// policy cannot reach it and the disk cache would otherwise let the photo
  /// outlive the 60-second window.
  factory PhotoPreviewScreen.network({
    Key? key,
    required String imageUrl,
    required String imageId,
    bool memoryOnly = false,
  }) => PhotoPreviewScreen._(
    heroTag: serverPhotoHeroTag(imageId),
    imageUrl: imageUrl,
    memoryOnly: memoryOnly,
  );

  final String heroTag;
  final File? file;
  final String? imageUrl;
  final bool memoryOnly;

  /// Pushes the preview for a staged file.
  static Future<void> open(BuildContext context, File file) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhotoPreviewScreen(file: file)),
    );
  }

  /// Pushes the preview for a photo already on the server.
  static Future<void> openNetwork(
    BuildContext context, {
    required String imageUrl,
    required String imageId,
    bool memoryOnly = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PhotoPreviewScreen.network(
          imageUrl: imageUrl,
          imageId: imageId,
          memoryOnly: memoryOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void close() => Navigator.of(context).pop();
    return Scaffold(
      backgroundColor: QeranColors.wine,
      body: Stack(
        children: [
          // Tapping the photo closes, same as the × — the whole surface is the
          // dismiss target, so the user never has to aim.
          Positioned.fill(
            child: GestureDetector(
              onTap: close,
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  // contain, never cover: the point is to check the whole
                  // photo, so nothing may be cropped away.
                  child: _content(),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: QeranSpacing.s8,
            end: QeranSpacing.s8,
            // Clear of the status bar / notch.
            child: SafeArea(
              child: Material(
                color: QeranColors.wine80,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: close,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close_rounded,
                      color: QeranColors.paper,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final f = file;
    if (f != null) return Image.file(f, fit: BoxFit.contain);
    return LikeBlurredImage(
      url: imageUrl,
      blur: false,
      memoryOnly: memoryOnly,
      size: null,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.zero,
      fit: BoxFit.contain,
    );
  }
}
