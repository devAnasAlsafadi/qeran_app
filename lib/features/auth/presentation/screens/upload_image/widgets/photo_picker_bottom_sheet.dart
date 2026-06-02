import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class PhotoPickerBottomSheet extends StatelessWidget {
  final ValueChanged<String> onImagePicked;

  const PhotoPickerBottomSheet({super.key, required this.onImagePicked});

  static void show(
    BuildContext context, {
    required ValueChanged<String> onImagePicked,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: QeranRadii.domeTop,
      ),
      builder: (context) =>
          PhotoPickerBottomSheet(onImagePicked: onImagePicked),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      onImagePicked(pickedFile.path);
    }
  }

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
              leading: const Icon(Icons.camera_alt, color: QeranColors.wine),
              title: Text(
                LocaleKeys.auth_photo_camera.t(context),
                style: QeranTypography.subtitle,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: QeranColors.wine,
              ),
              title: Text(
                LocaleKeys.auth_photo_gallery.t(context),
                style: QeranTypography.subtitle,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
