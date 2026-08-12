import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Validators call the global `tr()`, so EasyLocalization has to be stood up
/// before any of them run. The assertions below check WHICH rule fired by
/// key, not the translated wording, so they stay honest if the copy changes.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // EasyLocalization reads SharedPreferences during init, which has no
    // platform implementation under `flutter test`.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  String? validate(String? v) => Validators.validateDisplayName(v);

  test('empty and whitespace-only are rejected as required', () {
    expect(validate(null), isNotNull);
    expect(validate(''), isNotNull);
    expect(validate('   '), isNotNull);
  });

  test('a single character is too short', () {
    expect(validate('د'), isNotNull);
  });

  test('two characters is the shortest accepted name', () {
    expect(validate('دي'), isNull);
  });

  test('exactly 100 characters passes, 101 does not', () {
    expect(validate('a' * 100), isNull);
    expect(validate('a' * 101), isNotNull);
  });

  test('length is measured after trimming', () {
    // '  دي  ' is 6 raw characters but 2 real ones — it must pass, and a
    // single character padded to look long must still fail.
    expect(validate('  دي  '), isNull);
    expect(validate('   د   '), isNotNull);
  });

  test('rejects each character the backend forbids', () {
    for (final bad in ['<', '>', '%']) {
      expect(
        validate('ديما$bad'),
        isNotNull,
        reason: '"$bad" must be rejected client-side',
      );
    }
  });

  test('accepts ordinary Arabic and Latin names', () {
    expect(validate('ديما'), isNull);
    expect(validate('Dima'), isNull);
    expect(validate('أنس الصفدي'), isNull);
    expect(validate("O'Brien"), isNull);
    expect(validate('Anne-Marie'), isNull);
  });
}
