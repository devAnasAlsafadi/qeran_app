import 'package:equatable/equatable.dart';

/// One-shot events surfaced by [ShareWithMatchmakerCubit] for screen
/// listeners (snackbars, dialog dismissal). The cubit bumps
/// [ShareWithMatchmakerState.eventVersion] each time a fresh event
/// fires so the listener can react exactly once.
enum ShareEvent {
  none,
  success,
  noMatchmaker,
  validation,
  rateLimited,
  conversationNotFound,
  unauthorized,
  profileNotFound,
  failure,
}

/// Screen-scoped share cubit state. `resolved` flips to `true` once we
/// know whether the user has a matchmaker (so the button can render
/// disabled / hidden appropriately). `conversationId` is null when no
/// matchmaker is assigned OR before the lookup resolves.
class ShareWithMatchmakerState extends Equatable {
  final bool resolved;
  final int? conversationId;
  final bool isSharing;
  final ShareEvent event;
  final int eventVersion;

  const ShareWithMatchmakerState({
    required this.resolved,
    required this.conversationId,
    required this.isSharing,
    required this.event,
    required this.eventVersion,
  });

  const ShareWithMatchmakerState.initial()
      : resolved = false,
        conversationId = null,
        isSharing = false,
        event = ShareEvent.none,
        eventVersion = 0;

  bool get hasMatchmaker => resolved && conversationId != null;

  ShareWithMatchmakerState copyWith({
    bool? resolved,
    int? conversationId,
    bool? isSharing,
    ShareEvent? event,
    int? eventVersion,
    bool clearConversationId = false,
  }) {
    return ShareWithMatchmakerState(
      resolved: resolved ?? this.resolved,
      conversationId:
          clearConversationId ? null : (conversationId ?? this.conversationId),
      isSharing: isSharing ?? this.isSharing,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props =>
      [resolved, conversationId, isSharing, event, eventVersion];
}
