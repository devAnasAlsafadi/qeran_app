import 'package:equatable/equatable.dart';

import '../../../domain/entities/community_guidelines.dart';

enum CommunityGuidelinesStatus { loading, ready, failed }

/// One-shot outcomes, told apart by [CommunityGuidelinesState.eventVersion].
enum CommunityGuidelinesEvent {
  none,

  /// Stored: the step closes, and the member goes on writing (F6).
  accepted,

  /// Not stored — the screen stays, and says so.
  acceptFailed,
}

class CommunityGuidelinesState extends Equatable {
  final CommunityGuidelinesStatus status;

  /// The text on screen; null until the first read lands.
  final CommunityGuidelines? guidelines;

  /// An accept is on its way — or done, and the step is closing.
  final bool accepting;
  final CommunityGuidelinesEvent event;
  final int eventVersion;

  const CommunityGuidelinesState({
    this.status = CommunityGuidelinesStatus.loading,
    this.guidelines,
    this.accepting = false,
    this.event = CommunityGuidelinesEvent.none,
    this.eventVersion = 0,
  });

  /// «أوافق وأتابع» works only on text the member can read (S6).
  bool get canAccept => status == CommunityGuidelinesStatus.ready && !accepting;

  CommunityGuidelinesState copyWith({
    CommunityGuidelinesStatus? status,
    CommunityGuidelines? guidelines,
    bool? accepting,
  }) => CommunityGuidelinesState(
    status: status ?? this.status,
    guidelines: guidelines ?? this.guidelines,
    accepting: accepting ?? this.accepting,
    event: event,
    eventVersion: eventVersion,
  );

  /// This state, telling the screen [next] once.
  CommunityGuidelinesState withEvent(CommunityGuidelinesEvent next) =>
      CommunityGuidelinesState(
        status: status,
        guidelines: guidelines,
        accepting: accepting,
        event: next,
        eventVersion: eventVersion + 1,
      );

  @override
  List<Object?> get props => [
    status,
    guidelines,
    accepting,
    event,
    eventVersion,
  ];
}
