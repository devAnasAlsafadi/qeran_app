import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_title_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shipped copy, so the pill is as wide as it really is.
class _CopyLoader extends AssetLoader {
  const _CopyLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => {
    'discovery': locale.languageCode == 'ar'
        ? {'title': 'ترشيحات', 'filter_button': 'تعديل الفلترة'}
        : {'title': 'Suggestions', 'filter_button': 'Edit filters'},
  };
}

const _profile = DiscoveryProfile(
  id: 'p1',
  name: 'رنا',
  age: 22,
  images: [],
  matchingScore: 0,
  placements: [],
);

/// Two digits: wider than any one-digit count, so the worst case is the one
/// measured.
const _count = 12;

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required double width,
  required bool onPhoto,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [locale],
      path: 'assets/translations',
      assetLoader: const _CopyLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Align(
            alignment: Alignment.topCenter,
            child: onPhoto
                ? DiscoveryImagePanel(
                    profile: _profile,
                    height: 280,
                    activeFilterCount: _count,
                    onFilterTap: () {},
                  )
                // On the canvas the row sits at the top of the tab stage,
                // which clips its children.
                : ClipRect(
                    child: DiscoveryTitleRow(
                      onPhoto: false,
                      activeFilterCount: _count,
                      onEditFilters: () {},
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectInside(Rect inner, Rect outer, String what) {
  expect(
    inner.left >= outer.left &&
        inner.top >= outer.top &&
        inner.right <= outer.right &&
        inner.bottom <= outer.bottom,
    isTrue,
    reason: 'the badge $inner pokes out of $what $outer',
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final lang = locale.languageCode;
    for (final onPhoto in const [true, false]) {
      final where = onPhoto ? 'on the photo' : 'on the canvas';
      for (final width in const [320.0, 412.0]) {
        // Nothing that holds the row may clip the badge: the row's own box is
        // inside the photo, the tab stage and the screen, so a badge inside
        // the row is inside all of them.
        testWidgets(
          'the badge stays inside the row, photo and screen '
          '[$lang, $where, ${width.toInt()} pt]',
          (tester) async {
            await _pump(tester, locale: locale, width: width, onPhoto: onPhoto);

            final badge = tester.getRect(find.byType(QeranCountBadge));
            expect(find.text('$_count'), findsOneWidget);
            _expectInside(
              badge,
              tester.getRect(find.byType(DiscoveryTitleRow)),
              'the title row',
            );
            _expectInside(badge, Offset.zero & Size(width, 800), 'the screen');
            if (onPhoto) {
              _expectInside(
                badge,
                tester.getRect(find.byType(DiscoveryImagePanel)),
                'the photo',
              );
            }
          },
        );
      }
    }

    testWidgets('the badge rides the pill\'s top-end corner [$lang]', (
      tester,
    ) async {
      await _pump(tester, locale: locale, width: 375, onPhoto: true);

      final badge = tester.getRect(find.byType(QeranCountBadge));
      final pill = tester.getRect(
        find
            .ancestor(
              of: find.byType(QeranCountBadge),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(badge.top, pill.top - 4);
      if (lang == 'ar') {
        // End is the left in Arabic.
        expect(badge.left, pill.left - 4);
      } else {
        expect(badge.right, pill.right + 4);
      }
    });
  }
}
