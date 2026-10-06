import 'package:qeran/features/matchmaker/account/domain/entities/matchmaker_me.dart';

/// Her `matchmaker/me`, saying [accepted] about the posting guidelines.
MatchmakerMe meWith({bool? accepted}) => MatchmakerMe(
  userId: 'mm-1',
  name: 'هدى',
  email: 'anosa@test.com',
  phoneNumber: '',
  gender: 'Female',
  isActive: true,
  isPhoneVerified: true,
  createdAt: null,
  image: null,
  referralCode: null,
  communityGuidelinesAccepted: accepted,
);
