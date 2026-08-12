import 'package:equatable/equatable.dart';

import 'profile_image.dart';

/// One tile in the photo manager grid.
///
/// The grid mixes photos that already live on the server with photos the
/// user has just picked but not uploaded yet. The two behave differently —
/// a server photo is deleted and promoted through the API, a staged photo
/// only exists locally until the batch upload runs — so the UI needs to
/// tell them apart without reaching for nullable fields.
sealed class PhotoSlot extends Equatable {
  const PhotoSlot();

  /// Whether this photo is the profile's main one. For a staged photo this
  /// is the user's local intent; it only reaches the server after upload.
  bool get isMain;
}

/// A photo the server already knows about.
final class ServerPhotoSlot extends PhotoSlot {
  const ServerPhotoSlot(this.image);

  final OwnerImage image;

  String get id => image.id;
  String get url => image.url;

  /// False while the matchmaker has yet to review it — the owner sees it,
  /// peers do not.
  bool get isApproved => image.isApproved;

  @override
  bool get isMain => image.isProfile;

  @override
  List<Object?> get props => [image];
}

/// A photo picked on-device and awaiting the batch upload.
final class StagedPhotoSlot extends PhotoSlot {
  const StagedPhotoSlot({required this.path, required this.isMain});

  final String path;

  @override
  final bool isMain;

  @override
  List<Object?> get props => [path, isMain];
}
