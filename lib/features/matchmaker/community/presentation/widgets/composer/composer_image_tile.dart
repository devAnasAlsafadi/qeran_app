import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../../core/design_system/widgets/qeran_dashed_ring.dart';
import '../../../../../../core/extensions/localization_extension.dart';
import '../../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../../generated/locale_keys.g.dart';
import 'composer_remove_button.dart';

/// The side of a composer thumbnail and of the add tile (C5).
const double composerTileSide = 104;

/// One of her images in the composer (C5): her own file, cropped to the
/// square, with × at the top end in a 48 pt target. [onRemove] null while
/// it publishes.
class ComposerImageTile extends StatelessWidget {
  const ComposerImageTile({super.key, required this.path, this.onRemove});

  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: composerTileSide,
      child: Stack(
        children: [
          Positioned.fill(child: _image(context)),
          if (onRemove != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: ComposerRemoveButton(
                label: LocaleKeys.matchmaker_community_remove_image.t(context),
                onTap: onRemove!,
              ),
            ),
        ],
      ),
    );
  }

  /// Decoded at the tile's size, not the photo's.
  Widget _image(BuildContext context) => ClipRRect(
    borderRadius: QeranRadii.controlR,
    child: Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: (composerTileSide * MediaQuery.devicePixelRatioOf(context))
          .round(),
      errorBuilder: (_, _, _) => const ColoredBox(
        color: QeranColors.softFill,
        child: Icon(Icons.image_rounded, color: QeranColors.inkFaint),
      ),
    ),
  );
}

/// «إضافة» after her images while more fit: a dashed square (C5).
class ComposerAddImageTile extends StatelessWidget {
  const ComposerAddImageTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: QeranDashedRing(
        color: QeranColors.wine20,
        borderRadius: QeranRadii.controlR,
        child: SizedBox.square(
          dimension: composerTileSide,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_rounded,
                size: 26,
                color: QeranColors.wine,
              ),
              Text(
                LocaleKeys.matchmaker_community_add_image.t(context),
                style: QeranTypography.label.copyWith(
                  color: QeranColors.wine,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
