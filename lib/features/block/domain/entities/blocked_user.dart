import 'package:equatable/equatable.dart';

/// A user the signed-in account has blocked. [imageUrl] is null for now (the
/// backend returns null until avatars are wired) — the UI falls back to a
/// monogram. [blockedAt] is the UTC instant the block was created.
class BlockedUser extends Equatable {
  final String userId;
  final String name;
  final String? imageUrl;
  final DateTime? blockedAt;

  const BlockedUser({
    required this.userId,
    required this.name,
    this.imageUrl,
    this.blockedAt,
  });

  @override
  List<Object?> get props => [userId, name, imageUrl, blockedAt];
}
