import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D17: a real display name before the first comment. The server refuses
/// the two placeholders as a chosen name, with any diacritics (contract
/// §4, gate 2); the form says so before a save does.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  // With no translations loaded, tr() hands back the key — so each check
  // says which rule fired, not how it's worded.
  final defaultError = tr('profile.name_default_error');

  group('a placeholder', () {
    String? validate(String v) => Validators.validateDisplayName(v);

    test('«مستخدم» is refused as the placeholder', () {
      expect(validate('مستخدم'), defaultError);
    });

    test('«مستخدم جديد» is refused too', () {
      expect(validate('مستخدم جديد'), defaultError);
    });

    test('diacritics don\'t make it a name', () {
      expect(validate('مُسْتَخْدَم'), defaultError);
      expect(validate('مُسْتَخْدِمٌ جَدِيدٌ'), defaultError);
    });

    test('nor does the spacing', () {
      expect(validate('  مستخدم  '), defaultError);
      expect(validate('مستخدم   جديد'), defaultError);
    });
  });

  group('a name', () {
    bool placeholder(String v) => Validators.isDefaultDisplayName(v);

    test('that only contains the word is a name', () {
      expect(placeholder('مستخدمة'), isFalse);
      expect(placeholder('مستخدم قديم'), isFalse);
      expect(placeholder('أبو مستخدم'), isFalse);
      expect(Validators.validateDisplayName('مستخدمة'), isNull);
    });

    test('in English, "User" is a name: the placeholder is Arabic', () {
      expect(placeholder('User'), isFalse);
      expect(Validators.validateDisplayName('User'), isNull);
    });
  });
}
