import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

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
        Positioned.fill(
          child: ClipRRect(
            borderRadius: QeranRadii.controlR,
            child: Image.file(file, fit: BoxFit.cover),
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
        if (!isPrimary && !isUploading)
          Positioned.fill(
            child: GestureDetector(
              onTap: onSetPrimary,
              child: Container(
                decoration: BoxDecoration(
                  color: QeranColors.wine20,
                  borderRadius: QeranRadii.controlR,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: QeranColors.paper,
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
