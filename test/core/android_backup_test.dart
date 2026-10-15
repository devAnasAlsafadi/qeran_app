import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing of the member's leaves the phone through Android's backup
/// (cleanup audit `19`, run 11): SharedPreferences hold the name, email, role
/// and FCM token. `allowBackup="false"` covers Android up to 11; from 12,
/// device-to-device transfer ignores it, so the extraction rules exclude
/// every domain for both cloud backup and transfer.
void main() {
  const domains = ['root', 'file', 'database', 'sharedpref', 'external'];
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final rules = File(
    'android/app/src/main/res/xml/data_extraction_rules.xml',
  ).readAsStringSync();

  test('the application turns backup off and names the rules', () {
    expect(manifest, contains('android:allowBackup="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
  });

  for (final section in ['cloud-backup', 'device-transfer']) {
    test('$section excludes every domain', () {
      final body = RegExp(
        '<$section>(.*?)</$section>',
        dotAll: true,
      ).firstMatch(rules)?.group(1);
      expect(body, isNotNull, reason: 'no <$section>');
      for (final domain in domains) {
        expect(body, contains('<exclude domain="$domain" />'));
      }
    });
  }
}
