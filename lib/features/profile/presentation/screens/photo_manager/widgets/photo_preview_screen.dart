import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

/// Hero tag shared between an upload thumbnail and its full-screen preview.
///
/// Keyed on the file path, not the slot index: removing a photo re-indexes the
/// remaining slots, and an index-based tag would fly the wrong image.
String uploadPhotoHeroTag(String path) => 'upload_photo_$path';

/// Full-screen check of a photo the user just picked (QER-77).
///
/// These are the user's OWN photos on their OWN upload screen, so there is no
/// blur and no consent gate here — that belongs to the mutual photo-exchange
/// flow, which is a different surface with different rules.
class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen({super.key, required this.file});

  final File file;

  /// Pushes the preview. Opaque black-on-wine page; the Hero does the rest.
  static Future<void> open(BuildContext context, File file) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PhotoPreviewScreen(file: file)),
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
                tag: uploadPhotoHeroTag(file.path),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  // contain, never cover: the point is to check the whole
                  // photo, so nothing may be cropped away.
                  child: Image.file(file, fit: BoxFit.contain),
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
}
