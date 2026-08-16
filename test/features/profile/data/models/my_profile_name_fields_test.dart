import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/my_profile_model.dart';

/// The DisplayName/RealName split on `GET /api/profile`: `realName` never
/// leaks into the public-facing name, and `isDefaultName` survives the wire.
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

  test('realName parses when present and is null when absent', () {
    final withName = MyProfileModel.fromJson(
      json({'displayName': 'سارة', 'realName': 'سارة السالم'}),
    ).toEntity();
    expect(withName.realName, 'سارة السالم');

    final without = MyProfileModel.fromJson(
      json({'displayName': 'سارة'}),
    ).toEntity();
    expect(without.realName, isNull);
  });

  test('the default-name flag survives as sent', () {
    final profile = MyProfileModel.fromJson(
      json({'displayName': 'مستخدم', 'isDefaultName': true}),
    ).toEntity();
    expect(profile.isDefaultName, isTrue);
  });

  test('an omitted default-name flag reads as false', () {
    // Defaulting to true would show the "set a real name" banner to everyone
    // on a payload that simply predates the field.
    final profile = MyProfileModel.fromJson(
      json({'name': 'مستخدم'}),
    ).toEntity();
    expect(profile.isDefaultName, isFalse);
  });

  test('retired lock keys on the wire are ignored, not parsed', () {
    // The backend never had a cooldown; if a stale payload still carries the
    // fields the client must simply not care.
    final profile = MyProfileModel.fromJson(
      json({
        'displayName': 'سارة',
        'isDisplayNameLocked': true,
        'displayNameLockedUntil': '2026-08-19T12:00:00Z',
      }),
    ).toEntity();
    expect(profile.name, 'سارة');
    expect(profile.isDefaultName, isFalse);
  });
}
