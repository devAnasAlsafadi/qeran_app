import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_composer_state.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_gate.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'composer_cubit_harness.dart';

/// The steps before writing (D17, D7; F1–F7, S5): a member who owes a real
/// name or the guidelines takes them, one at a time, before the field
/// opens.
void main() {
  late ComposerHarness h;

  tearDown(() => h.dispose());

  CommunityComposerEvent eventOf() => h.cubit.state.event;

  test('owes what the app says, from the start', () {
    h = ComposerHarness(owes: CommunityGate.name);

    expect(h.cubit.state.owes, CommunityGate.name);
  });

  test('a tap on the waiting field opens the first step', () {
    h = ComposerHarness(owes: CommunityGate.name);

    h.cubit.startWriting();

    expect(eventOf(), CommunityComposerEvent.openNameGate);
  });

  test('the name taken: the guidelines next, as the app now says', () {
    h = ComposerHarness(owes: CommunityGate.name);
    h.cubit.startWriting();

    h.owes = CommunityGate.guidelines;
    h.cubit.stepClosed(done: true);

    expect(h.cubit.state.owes, CommunityGate.guidelines);
    expect(eventOf(), CommunityComposerEvent.openGuidelines);
  });

  test('the last step taken: the field takes the focus (F6)', () {
    h = ComposerHarness(owes: CommunityGate.guidelines);
    h.cubit.startWriting();

    h.owes = null;
    h.cubit.stepClosed(done: true);

    expect(h.cubit.state.owes, isNull);
    expect(eventOf(), CommunityComposerEvent.focus);
  });

  test('a step left undone: nothing more, the field still waits (F7)', () {
    h = ComposerHarness(owes: CommunityGate.guidelines);
    h.cubit.startWriting();
    final version = h.cubit.state.eventVersion;

    h.cubit.stepClosed(done: false);

    expect(h.cubit.state.eventVersion, version);
    expect(h.cubit.state.owes, CommunityGate.guidelines);
  });

  test('Reply while a step is owed: the step, then the strip and the '
      'focus', () {
    h = ComposerHarness(owes: CommunityGate.name);
    final comment = testComment(id: 7);

    h.cubit.replyTo(comment);
    expect(eventOf(), CommunityComposerEvent.openNameGate);
    expect(h.cubit.state.replyTo, isNull);

    h.owes = null;
    h.cubit.stepClosed(done: true);
    expect(h.cubit.state.replyTo, comment);
    expect(eventOf(), CommunityComposerEvent.focus);
  });

  test('Reply, then the step left: no strip later', () {
    h = ComposerHarness(owes: CommunityGate.name);
    h.cubit.replyTo(testComment(id: 7));
    h.cubit.stepClosed(done: false);

    h.owes = null;
    h.cubit.stepClosed(done: true);

    expect(h.cubit.state.replyTo, isNull);
  });

  test('a step the app still sees as owed is not asked twice', () {
    h = ComposerHarness(owes: CommunityGate.name);
    h.cubit.startWriting();

    // The app's gate didn't hear of the new name: the server checks on send.
    h.cubit.stepClosed(done: true);

    expect(h.cubit.state.owes, isNull);
    expect(eventOf(), CommunityComposerEvent.focus);
  });

  for (final (outcome, gate, event) in [
    (
      const CommentNameRequired(),
      CommunityGate.name,
      CommunityComposerEvent.openNameGate,
    ),
    (
      const CommentGuidelinesRequired(),
      CommunityGate.guidelines,
      CommunityComposerEvent.openGuidelines,
    ),
  ]) {
    test('the server asks for $gate on send: that step, the text kept, '
        'then the field (S5)', () async {
      h = ComposerHarness()..answer = outcome;

      await h.cubit.submit('سؤال عن الاستخارة');
      expect(h.cubit.state.owes, gate);
      expect(eventOf(), event);
      expect(h.cubit.state.restore, 'سؤال عن الاستخارة');

      h.cubit.stepClosed(done: true);
      expect(eventOf(), CommunityComposerEvent.focus);
      // Nothing is sent again on its own: the member taps send (S5).
      expect(h.sent, hasLength(1));
    });
  }

  test('nothing owed: Reply focuses at once', () {
    h = ComposerHarness();

    h.cubit.replyTo(testComment(id: 7));

    expect(eventOf(), CommunityComposerEvent.focus);
  });
}
