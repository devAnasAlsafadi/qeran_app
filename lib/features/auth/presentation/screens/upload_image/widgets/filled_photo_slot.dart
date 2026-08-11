import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import 'photo_preview_screen.dart';
import 'photo_primary_badge.dart';

class FilledPhotoSlot extends StatelessWidget {
  final int index;
  final File file;
  final bool isPrimary;
  final bool isUploading;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  const FilledPhotoSlot({
    super.key,
    required this.index,
    required this.file,
    required this.isPrimary,
    required this.isUploading,
    required this.onRemove,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // QER-77: the photo itself is the preview target. Both small corner
        // controls sit LATER in this Stack, so they are hit-tested first and
        // win their own taps — the preview only fires on the area around them.
        Positioned.fill(
          child: GestureDetector(
            onTap: isUploading
                ? null
                : () => PhotoPreviewScreen.open(context, file),
            child: ClipRRect(
              borderRadius: QeranRadii.controlR,
              child: Hero(
                tag: uploadPhotoHeroTag(file.path),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        if (isPrimary)
          const PositionedDirectional(
            bottom: 0,
            start: 0,
            child: PhotoPrimaryBadge(),
          ),
        if (!isUploading)
          PositionedDirectional(
            top: QeranSpacing.s4,
            end: QeranSpacing.s4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: QeranColors.wine80,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: QeranColors.paper,
                  size: 14,
                ),
              ),
            ),
          ),
        // "Make this the primary photo" used to be a FULL-SLOT tap target with
        // a wine scrim over the whole thumbnail. It cannot stay that way and
        // also let the thumbnail open a preview — one of the two would have to
        // lose. Rather than drop a working feature, it becomes an explicit
        // corner control mirroring the delete x, so both gestures coexist:
        // small targets act, the photo previews.
        if (!isPrimary && !isUploading)
          PositionedDirectional(
            top: QeranSpacing.s4,
            start: QeranSpacing.s4,
            child: GestureDetector(
              onTap: onSetPrimary,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: QeranColors.wine80,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: QeranColors.paper,
                  size: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
