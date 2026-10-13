import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/match_card_model.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// Run 7, item 5: the Mutual cards show the other member's residence, job and
/// age under the name, as Sent and Received do — each only when the row
/// carries it (TQ16: Tariq sends them on `matches` from his next deploy).
Map<String, dynamic> _row([Map<String, dynamic> extra = const {}]) => {
  'likeRequestId': 7,
  'otherUserId': 'u7',
  'otherUserName': 'User',
  'stage': 'WaitingForPhotoExchange',
  ...extra,
};

MatchCard _card(MatchStage stage, {int? age, String? residence, String? job}) =>
    MatchCard(
      likeRequestId: 1,
      otherUserId: 'u1',
      otherUserName: 'User',
      images: const [],
      stage: stage,
      pendingPhotoExchange: null,
      formalRequest: null,
      conversationId: null,
      age: age,
      residence: residence,
      job: job,
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('the row', () {
    test('direct keys', () {
      final card = MatchCardModel.fromJson(
        _row({'age': 29, 'residenceCountry': 'الكويت', 'job': 'مهندس'}),
      ).toEntity();
      expect((card.age, card.residence, card.job), (29, 'الكويت', 'مهندس'));
    });

    test('or its answers, by the question', () {
      final card = MatchCardModel.fromJson(
        _row({
          'answers': [
            {'question': 'بلد الإقامة', 'answer': 'قطر'},
            {'question': 'المهنة', 'answer': 'معلمة'},
          ],
        }),
      ).toEntity();
      expect((card.age, card.residence, card.job), (null, 'قطر', 'معلمة'));
    });

    test('none at all', () {
      final card = MatchCardModel.fromJson(_row()).toEntity();
      expect((card.age, card.residence, card.job), (null, null, null));
    });
  });

  for (final stage in [
    MatchStage.waitingForPhotoExchange,
    MatchStage.photosExchanged,
    MatchStage.matchmakerEngaged,
  ]) {
    testWidgets('${stage.name}: residence, job, age under the name', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: _card(stage, age: 29, residence: 'الكويت', job: 'مهندس'),
      );
      expect(find.text('الكويت'), findsOneWidget);
      expect(find.text('مهندس'), findsOneWidget);
      expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
      double x(IconData icon) => tester.getCenter(find.byIcon(icon)).dx;
      expect(
        x(Icons.location_on_outlined),
        greaterThan(x(Icons.work_outline_rounded)),
      );
      final name = tester.getRect(find.text('User'));
      expect(tester.getRect(find.text('الكويت')).top, greaterThan(name.top));
    });
  }

  testWidgets('a row with none shows no facts line', (tester) async {
    await pumpMatchCard(tester, card: _card(MatchStage.photosExchanged));
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    expect(find.byIcon(Icons.cake_outlined), findsNothing);
  });
}
