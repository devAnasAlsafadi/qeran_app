import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/formatting/guideline_icons.dart';

/// W2: the server names each rule's icon, and the client can change it.
void main() {
  test("the server's names, in both texts, each have an icon", () {
    for (final name in [
      'block',
      'phone_disabled',
      'lock',
      'campaign',
      'flag',
      'lightbulb',
      'shield',
    ]) {
      expect(
        guidelineIcon(name),
        isNot(guidelineIconFallback),
        reason: '"$name" is sent by the live server',
      );
    }
  });

  test("the boards' names too, should the client pick them", () {
    expect(guidelineIcon('handshake'), Icons.handshake_outlined);
    expect(guidelineIcon('gpp_bad'), Icons.gpp_bad_outlined);
    expect(guidelineIcon('person_off'), Icons.person_off_outlined);
  });

  test('a name the app does not know gets the neutral icon', () {
    expect(guidelineIcon('rocket_launch'), guidelineIconFallback);
    expect(guidelineIcon(''), guidelineIconFallback);
  });

  test('stray spaces around a name are ignored', () {
    expect(guidelineIcon(' lock '), Icons.lock_outline_rounded);
  });
}
