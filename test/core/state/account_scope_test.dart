import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/state/account_scope.dart';

/// The one place the session reaches everything app-scoped that belongs to
/// the signed-in account.
void main() {
  test('a holder joins as it is built, and every holder forgets', () {
    final scope = AccountScope();
    final forgotten = <String>[];

    final held = scope.hold('gate', forgotten.add);
    scope.hold('badges', forgotten.add);
    scope.forgetAccount();

    expect(held, 'gate');
    expect(forgotten, ['gate', 'badges']);
  });

  test('a holder that throws does not stop the others forgetting', () {
    final scope = AccountScope();
    final forgotten = <String>[];
    scope.hold('broken', (_) => throw StateError('no'));
    scope.hold('badges', forgotten.add);

    scope.forgetAccount();

    expect(forgotten, ['badges']);
  });
}
