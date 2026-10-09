import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// E3: the name under the Android launcher icon is "Qeran", as on iOS — not
/// the project's lowercase id.
void main() {
  test('the Android launcher label is "Qeran"', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:label="Qeran"'));
    expect(manifest, isNot(contains('android:label="qeran"')));
  });
}
