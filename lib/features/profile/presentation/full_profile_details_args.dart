import 'package:equatable/equatable.dart';

import '../domain/entities/other_profile.dart';
import '../domain/entities/profile_entry_source.dart';

/// Arguments for [RouteNames.fullProfileDetails]. Always carry the
/// canonical `userId` (so the screen can hydrate); the optional
/// `initialData` is a partial seed used to paint instantly while the
/// network call runs.
class FullProfileDetailsArgs extends Equatable {
  final String userId;
  final OtherProfile? initialData;
  final ProfileEntrySource entry;

  const FullProfileDetailsArgs({
    required this.userId,
    required this.entry,
    this.initialData,
  });

  @override
  List<Object?> get props => [userId, initialData, entry];
}
