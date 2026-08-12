import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/my_profile_model.dart';

/// The DisplayName/RealName migration on `GET /api/profile`. Two things must
/// hold: `realName` never leaks into the public-facing name, and the lock
/// fields survive the wire.
void main() {
  Map<String, dynamic> json(Map<String, dynamic> overrides) => {
    'userId': 'u-1',
    'gender': 'Male',
    'age': 30,
    'profileStatus': 'Visible',
    'hasAnsweredQuestions': true,
    ...overrides,
  };

  test('displayName wins over the legacy name alias', () {
    final profile = MyProfileModel.fromJson(
      json({'displayName': 'أبو محمد', 'name': 'legacy'}),
    ).toEntity();
    expect(profile.name, 'أبو محمد');
  });

  test('realName is never used as the display name', () {
    // The whole point of the split: a legal name must not surface on a card
    // or a chat header just because the display name is missing.
    final profile = MyProfileModel.fromJson(
      json({'realName': 'محمد عبدالله السالم'}),
    ).toEntity();
    expect(profile.name, isEmpty);
    expect(profile.realName, 'محمد عبدالله السالم');
  });

  test('the lock fields parse', () {
    final profile = MyProfileModel.fromJson(
      json({
        'displayName': 'سارة',
        'isDefaultName': false,
        'isDisplayNameLocked': true,
        'displayNameLockedUntil': '2026-08-19T12:00:00Z',
      }),
    ).toEntity();
    expect(profile.isDefaultName, isFalse);
    expect(profile.isDisplayNameLocked, isTrue);
    expect(
      profile.displayNameLockedUntil?.toUtc(),
      DateTime.utc(2026, 8, 19, 12),
    );
  });

  test('a payload that predates the migration is treated as unlocked', () {
    // An older server (or a cached response) omits all three. Defaulting to
    // "locked" would strand the user with no way to set a name at all.
    final profile = MyProfileModel.fromJson(json({'name': 'مستخدم'})).toEntity();
    expect(profile.isDefaultName, isFalse);
    expect(profile.isDisplayNameLocked, isFalse);
    expect(profile.displayNameLockedUntil, isNull);
  });

  test('the default-name flag survives as sent', () {
    final profile = MyProfileModel.fromJson(
      json({'displayName': 'مستخدم', 'isDefaultName': true}),
    ).toEntity();
    expect(profile.isDefaultName, isTrue);
  });
}
