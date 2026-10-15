import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Declaring CAMERA makes Google Play assume the camera (and autofocus) are
/// required, hiding the app from phones without one; the gallery covers
/// them, so both are declared optional (cleanup audit `19`, run 11).
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('the camera is still asked for (the refusal dialog needs it)', () {
    expect(manifest, contains('android.permission.CAMERA'));
  });

  for (final feature in [
    'android.hardware.camera',
    'android.hardware.camera.autofocus',
  ]) {
    test('$feature is optional', () {
      expect(
        manifest,
        contains(
          '<uses-feature android:name="$feature" android:required="false" />',
        ),
      );
    });
  }
}
