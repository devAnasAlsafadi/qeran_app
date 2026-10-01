import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../shipped_strings_rig.dart';

/// The reply links in every Arabic category (§7.1). Zero never shows.
const _viewReplies = <int, String>{
  1: 'عرض الردّ',
  2: 'عرض الردّين',
  3: 'عرض 3 ردود',
  10: 'عرض 10 ردود',
  11: 'عرض 11 ردّاً',
  99: 'عرض 99 ردّاً',
  100: 'عرض 100 ردّ',
  103: 'عرض 103 ردود',
};

const _moreReplies = <int, String>{
  1: 'عرض ردّ آخر',
  2: 'عرض ردّين آخرين',
  5: 'عرض 5 ردود أخرى',
  12: 'عرض 12 ردّاً آخر',
  200: 'عرض 200 ردّ آخر',
};

void main() {
  setUpAll(initShippedStrings);

  test('the app turns plural rules on (B1)', () {
    // Off is the package default, and with it Arabic never reaches few or
    // many: «عرض 3 ردّ». The tests below run with them on, as main.dart does.
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('ignorePluralRules: false'),
    );
  });

  testWidgets('Arabic: one form per category', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    for (final MapEntry(key: n, value: text) in _viewReplies.entries) {
      expect(LocaleKeys.community_view_replies.tPlural(context, n), text);
    }
    for (final MapEntry(key: n, value: text) in _moreReplies.entries) {
      expect(LocaleKeys.community_more_replies.tPlural(context, n), text);
    }
  });

  testWidgets('English: one and other', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    String view(int n) => LocaleKeys.community_view_replies.tPlural(context, n);
    String more(int n) => LocaleKeys.community_more_replies.tPlural(context, n);

    expect(
      [view(1), view(2), view(11)],
      ['View 1 reply', 'View 2 replies', 'View 11 replies'],
    );
    expect([more(1), more(3)], ['View 1 more reply', 'View 3 more replies']);
  });
}
