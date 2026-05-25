import 'package:equatable/equatable.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';

sealed class DiscoveryFilterState extends Equatable {
  const DiscoveryFilterState();

  @override
  List<Object?> get props => const [];
}

final class DiscoveryFilterInitial extends DiscoveryFilterState {
  const DiscoveryFilterInitial();
}

final class DiscoveryFilterLoading extends DiscoveryFilterState {
  const DiscoveryFilterLoading();
}

final class DiscoveryFilterFailure extends DiscoveryFilterState {
  final String message;
  const DiscoveryFilterFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loaded sheet state. `selections` is keyed by `questionId`. A question
/// without an entry in the map means "no constraint" — the user hasn't
/// touched it yet.
final class DiscoveryFilterLoaded extends DiscoveryFilterState {
  final List<DiscoveryFilterQuestion> questions;
  final Map<int, DiscoveryFilterSelection> selections;

  const DiscoveryFilterLoaded({
    required this.questions,
    required this.selections,
  });

  DiscoveryFilterLoaded copyWith({
    List<DiscoveryFilterQuestion>? questions,
    Map<int, DiscoveryFilterSelection>? selections,
  }) {
    return DiscoveryFilterLoaded(
      questions: questions ?? this.questions,
      selections: selections ?? this.selections,
    );
  }

  @override
  List<Object?> get props => [questions, selections];
}
