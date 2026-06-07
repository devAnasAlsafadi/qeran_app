import 'package:equatable/equatable.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';

/// Parallel to `DiscoveryFilterState` (NOT reused, per the close-out plan —
/// discovery stays untouched). Reuses the discovery filter ENTITIES, which are
/// shared domain types.
sealed class MatchmakerExploreFilterState extends Equatable {
  const MatchmakerExploreFilterState();

  @override
  List<Object?> get props => const [];
}

final class MatchmakerExploreFilterInitial extends MatchmakerExploreFilterState {
  const MatchmakerExploreFilterInitial();
}

final class MatchmakerExploreFilterLoading extends MatchmakerExploreFilterState {
  const MatchmakerExploreFilterLoading();
}

final class MatchmakerExploreFilterFailure extends MatchmakerExploreFilterState {
  final String message;
  const MatchmakerExploreFilterFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loaded sheet state. [selections] is keyed by `questionId`; a question with
/// no entry means "no constraint".
final class MatchmakerExploreFilterLoaded extends MatchmakerExploreFilterState {
  final List<DiscoveryFilterQuestion> questions;
  final Map<int, DiscoveryFilterSelection> selections;

  const MatchmakerExploreFilterLoaded({
    required this.questions,
    required this.selections,
  });

  MatchmakerExploreFilterLoaded copyWith({
    List<DiscoveryFilterQuestion>? questions,
    Map<int, DiscoveryFilterSelection>? selections,
  }) {
    return MatchmakerExploreFilterLoaded(
      questions: questions ?? this.questions,
      selections: selections ?? this.selections,
    );
  }

  @override
  List<Object?> get props => [questions, selections];
}
