import 'package:qeran/features/chat/domain/entities/shared_profile.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart'
    as discovery;
import 'package:qeran/features/discovery/domain/entities/profile_image.dart'
    as discovery_image;
import 'package:qeran/features/likes/domain/entities/like_profile_image.dart';
import 'package:qeran/features/likes/domain/entities/like_request_card.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';

import '../domain/entities/other_profile.dart';
import '../domain/entities/profile_image.dart';

/// Adapters that build an [OtherProfile] from preview shapes already in
/// hand (Discovery deck, Chat shared bubble, Like row, Match card).
/// `placements` is always empty on a seed — full details land via the
/// hydration call inside [ProfileDetailsCubit].
class OtherProfileSeed {
  const OtherProfileSeed._();

  static OtherProfile fromDiscovery(discovery.DiscoveryProfile profile) {
    return OtherProfile(
      id: profile.id,
      name: profile.name,
      age: profile.age,
      matchingScore: profile.matchingScore,
      images: profile.images.map(_fromDiscoveryImage).toList(growable: false),
      placements: const [],
    );
  }

  static OtherProfile fromSharedProfile(SharedProfile profile) {
    return OtherProfile(
      id: profile.id,
      name: profile.name,
      age: profile.age,
      matchingScore: profile.matchingScore,
      images: profile.images
          .map((i) => OtherProfileImage(
                id: i.id,
                url: i.url,
                isProfile: i.isProfile,
                isBlurred: i.isBlurred,
              ))
          .toList(growable: false),
      placements: const [],
    );
  }

  static OtherProfile fromLikeRequestCard(LikeRequestCard card) {
    return OtherProfile(
      id: card.profileId,
      name: card.name,
      age: null,
      matchingScore: 0,
      images: card.profileImage == null
          ? const []
          : <OtherProfileImage>[_fromLikeImage(card.profileImage!)],
      placements: const [],
    );
  }

  static OtherProfile fromMatchCard(MatchCard card) {
    return OtherProfile(
      id: card.otherUserId,
      name: card.otherUserName,
      age: null,
      matchingScore: 0,
      images: card.images.map(_fromMatchImage).toList(growable: false),
      placements: const [],
    );
  }

  static OtherProfileImage _fromDiscoveryImage(discovery_image.ProfileImage i) {
    return OtherProfileImage(
      id: i.id,
      url: i.url,
      isProfile: i.isProfile,
      isBlurred: i.isBlurred,
    );
  }

  static OtherProfileImage _fromLikeImage(LikeProfileImage i) {
    return OtherProfileImage(
      id: i.id,
      url: i.url,
      isProfile: i.isProfile,
      isBlurred: i.isBlurred,
    );
  }

  static OtherProfileImage _fromMatchImage(MatchImage i) {
    return OtherProfileImage(
      id: i.id,
      url: i.url,
      isProfile: i.isProfile,
      isBlurred: i.isBlurred,
    );
  }
}
