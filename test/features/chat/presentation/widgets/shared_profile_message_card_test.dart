import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/domain/entities/shared_profile.dart';
import 'package:qeran/features/chat/domain/entities/shared_profile_image.dart';
import 'package:qeran/features/chat/presentation/widgets/shared_profile_message_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    return const {
      'chat': {
        'shared_profile_score_label': 'Compatibility {percent}%',
        'shared_profile_shared_by_matchmaker': 'Shared by {name}',
        'shared_profile_shared_by_me': 'You shared this profile',
      }
    };
  }
}

SharedProfile _profile({
  String name = 'نور',
  int? age,
  double score = 0.0,
  bool hasImage = false,
}) {
  return SharedProfile(
    id: 'guid-x',
    name: name,
    age: age,
    matchingScore: score,
    images: hasImage
        ? const [
            SharedProfileImage(
              id: 'img-1',
              url: 'https://example/test.jpg',
              isProfile: true,
              isBlurred: true,
            ),
          ]
        : const [],
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('renders name + age when age is non-null', (tester) async {
    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(name: 'نور', age: 27),
        isMine: false,
      ),
    );
    expect(find.textContaining('نور'), findsOneWidget);
    expect(find.textContaining('27'), findsOneWidget);
  });

  testWidgets('omits age when null', (tester) async {
    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(name: 'نور', age: null),
        isMine: false,
      ),
    );
    expect(find.text('نور'), findsOneWidget);
    expect(find.textContaining('·'), findsNothing,
        reason: 'no age separator when age is null');
  });

  testWidgets('compatibility chip is HIDDEN when score == 0', (tester) async {
    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(score: 0),
        isMine: false,
      ),
    );
    expect(find.textContaining('Compatibility'), findsNothing);
  });

  testWidgets('compatibility chip rounds to whole percent when score > 0',
      (tester) async {
    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(score: 78.5),
        isMine: false,
      ),
    );
    // 78.5 → rounds to 79 via Dart's round() (banker's: 0.5 → away
    // from zero for positives).
    expect(find.textContaining('79'), findsOneWidget);
    expect(find.textContaining('Compatibility'), findsOneWidget);
  });

  testWidgets('footer label switches between mine and matchmaker variants',
      (tester) async {
    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(),
        isMine: true,
      ),
    );
    expect(find.text('You shared this profile'), findsOneWidget);

    await _pump(
      tester,
      SharedProfileMessageCard(
        profile: _profile(),
        isMine: false,
      ),
    );
    expect(find.textContaining('Shared by'), findsOneWidget);
  });

  testWidgets('does NOT register a tap handler (MVP)', (tester) async {
    // Pump a card inside a stack with a fallback gesture detector so
    // we can confirm the card itself doesn't swallow taps.
    var outerTapped = false;
    await _pump(
      tester,
      GestureDetector(
        onTap: () => outerTapped = true,
        child: SharedProfileMessageCard(
          profile: _profile(),
          isMine: false,
        ),
      ),
    );
    await tester.tap(find.byType(SharedProfileMessageCard));
    expect(outerTapped, isTrue,
        reason: 'card is non-tappable in MVP — tap reaches the ancestor');
  });
}
