import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../../../likes/presentation/widgets/like_blurred_image.dart';
import '../../../../domain/entities/photo_slot.dart';
import 'photo_preview_screen.dart';
import 'photo_primary_badge.dart';

/// One occupied tile. Renders either a locally staged file or a photo the
/// server already holds; the controls are identical, only the source differs.
class FilledPhotoSlot extends StatelessWidget {
  final PhotoSlot slot;

  /// THIS photo is mid-mutation — it alone wears the scrim.
  final bool isLoading;

  /// A mutation owns the screen, though not necessarily this photo. Its
  /// controls hide so a tap cannot silently vanish into the cubit's
  /// single-mutation guard, but the tile stays bright and previewable.
  final bool isLocked;

  /// Whether deleting this photo is possible at all. False for the last
  /// photo on the server, which the backend refuses to remove — the control
  /// disappears rather than offering an action that can only fail.
  ///
  /// Defaults to true so the many call sites holding a staged slot (which is
  /// always removable) need not say so.
  final bool canRemove;

  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  const FilledPhotoSlot({
    super.key,
    required this.slot,
    required this.isLoading,
    required this.isLocked,
    this.canRemove = true,
    required this.onRemove,
    required this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = slot.isMain;
    return Stack(
      children: [
        // QER-77: the photo itself is the preview target. Both small corner
        // controls sit LATER in this Stack, so they are hit-tested first and
        // win their own taps — the preview only fires on the area around them.
        Positioned.fill(
          child: GestureDetector(
            // Previewing another photo while one mutates is harmless, so
            // only the mutating tile itself refuses the tap.
            onTap: isLoading ? null : () => _preview(context),
            child: ClipRRect(
              borderRadius: QeranRadii.controlR,
              child: _image(),
            ),
          ),
        ),
        if (isPrimary)
          const PositionedDirectional(
            bottom: 0,
            start: 0,
            child: PhotoPrimaryBadge(),
          ),
        if (canRemove && !isLoading && !isLocked)
          PositionedDirectional(
            top: QeranSpacing.s4,
            end: QeranSpacing.s4,
            child: _CornerControl(
              icon: Icons.close_rounded,
              onTap: onRemove,
            ),
          ),
        // "Make this the primary photo" used to be a FULL-SLOT tap target with
        // a wine scrim over the whole thumbnail. It cannot stay that way and
        // also let the thumbnail open a preview — one of the two would have to
        // lose. Rather than drop a working feature, it becomes an explicit
        // corner control mirroring the delete x, so both gestures coexist:
        // small targets act, the photo previews.
        if (!isPrimary && !isLoading && !isLocked)
          PositionedDirectional(
            top: QeranSpacing.s4,
            start: QeranSpacing.s4,
            child: _CornerControl(
              icon: Icons.check_rounded,
              onTap: onSetPrimary,
            ),
          ),
        if (isLoading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: QeranRadii.controlR,
              child: const ColoredBox(color: QeranColors.overlayTintDark),
            ),
          ),
        // A staged tile can only ever be loading because it is being sent,
        // so the label needs no extra flag to know what is happening. Server
        // tiles mutate in place and stay wordless — a set-main is a moment,
        // an upload is not, and only the second one owes the user an
        // explanation for the wait.
        if (isLoading && slot is StagedPhotoSlot)
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s8,
                ),
                child: Text(
                  LocaleKeys.profile_photos_uploading.t(context),
                  textAlign: TextAlign.center,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.paper,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _image() => switch (slot) {
    StagedPhotoSlot(:final path) => Hero(
      tag: uploadPhotoHeroTag(path),
      child: Image.file(File(path), fit: BoxFit.cover),
    ),
    // Server photos need the session bearer token, which LikeBlurredImage
    // attaches; a bare Image.network would 401 and fall back to the grey
    // person icon.
    ServerPhotoSlot(:final id, :final url) => Hero(
      tag: serverPhotoHeroTag(id),
      child: LikeBlurredImage(
        url: url,
        blur: false,
        size: null,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.zero,
      ),
    ),
  };

  /// QER-77: the thumbnail opens full-screen, for staged and server photos
  /// alike. The corner controls sit later in the Stack and win their own
  /// taps, so delete and set-main never trigger a preview.
  void _preview(BuildContext context) {
    switch (slot) {
      case StagedPhotoSlot(:final path):
        PhotoPreviewScreen.open(context, File(path));
      case ServerPhotoSlot(:final id, :final url):
        PhotoPreviewScreen.openNetwork(context, imageUrl: url, imageId: id);
    }
  }
}

class _CornerControl extends StatelessWidget {
  const _CornerControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: QeranColors.wine80,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: QeranColors.paper, size: 14),
      ),
    );
  }
}
