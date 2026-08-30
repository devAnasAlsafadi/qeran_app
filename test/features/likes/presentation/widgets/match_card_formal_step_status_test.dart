import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_formal_step_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two exhaustive switches answer for the post-approval stages — one decides
/// the retired button is a lie, the other decides what to say instead — and
/// the whole value of them being exhaustive is that a twelfth server stage
/// breaks the build in both rather than reading wrong in one.
///
/// A wildcard arm in either would compile and silently disagree, which is why
/// the agreement itself is asserted here rather than left to the reader.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Builder(
            builder: (inner) {
              captured = inner;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

const _pastApproval = [
  MatchCaseStage.awaitingMatchmakerCoordination,
  MatchCaseStage.parentsVisited,
  MatchCaseStage.marriageCompleted,
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // THE one that keeps the exhaustiveness honest. Swap either switch for a
  // wildcard and a stage can lose its button while keeping another stage's
  // subtitle, or keep a button it should have lost — neither of which any
  // single-stage test would notice.
  testWidgets('every stage that loses the button has words to replace it', (
    tester,
  ) async {
    final context = await _context(tester);

    for (final stage in MatchCaseStage.values) {
      expect(
        MatchCardFormalStepStatus.forStage(context, stage) != null,
        MatchCardFormalStepStatus.isPastApproval(stage),
        reason:
            '${stage.name}: one switch says the retired button is wrong here '
            'and the other has nothing to put in its place, or the reverse. '
            'They answer for the same set and must agree.',
      );
    }
  });

  testWidgets('no stage outside the three claims a line', (tester) async {
    final context = await _context(tester);

    for (final stage in MatchCaseStage.values) {
      if (_pastApproval.contains(stage)) continue;
      expect(
        MatchCardFormalStepStatus.forStage(context, stage),
        isNull,
        reason: '${stage.name} took over a post-approval line',
      );
    }
  });

  // A stage wearing another stage's glyph is the label bug this file was
  // split out of, one field over. The record shape makes the two travel
  // together; this is what stops one arm being edited alone.
  group('text and glyph belong to the same stage', () {
    testWidgets('each stage carries its own glyph', (tester) async {
      final context = await _context(tester);

      expect(
        MatchCardFormalStepStatus.forStage(
          context,
          MatchCaseStage.awaitingMatchmakerCoordination,
        )?.icon,
        Icons.check_circle_outline,
      );
      expect(
        MatchCardFormalStepStatus.forStage(
          context,
          MatchCaseStage.parentsVisited,
        )?.icon,
        Icons.groups_outlined,
      );
      expect(
        MatchCardFormalStepStatus.forStage(
          context,
          MatchCaseStage.marriageCompleted,
        )?.icon,
        Icons.favorite_rounded,
      );
    });

    // The assertion above pins the choices; this one pins the PROPERTY. Two
    // stages sharing a glyph would read as the same state on a card whose
    // status line is the only thing separating them.
    testWidgets('no two of them share a glyph', (tester) async {
      final context = await _context(tester);
      final glyphs = [
        for (final stage in _pastApproval)
          MatchCardFormalStepStatus.forStage(context, stage)!.icon,
      ];

      expect(glyphs.toSet(), hasLength(_pastApproval.length));
    });
  });
}
