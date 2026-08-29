import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// The photo-exchange pair lays itself out by MEASURING, not by a breakpoint:
/// side by side while both labels fit, stacked when they stop fitting.
///
/// The full wording «قبول تبادل الصور» / «رفض تبادل الصور» was briefly
/// shortened because the pair clipped side by side at 320dp. This is the other
/// answer to the same measurement — keep the words, move the layout — so these
/// tests have to hold BOTH ends of it: the words are still whole, and nothing
/// truncates at any width.
const _reject = 'matches_photo_exchange_action_reject';
const _accept = 'matches_photo_exchange_action_accept';

/// True when the two buttons share a row.
///
/// Read off the rendered geometry rather than by looking for a `Row`, so it
/// cannot pass by finding some unrelated Row in the card, and it keeps
/// working if the widget is rebuilt with a different container.
bool _sideBySide(WidgetTester tester, Locale locale) {
  final r = tester.getCenter(find.text(shipped(locale, _reject))).dy;
  final a = tester.getCenter(find.text(shipped(locale, _accept))).dy;
  return (r - a).abs() < 1.0;
}

bool _eitherTruncates(WidgetTester tester, Locale locale) =>
    isTruncated(tester, find.text(shipped(locale, _reject))) ||
    isTruncated(tester, find.text(shipped(locale, _accept)));

Future<void> _pump(WidgetTester tester, Locale locale, double width) =>
    pumpMatchCard(
      tester,
      card: cardAwaitingMyResponse(),
      locale: locale,
      size: Size(width, 900),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  // THE load-bearing one. Every other test here names a specific width and
  // could go stale when copy or padding moves; this one states the rule the
  // widget exists to keep, at every width either language can meet.
  //
  // Note the shape: it does NOT assert where the switch happens. It asserts
  // that the switch is never WRONG — the pair may stack whenever it likes, but
  // it may never choose a row it cannot fit. A widget that stacked always
  // would pass this and fail the two below, which is the intended division.
  group('it never sits side by side when that would truncate', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      // Floored at 320dp, the width this project treats as the narrowest
      // real device — the same floor 6c held the shipped copy to. A 280dp
      // sweep was tried and dropped: it fails on a pre-existing 2.2px
      // overflow in MatchPendingCountdownChip's QeranChip, in the card HEADER
      // and nothing to do with this pair. Fixing that is its own job; testing
      // below the supported floor would have invented a requirement.
      for (final width in const [
        320.0, 330.0, 340.0, 360.0, 375.0, 412.0, 480.0,
      ]) {
        testWidgets('${locale.languageCode} at ${width.toInt()}dp', (
          tester,
        ) async {
          await _pump(tester, locale, width);

          if (_sideBySide(tester, locale)) {
            expect(
              _eitherTruncates(tester, locale),
              isFalse,
              reason:
                  'chose a row at ${width.toInt()}dp and a label did not fit',
            );
          }
        });
      }
    }
  });

  // The other half: it must not stack out of caution either, or the measuring
  // buys nothing over the plain Column it replaced.
  group('and it does use the row when the row fits', () {
    testWidgets('a comfortable width keeps both on one line [ar]', (
      tester,
    ) async {
      await _pump(tester, const Locale('ar'), 360);

      expect(_sideBySide(tester, const Locale('ar')), isTrue);
      expect(_eitherTruncates(tester, const Locale('ar')), isFalse);
    });

    // English is the reason the switch measures instead of using a fixed
    // breakpoint: its labels are shorter, so it keeps its row at a width where
    // Arabic has already given up on one.
    testWidgets('English keeps its row at a width Arabic cannot', (
      tester,
    ) async {
      await _pump(tester, const Locale('en'), 320);
      expect(_sideBySide(tester, const Locale('en')), isTrue);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const Locale('ar'), 320);
      expect(_sideBySide(tester, const Locale('ar')), isFalse);
    });
  });

  group('stacked, the full labels still fit', () {
    testWidgets('320dp [ar] stacks and neither label truncates', (
      tester,
    ) async {
      await _pump(tester, const Locale('ar'), 320);

      expect(_sideBySide(tester, const Locale('ar')), isFalse);
      expect(_eitherTruncates(tester, const Locale('ar')), isFalse);
    });

    // 330 is the last width that still cannot hold the row: the labels need
    // 109.4dp and the half-width gives 108.0. One dp of margin either side of
    // the switch is exactly where an off-by-one in the measurement would show.
    testWidgets('330dp [ar] is still stacked, 340dp is not', (tester) async {
      await _pump(tester, const Locale('ar'), 330);
      expect(_sideBySide(tester, const Locale('ar')), isFalse);
      expect(_eitherTruncates(tester, const Locale('ar')), isFalse);

      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const Locale('ar'), 340);
      expect(_sideBySide(tester, const Locale('ar')), isTrue);
      expect(_eitherTruncates(tester, const Locale('ar')), isFalse);
    });
  });

  // Guards the copy this change restored. Without it the whole feature could
  // be "fixed" by shortening the labels again, and every test above would
  // still pass.
  test('the shipped Arabic names the exchange in full', () {
    expect(shipped(const Locale('ar'), _accept), 'قبول تبادل الصور');
    expect(shipped(const Locale('ar'), _reject), 'رفض تبادل الصور');
  });
}
