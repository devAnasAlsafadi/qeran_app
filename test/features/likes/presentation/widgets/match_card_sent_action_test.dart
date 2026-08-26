import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_sent_action.dart';

/// Three CTAs share this rule — the stage-0 inquiry and the stage-1/2 formal
/// step — and before it they gave three different answers to "what does a
/// sent button look like?". The formal step never relabelled; the inquiry
/// went dead on tap.
MatchCardSentAction _inquiry({required bool isSent}) =>
    MatchCardSentAction.resolve(
      isSent: isSent,
      cta: 'send your questions',
      sentLabel: 'inquiry sent',
      unsentVariant: QeranButtonVariant.primaryWine,
    );

MatchCardSentAction _formal({required bool isSent}) =>
    MatchCardSentAction.resolve(
      isSent: isSent,
      cta: 'formal step',
      sentLabel: 'request sent',
      unsentVariant: QeranButtonVariant.primary,
      staysTappableWhenSent: false,
    );

void main() {
  test('unsent reads as the call to action', () {
    expect(_inquiry(isSent: false).label, 'send your questions');
    expect(_formal(isSent: false).label, 'formal step');
  });

  // Emphasis is the stages' own business: the inquiry sits under the
  // photo-exchange CTA, the formal step IS its card's primary action. Only
  // the sent treatment is shared, so unsent must stay untouched.
  test('unsent keeps each stage its own emphasis, and no checkmark', () {
    expect(_inquiry(isSent: false).variant, QeranButtonVariant.primaryWine);
    expect(_formal(isSent: false).variant, QeranButtonVariant.primary);
    expect(_inquiry(isSent: false).trailingIcon, isNull);
    expect(_formal(isSent: false).trailingIcon, isNull);
  });

  // Deliberately NOT unified. Having asked a question and having made a
  // formal request are different things to have done, and the member should
  // read which one they did.
  test('sent says so in each CTA own words, not one shared phrase', () {
    expect(_inquiry(isSent: true).label, 'inquiry sent');
    expect(_formal(isSent: true).label, 'request sent');
    expect(_inquiry(isSent: true).label, isNot(_formal(isSent: true).label));
  });

  // The point of the extraction: two buttons that look different before the
  // tap must look identical after it.
  test('the stages converge once sent, despite differing unsent', () {
    final inquiry = _inquiry(isSent: true);
    final formal = _formal(isSent: true);

    expect(inquiry.variant, formal.variant);
    expect(inquiry.trailingIcon, formal.trailingIcon);
  });

  test('sent de-emphasises to neutral and gains the checkmark', () {
    expect(_formal(isSent: true).variant, QeranButtonVariant.neutral);
    expect(_formal(isSent: true).trailingIcon, Icons.check_rounded);
  });

  // The one thing the two callers do NOT share, because a second tap means
  // different things to them. The inquiry's reopens the chat it posted to;
  // the formal step's spends a round trip to be told what its label already
  // says, so that one retires.
  group('what a second tap is worth', () {
    test('nothing is ever disabled before it is sent', () {
      expect(_inquiry(isSent: false).isEnabled, isTrue);
      expect(_formal(isSent: false).isEnabled, isTrue);
    });

    test('the inquiry stays tappable once sent', () {
      expect(_inquiry(isSent: true).isEnabled, isTrue);
    });

    test('the formal step retires once sent', () {
      expect(_formal(isSent: true).isEnabled, isFalse);
    });

    // Opting out has to be deliberate: a caller that says nothing keeps the
    // older behaviour rather than silently going dead.
    test('the default is to stay tappable', () {
      final quiet = MatchCardSentAction.resolve(
        isSent: true,
        cta: 'go',
        sentLabel: 'gone',
        unsentVariant: QeranButtonVariant.primary,
      );

      expect(quiet.isEnabled, isTrue);
    });
  });
}
