import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_status_section.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_timeline.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two defects this file exists to keep fixed, both found by the owner on a
/// case that had just been closed as unsuccessful.
///
///   1. The «المرحلة» row read «بانتظار تنسيق الخطّابة» while the timeline two
///      widgets above already said «لم ينجح». The backend FREEZES the case
///      `stage` field once the matchmaker takes over, so the row was reading a
///      value that had stopped moving. Its icon was looked up separately from
///      the same dead field, which is a second copy of the same bug.
///
///   2. «بانتظار تنسيق الخطّابة» wrapped onto two lines in a column half the
///      width it needed, because the short «المرحلة» label beside it was
///      `Expanded` and held space it did not use.
///
/// Measured against the SHIPPED fonts and the locale's real theme. The default
/// test font draws every glyph as a full em square and overstates Arabic by
/// roughly double, so a stub would fail copy that fits comfortably on a device.

class _DiskLoader extends AssetLoader {
  const _DiskLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      jsonDecode(
        File('assets/translations/${locale.languageCode}.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
}

Future<void> _loadFonts() async {
  const families = {
    'NotoKufiArabic': 'assets/fonts/NotoKufiArabic-Bold.ttf',
    'Montserrat': 'assets/fonts/Montserrat-Bold.ttf',
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        File(entry.value).readAsBytes().then(
          (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    await loader.load();
  }
}

CompatibilityCase _case({
  required CompatibilityCaseStage stage,
  FormalRequestStatus? formal,
}) {
  const user = CaseUser(
    userId: 'u',
    name: 'A',
    profileImageUrl: null,
    age: null,
    gender: null,
    isAssignedToMe: true,
  );
  return CompatibilityCase(
    caseId: 1,
    myUser: user,
    otherUser: user,
    likeAcceptedAt: DateTime.utc(2026, 8, 8),
    stage: stage,
    photoExchange: const CasePhotoExchange(
      requestId: 4,
      status: CasePhotoExchangeStatus.accepted,
      respondedAt: null,
      expiresAt: null,
      initiatorId: null,
      responderId: null,
    ),
    formalRequest:
        formal == null ? null : CaseFormalRequest(id: 9, status: formal),
    chat: const CaseChat(
      myUserConversationId: null,
      otherUserConversationId: null,
      otherMatchmakerId: null,
      otherMatchmakerConversationId: null,
      otherMatchmakerName: null,
      otherMatchmakerImageUrl: null,
    ),
    canUpdateFormalRequestStatus: true,
    hasMyNote: false,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required CompatibilityCase caseItem,
  required Locale locale,
  double width = 320,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'unused',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: QeranTheme.light(locale),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            // The page inset the detail screen actually uses, so the rows are
            // measured in the space they really get.
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: CaseStatusSection(caseItem: caseItem),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _shipped(Locale locale, String key) {
  final file = File('assets/translations/${locale.languageCode}.json');
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final parts = key.split('.');
  return (map[parts[0]] as Map<String, dynamic>)[parts[1]] as String;
}

/// The value rendered opposite [rowLabel], found by walking up to the shared
/// Row rather than by position — the rows reorder as fields drop out.
Text _valueOpposite(WidgetTester tester, String rowLabel) {
  final row = find.ancestor(of: find.text(rowLabel), matching: find.byType(Row));
  final texts = find
      .descendant(of: row.first, matching: find.byType(Text))
      .evaluate()
      .map((e) => e.widget as Text)
      .where((t) => t.data != null && t.data != rowLabel)
      .toList();
  expect(texts, hasLength(1), reason: 'expected one value beside "$rowLabel"');
  return texts.single;
}

/// The icon rendered in the same row as [rowLabel]. Scoped to the row because
/// two rows legitimately share a glyph — an ended case reports the closure in
/// both the stage row and the formal-status row, and both wear the lock.
Icon _iconIn(WidgetTester tester, String rowLabel) {
  final row = find.ancestor(of: find.text(rowLabel), matching: find.byType(Row));
  final icons = find
      .descendant(of: row.last, matching: find.byType(Icon))
      .evaluate()
      .map((e) => e.widget as Icon)
      .toList();
  expect(icons, hasLength(1), reason: 'expected one icon in the "$rowLabel" row');
  return icons.single;
}

/// Lines the paragraph actually laid out, counted from the glyph boxes'
/// distinct tops — RenderParagraph exposes no line metrics of its own.
int _lineCount(WidgetTester tester, String text) {
  final render = tester.renderObject<RenderParagraph>(find.text(text));
  final boxes = render.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    await EasyLocalization.ensureInitialized();
  });

  // ── FIX 1 ────────────────────────────────────────────────────────────────
  group('the stage row reports the case, not the frozen field', () {
    // The owner's case, exactly: closed as unsuccessful, with `stage` left
    // behind at the coordination step the backend never moves off.
    final reported = _case(
      stage: CompatibilityCaseStage.awaitingMatchmakerCoordination,
      formal: FormalRequestStatus.compatibilityClosed,
    );

    testWidgets('an ended case does not still read as coordinating', (
      tester,
    ) async {
      const locale = Locale('ar');
      await _pump(tester, caseItem: reported, locale: locale);

      final stale = _shipped(
        locale,
        LocaleKeys.matchmaker_cases_stage_awaiting_coordination,
      );
      final ended = _shipped(locale, LocaleKeys.matchmaker_cases_formal_closed);
      final value = _valueOpposite(
        tester,
        _shipped(locale, LocaleKeys.matchmaker_cases_field_stage),
      );

      expect(value.data, isNot(stale));
      expect(value.data, ended);
    });

    // The agreement guard. Rendering and projection are two views of one
    // answer; nothing may make them disagree again.
    for (final formal in FormalRequestStatus.values) {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        testWidgets(
          'agrees with the timeline node — ${formal.name} '
          '[${locale.languageCode}]',
          (tester) async {
            final item = _case(
              stage: CompatibilityCaseStage.awaitingMatchmakerCoordination,
              formal: formal,
            );
            await _pump(tester, caseItem: item, locale: locale);

            final step = currentCaseStep(item);
            final value = _valueOpposite(
              tester,
              _shipped(locale, LocaleKeys.matchmaker_cases_field_stage),
            );
            expect(value.data, _shipped(locale, step.labelKey));
          },
        );
      }
    }

    // The icon half. Fixing only the words would leave «لم ينجح» wearing the
    // handshake the coordination stage put there.
    testWidgets('the icon moves with the label', (tester) async {
      const locale = Locale('ar');
      await _pump(tester, caseItem: reported, locale: locale);

      final step = currentCaseStep(reported);
      final icon = _iconIn(
        tester,
        _shipped(locale, LocaleKeys.matchmaker_cases_field_stage),
      );
      expect(icon.icon, step.icon);
      // The glyph the frozen `stage` field would have supplied. Fixing the
      // words alone would have left «لم ينجح» under a handshake.
      expect(icon.icon, isNot(Icons.handshake_outlined));
    });

    // Rule: render only what the backend backs. `caseStagePlacement` answers
    // for every input, mapping an unreadable case onto the first node — which
    // would announce «التوافق الأولي» for a couple whose position we do not
    // actually know.
    testWidgets('an unplaceable case gets no stage row at all', (tester) async {
      const locale = Locale('ar');
      await _pump(
        tester,
        caseItem: _case(stage: CompatibilityCaseStage.unknown),
        locale: locale,
      );
      expect(
        find.text(_shipped(locale, LocaleKeys.matchmaker_cases_field_stage)),
        findsNothing,
      );
    });
  });

  // ── FIX 2 ────────────────────────────────────────────────────────────────
  group('row layout', () {
    // Under the old 50/50 split the value column was 112dp wide whatever the
    // label needed. These two strings are what the stage row can really show,
    // and both outran it. The label takes 38.6dp now, leaving 185.4dp at 360
    // and 145.4dp at 320.
    //
    // Neither is a round number picked to pass: «التواصل الرسمي مع الأهل» is
    // 165.4dp, so it discriminates at 360 but not at 320, and
    // «رُفضت الخطوة الرسمية» is 143.7dp, which discriminates at 320.
    const targets = [
      (
        stage: CompatibilityCaseStage.photoExchangeAccepted,
        formal: FormalRequestStatus.waitingForParentAppointment,
        key: LocaleKeys.matchmaker_cases_timeline_formal_contact,
        width: 360.0,
      ),
      (
        stage: CompatibilityCaseStage.formalStepRejected,
        formal: null,
        key: LocaleKeys.matchmaker_cases_stage_formal_step_rejected,
        width: 320.0,
      ),
    ];

    for (final t in targets) {
      testWidgets('the stage value fits on one line at '
          '${t.width.toInt()}dp — ${t.key.split('.').last}', (tester) async {
        const locale = Locale('ar');
        await _pump(
          tester,
          caseItem: _case(stage: t.stage, formal: t.formal),
          locale: locale,
          width: t.width,
        );
        final value = _shipped(locale, t.key);
        expect(find.text(value), findsOneWidget, reason: 'not the stage value');
        expect(_lineCount(tester, value), 1, reason: 'wrapped');
      });
    }

    // The label is a non-flex child now, so it is the one element in the row
    // that CANNOT be given less than it asks for. That is safe only while the
    // four field labels stay short — so it is checked rather than assumed.
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('no field label wraps or truncates at 320dp '
          '[${locale.languageCode}]', (tester) async {
        await _pump(
          tester,
          caseItem: _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.waitingForParentAppointment,
          ),
          locale: locale,
        );

        const labelKeys = [
          LocaleKeys.matchmaker_cases_field_stage,
          LocaleKeys.matchmaker_cases_field_formal_status,
          LocaleKeys.matchmaker_cases_field_photo_exchange,
          LocaleKeys.matchmaker_cases_field_like_accepted,
        ];
        for (final key in labelKeys) {
          final label = _shipped(locale, key);
          expect(find.text(label), findsOneWidget, reason: '$key not rendered');
          final render = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(render.didExceedMaxLines, isFalse, reason: '$key truncated');
          expect(
            _lineCount(tester, label),
            1,
            reason: '$key wrapped — it is non-flex and must fit',
          );
        }
      });
    }
  });
}
