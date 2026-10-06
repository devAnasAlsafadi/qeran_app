import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/account/data/models/matchmaker_me_model.dart';
import 'package:qeran/features/matchmaker/account/domain/entities/matchmaker_me.dart';

MatchmakerMe _parse(Map<String, dynamic> json) =>
    MatchmakerMeModel.fromJson(json).toEntity();

Map<String, dynamic> _me() => {
  'userId': 'mm-1',
  'name': 'هدى العتيبي',
  'email': 'anosa@test.com',
  'phoneNumber': '+966500000000',
  'gender': 'Female',
  'isActive': true,
  'isPhoneVerified': true,
  'createdAt': '2026-01-10T08:00:00Z',
  'profileImage': null,
  'referralCode': 'HUDA1',
};

void main() {
  test('her posting guidelines flag (contract §4.1), either way', () {
    expect(
      _parse({
        ..._me(),
        'communityGuidelinesAccepted': true,
      }).communityGuidelinesAccepted,
      isTrue,
    );
    expect(
      _parse({
        ..._me(),
        'communityGuidelinesAccepted': false,
      }).communityGuidelinesAccepted,
      isFalse,
    );
  });

  test('a payload without the flag says nothing, never "accepted"', () {
    expect(_parse(_me()).communityGuidelinesAccepted, isNull);
  });

  test('a name or photo change keeps the flag', () {
    final me = _parse({..._me(), 'communityGuidelinesAccepted': true});

    expect(me.copyWith(name: 'هدى').communityGuidelinesAccepted, isTrue);
    expect(me.copyWith(name: 'هدى').name, 'هدى');
  });
}
