import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders keys rather than translations, so an assertion names the key it
/// means. The sibling `match_card_stage1_photo_view_test` works the same way.
class _KeyLoader extends AssetLoader {
  const _KeyLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Invariants for the one-time photo-view copy.
///
/// The window length is the SERVER's, and the client cannot even read it
/// before the window starts: in the `available` phase `viewedAt`,
/// `viewExpiresAt` and `secondsRemaining` are all unpopulated. The confirm
/// dialog nevertheless said «لمدة 60 ثانية» in both languages — a number typed
/// by hand about a behaviour this app cannot see, which would have become a
/// lie the moment the window changed and which nothing would have caught.
Map<String, String> _photoViewStrings(String locale) {
  final file = File('assets/translations/$locale.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final likes = json['likes'] as Map<String, dynamic>;
  return {
    for (final entry in likes.entries)
      if (entry.key.contains('photo_view') && entry.value is String)
        entry.key: entry.value as String,
  };
}

const _locales = ['ar', 'en'];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // THE one. It does not fix the 60 — it makes the whole CATEGORY of bug
  // impossible, so no future duration can be typed into shipped copy again.
  //
  // `matches_photo_view_remaining` is the deliberate exception: its digits
  // arrive through `{seconds}`, which is interpolation rather than a claim.
  group('no photo-view string states a duration of its own', () {
    for (final locale in _locales) {
      test('[$locale]', () {
        final offenders = <String>[];
        _photoViewStrings(locale).forEach((key, value) {
          final stripped = value.replaceAll('{seconds}', '');
          if (RegExp(r'[0-9٠-٩]').hasMatch(stripped)) {
            offenders.add('$key = $value');
          }
        });

        expect(
          offenders,
          isEmpty,
          reason:
              'a photo-view string carries a hardcoded number. The window '
              'length belongs to the server and the client cannot read it '
              'before the window opens, so any duration written here is a '
              'guess that silently rots:\n${offenders.join('\n')}',
        );
      });
    }
  });

  // The window covers every photo of one person at once — it is keyed by
  // `photoExchangeId`, never by image. The expired copy said «الصورة».
  test('the Arabic copy speaks of the photos, not a photo', () {
    final offenders = <String>[];
    _photoViewStrings('ar').forEach((key, value) {
      if (value.contains('الصورة')) offenders.add('$key = $value');
    });

    expect(
      offenders,
      isEmpty,
      reason:
          'one window covers the whole set, so the copy must be plural:\n'
          '${offenders.join('\n')}',
    );
  });

  // Guards the guard: if the section ever empties, the two tests above pass
  // vacuously and stop meaning anything.
  test('there are photo-view strings to police', () {
    expect(_photoViewStrings('ar').length, greaterThan(4));
    expect(_photoViewStrings('en').length, greaterThan(4));
  });

  group('the expired overlay says it will not come back', () {
    Future<void> pumpExpired(WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar')],
          path: 'unused',
          assetLoader: const _KeyLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: PhotoViewScope(
                state: const PhotoViewState(phase: PhotoViewPhase.consumed),
                onReveal: () {},
                onRetry: () {},
                onImageForbidden: () {},
                child: const Scaffold(
                  body: Stack(children: [PhotoViewOverlay()]),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Two assertions rather than one, because the headline alone reads as
    // "come back later" — which is the opposite of what happened.
    testWidgets('headline AND the permanence note', (tester) async {
      await pumpExpired(tester);

      expect(
        find.text('likes.matches_photo_view_expired'),
        findsOneWidget,
        reason: 'the expired headline is missing',
      );
      expect(
        find.text('likes.matches_photo_view_expired_note'),
        findsOneWidget,
        reason:
            'the overlay states only that the window closed. Nothing on this '
            'screen tells the member it was their one opening.',
      );
    });
  });
}
