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

  // Built from code points rather than embedded as literal bytes — a raw NUL
  // in a source file is invisible in a diff and mangled by tooling.
  final nul = String.fromCharCode(0);
  final del = String.fromCharCode(0x7F);

  group('displayName', () {
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

    test('exactly 50 characters passes, 51 does not', () {
      // The backend's cap. It used to be enforced at 100 client-side, which
      // let a name through the form that the server would reject.
      expect(validate('a' * 50), isNull);
      expect(validate('a' * 51), isNotNull);
    });

    test('length is measured after trimming', () {
      // '  دي  ' is 6 raw characters but 2 real ones — it must pass, and a
      // single character padded to look long must still fail.
      expect(validate('  دي  '), isNull);
      expect(validate('   د   '), isNotNull);
    });

    test('accepts the characters the old client wrongly rejected', () {
      // `< > %` were filtered client-side against a server rule that never
      // existed. The backend accepts any character but control codes.
      for (final ok in ['<', '>', '%']) {
        expect(
          validate('ديما$ok'),
          isNull,
          reason: '"$ok" is accepted by the backend and must pass',
        );
      }
    });

    test('trailing whitespace controls are trimmed, not rejected', () {
      // trim() runs before the character rule, so a stray trailing newline is
      // normalised away and never reaches the server — nothing to reject.
      expect(validate('ديما\n'), isNull);
      expect(validate('ديما\r\n'), isNull);
      expect(validate('ديما\t'), isNull);
    });

    test('rejects control characters inside the name', () {
      expect(validate('ديما\nعلي'), isNotNull);
      expect(validate('ديما\r\nعلي'), isNotNull);
      expect(validate('ديما\tعلي'), isNotNull);
      // NUL and DEL are not whitespace, so trim() leaves them wherever
      // they sit — including at the end.
      expect(validate('ديما$nul'), isNotNull);
      expect(validate('ديما$del'), isNotNull);
    });

    test('accepts ordinary Arabic and Latin names', () {
      expect(validate('ديما'), isNull);
      expect(validate('Dima'), isNull);
      expect(validate('أنس الصفدي'), isNull);
      expect(validate("O'Brien"), isNull);
      expect(validate('Anne-Marie'), isNull);
    });
  });

  group('realName', () {
    String? validate(String? v) => Validators.validateRealName(v);

    test('empty is valid — the field is optional', () {
      expect(validate(null), isNull);
      expect(validate(''), isNull);
      expect(validate('   '), isNull);
    });

    test('no minimum length — a single character is accepted', () {
      // Unlike displayName, realName carries no floor: it is either absent
      // or whatever the member's legal name actually is.
      expect(validate('د'), isNull);
    });

    test('exactly 100 characters passes, 101 does not', () {
      expect(validate('a' * 100), isNull);
      expect(validate('a' * 101), isNotNull);
    });

    test('the cap is 100, not the 50 that gates displayName', () {
      expect(validate('a' * 60), isNull);
      expect(Validators.validateDisplayName('a' * 60), isNotNull);
    });

    test('length is measured after trimming', () {
      expect(validate('  ${'a' * 100}  '), isNull);
    });

    test('trailing whitespace controls are trimmed, not rejected', () {
      expect(validate('محمد\n'), isNull);
      expect(validate('محمد\r\n'), isNull);
      expect(validate('محمد\t'), isNull);
    });

    test('rejects control characters inside the name', () {
      expect(validate('محمد\nعبدالله'), isNotNull);
      expect(validate('محمد\r\nعبدالله'), isNotNull);
      expect(validate('محمد\tعبدالله'), isNotNull);
      expect(validate('محمد$nul'), isNotNull);
      expect(validate('محمد$del'), isNotNull);
    });

    test('accepts a full legal name in either script', () {
      expect(validate('محمد عبدالله السالم'), isNull);
      expect(validate('Mohammed Abdullah Al-Salem'), isNull);
    });
  });
}
