import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/media/media_access.dart';
import 'package:qeran/core/media/pick_with_access.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The camera or the gallery for a profile photo. The sheet only answers
/// which; the phone's picker opens once it has closed.
class PhotoPickerBottomSheet extends StatelessWidget {
  const PhotoPickerBottomSheet({super.key});

  /// The sheet, then the picker on [context] (the photo manager, still on
  /// screen), so a refused camera or library gets the settings dialog.
  /// Backing out of either does nothing; a picked photo goes to
  /// [onImagePicked].
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<String> onImagePicked,
    ImagePicker? picker,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      barrierColor: QeranColors.overlayTintDark,
      shape: const RoundedRectangleBorder(
        borderRadius: QeranRadii.domeTop,
      ),
      builder: (context) => const PhotoPickerBottomSheet(),
    );
    if (source == null || !context.mounted) return;
    await pickWithAccess(context, () async {
      final path = await _pick(picker ?? ImagePicker(), source);
      if (path != null) onImagePicked(path);
    });
  }

  /// No full metadata, so iOS asks for no photo-library permission to pick
  /// one photo.
  static Future<String?> _pick(ImagePicker picker, ImageSource source) =>
      guardMediaAccess(
        () async => (await picker.pickImage(
          source: source,
          imageQuality: 85,
          requestFullMetadata: false,
        ))?.path,
        fallback: null,
        tag: 'PROFILE',
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s16),
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: QeranSpacing.s8),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: QeranColors.wine20,
                      borderRadius: QeranRadii.pill,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: QeranColors.wine),
              title: Text(
                LocaleKeys.auth_photo_camera.t(context),
                style: QeranTypography.subtitle,
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: QeranColors.wine,
              ),
              title: Text(
                LocaleKeys.auth_photo_gallery.t(context),
                style: QeranTypography.subtitle,
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
