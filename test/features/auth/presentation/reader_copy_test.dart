import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/reader_copy.dart';

import 'fake_session.dart';

const _member = UserEntity(id: 'u-1', name: 'Dima', email: 'dima@test.com');

void main() {
  test('her app reads her key', () {
    signInForTest();

    expect(signedInAsMatchmaker, isTrue);
    expect(
      'community.retry'.forReader(her: 'community.her.retry'),
      'community.her.retry',
    );
  });

  test("the member's app keeps the generic key", () {
    signInForTest(_member);

    expect(signedInAsMatchmaker, isFalse);
    expect(
      'community.retry'.forReader(her: 'community.her.retry'),
      'community.retry',
    );
  });

  test('no session at all reads as the generic key', () {
    expect(signedInAsMatchmaker, isFalse);
    expect(
      'community.retry'.forReader(her: 'community.her.retry'),
      'community.retry',
    );
  });
}
