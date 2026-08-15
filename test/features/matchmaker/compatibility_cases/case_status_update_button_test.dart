// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_formal_request.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/case_timeline.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_card.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_labels.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The status-update control is deliberately UNCONDITIONAL: it shows on every
/// card, whatever the stage, and the sheet it opens explains a case that cannot
/// move rather than the button vanishing and leaving the matchmaker to wonder
/// where it went.
///
/// What IS conditional is which targets the sheet enables, and that is driven
/// by the server's transition graph — not by the stage.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

CompatibilityCase _case({
  required CompatibilityCaseStage stage,
  FormalRequestStatus? formal,
  bool canUpdate = true,
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
    likeAcceptedAt: null,
    stage: stage,
    photoExchange: null,
    formalRequest: formal == null
        ? null
        : CaseFormalRequest(id: 9, status: formal),
    chat: const CaseChat(
      myUserConversationId: null,
      otherUserConversationId: null,
      otherMatchmakerId: null,
      otherMatchmakerConversationId: null,
      otherMatchmakerName: null,
      otherMatchmakerImageUrl: null,
    ),
    canUpdateFormalRequestStatus: canUpdate,
    hasMyNote: false,
  );
}

Future<void> _pumpCard(WidgetTester tester, CompatibilityCase caseItem) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchmakerCaseCard(
                caseItem: caseItem,
                onUpdateStatus: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// What the sheet would enable for this case — the same expression the sheet
/// builds its rows from.
Set<FormalRequestStatus> _enabledTargets(CompatibilityCase c) {
  if (!c.canUpdateFormalRequestStatus) return const {};
  return c.formalRequest?.status.allowedNext ?? const {};
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // EasyLocalization reads its saved locale through SharedPreferences.
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('the button never disappears', () {
    for (final stage in CompatibilityCaseStage.values) {
      testWidgets('shown on ${stage.name}, with no formal request', (
        tester,
      ) async {
        await _pumpCard(tester, _case(stage: stage));

        expect(find.byIcon(Icons.update_rounded), findsOneWidget);
      });
    }

    // Including the three the ticket calls terminal, and including a case the
    // server says this matchmaker may not update at all.
    testWidgets('shown on a closed case', (tester) async {
      await _pumpCard(
        tester,
        _case(
          stage: CompatibilityCaseStage.photoExchangeAccepted,
          formal: FormalRequestStatus.compatibilityCancelled,
        ),
      );

      expect(find.byIcon(Icons.update_rounded), findsOneWidget);
    });

    testWidgets('shown even when the server forbids updating', (tester) async {
      await _pumpCard(
        tester,
        _case(
          stage: CompatibilityCaseStage.photoExchangeAccepted,
          formal: FormalRequestStatus.parentsVisited,
          canUpdate: false,
        ),
      );

      expect(find.byIcon(Icons.update_rounded), findsOneWidget);
    });
  });

  group('what the sheet offers', () {
    test('every target the sheet lists is a real transition target', () {
      // Nothing is listed that the server would never accept from anywhere.
      final reachable = {
        for (final from in FormalRequestStatus.values) ...from.allowedNext,
      };
      expect(statusUpdateTargets.toSet(), reachable);
    });

    test('a case with no formal request enables nothing', () {
      for (final stage in CompatibilityCaseStage.values) {
        expect(
          _enabledTargets(_case(stage: stage)),
          isEmpty,
          reason: '${stage.name} has not reached the formal track',
        );
      }
    });

    test('the two live statuses each enable a forward step and a closure', () {
      expect(
        _enabledTargets(
          _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.waitingForParentAppointment,
          ),
        ),
        {
          FormalRequestStatus.parentsVisited,
          FormalRequestStatus.compatibilityCancelled,
        },
      );
      expect(
        _enabledTargets(
          _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.parentsVisited,
          ),
        ),
        {
          FormalRequestStatus.successfullyClosed,
          FormalRequestStatus.compatibilityCancelled,
        },
      );
    });

    test('terminal statuses enable nothing — the sheet is all disabled', () {
      for (final terminal in [
        FormalRequestStatus.successfullyClosed,
        FormalRequestStatus.compatibilityClosed,
        FormalRequestStatus.compatibilityCancelled,
      ]) {
        expect(
          _enabledTargets(
            _case(
              stage: CompatibilityCaseStage.photoExchangeAccepted,
              formal: terminal,
            ),
          ),
          isEmpty,
          reason: '${terminal.name} is terminal',
        );
      }
    });

    test('the server permission flag alone can disable everything', () {
      expect(
        _enabledTargets(
          _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.waitingForParentAppointment,
            canUpdate: false,
          ),
        ),
        isEmpty,
      );
    });
  });

  group('the explanatory line', () {
    test('a case off the formal track is "not started", never "ended"', () {
      final c = _case(stage: CompatibilityCaseStage.likeAccepted);
      expect(c.formalRequest, isNull);
      // The sheet branches on formalRequest == null before consulting tone,
      // so a fresh case is never told it has finished.
      expect(currentCaseTone(c), isNot(CaseStepTone.ended));
    });

    test('a closed case reads as ended', () {
      expect(
        currentCaseTone(
          _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.compatibilityCancelled,
          ),
        ),
        CaseStepTone.ended,
      );
    });

    test('a successfully closed case reads as complete', () {
      expect(
        currentCaseTone(
          _case(
            stage: CompatibilityCaseStage.photoExchangeAccepted,
            formal: FormalRequestStatus.successfullyClosed,
          ),
        ),
        CaseStepTone.success,
      );
    });
  });
}
