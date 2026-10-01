import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';
import 'match_card_stage1_photo_harness.dart';

/// A formal step the OTHER side asked for, so the card shows the
/// accept / decline pair.
MatchCard _answeringFormalStep() {
  final now = DateTime.now().toUtc();
  return copyCard(
    MatchStage.photosExchanged,
    pendingFormalStep: PendingFormalStep(
      id: 55,
      likeRequestId: 1,
      status: FormalStepStatus.pending,
      remainingSeconds: 3600,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 47)),
      direction: 'Received',
      requestedByMe: false,
      canAccept: true,
      canReject: true,
    ),
  );
}

Future<void> _card(WidgetTester tester, MatchCard card) =>
    pumpMatchCard(tester, card: card, settle: false);

/// Every card state that draws buttons, with how many it draws — so a state
/// that silently stops drawing them can't pass for "all of them match".
final _states = <String, (Future<void> Function(WidgetTester), int)>{
  'no photo request yet: request photos + inquiry': (
    (t) => _card(t, copyCard(MatchStage.waitingForPhotoExchange)),
    2,
  ),
  'answering a photo request: the pair + inquiry': (
    (t) => _card(t, cardAwaitingMyResponse()),
    3,
  ),
  // Through the stage-1 rig: show-photos needs a gallery to open, which the
  // shared card rig doesn't wire.
  'photos exchanged: show photos + the formal step': (
    (t) => pumpStage1(t, photoCard(isBlurred: false)),
    2,
  ),
  'answering a formal step: the pair': (
    (t) => _card(t, _answeringFormalStep()),
    2,
  ),
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  // Buttons on one card always match: every one is compact, the full 48 pt
  // tap target.
  for (final MapEntry(key: name, value: (pump, count)) in _states.entries) {
    testWidgets('$name — every button is 48 pt', (tester) async {
      await pump(tester);

      final buttons = find.byType(QeranButton);
      expect(buttons, findsNWidgets(count));
      for (final element in buttons.evaluate()) {
        final button = element.widget as QeranButton;
        expect(button.size, QeranButtonSize.compact, reason: button.label);
        expect(element.size!.height, 48, reason: button.label);
      }
    });
  }
}
