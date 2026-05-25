import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/realtime_status.dart';

enum ConversationAsyncStatus { initial, loading, loaded, failure }

/// One-shot events the screen listens to for transient toasts /
/// paywall / banners. Versioned so the listener only reacts once per
/// emit.
enum ConversationEvent {
  none,
  // Send-text outcomes
  sendValidationEmpty,
  sendValidationTooLong,
  sendRateLimited,
  sendConversationNotFound,
  sendUnauthorized,
  sendFailure,
  // Share-profile outcomes
  shareProfileNotFound,
  shareValidation,
  shareRateLimited,
  shareConversationNotFound,
  shareUnauthorized,
  shareFailure,
  shareSuccess,
}

/// State for one open conversation. List is newest-first to match
/// the server's wire order and the `ListView(reverse: true)` render
/// order.
class ConversationStateData extends Equatable {
  final int conversationId;
  final ConversationAsyncStatus initialStatus;
  final List<ChatMessage> messages;
  final String? loadErrorKey;
  final bool hasMore;
  final bool isPaginating;
  final bool paginationFailed;
  final int currentPage;
  final RealtimeStatus realtimeStatus;

  /// True once the realtime port has ever transitioned to `connected`.
  /// The banner uses this to suppress the "disconnected" pill during
  /// the brief initial-connect window — we only nag the user after a
  /// previously-established session drops.
  final bool hasEverBeenConnected;

  final Set<int> seenServerIds;
  final ConversationEvent event;
  final int eventVersion;

  /// Rate-limit cooldown floor. While `DateTime.now() < sendCooldownUntil`
  /// the composer disables itself.
  final DateTime? sendCooldownUntil;

  const ConversationStateData({
    required this.conversationId,
    this.initialStatus = ConversationAsyncStatus.initial,
    this.messages = const [],
    this.loadErrorKey,
    this.hasMore = false,
    this.isPaginating = false,
    this.paginationFailed = false,
    this.currentPage = 0,
    this.realtimeStatus = RealtimeStatus.disconnected,
    this.hasEverBeenConnected = false,
    this.seenServerIds = const <int>{},
    this.event = ConversationEvent.none,
    this.eventVersion = 0,
    this.sendCooldownUntil,
  });

  ConversationStateData copyWith({
    ConversationAsyncStatus? initialStatus,
    List<ChatMessage>? messages,
    String? loadErrorKey,
    bool clearLoadError = false,
    bool? hasMore,
    bool? isPaginating,
    bool? paginationFailed,
    int? currentPage,
    RealtimeStatus? realtimeStatus,
    bool? hasEverBeenConnected,
    Set<int>? seenServerIds,
    ConversationEvent? event,
    int? eventVersion,
    DateTime? sendCooldownUntil,
    bool clearSendCooldown = false,
  }) {
    return ConversationStateData(
      conversationId: conversationId,
      initialStatus: initialStatus ?? this.initialStatus,
      messages: messages ?? this.messages,
      loadErrorKey:
          clearLoadError ? null : (loadErrorKey ?? this.loadErrorKey),
      hasMore: hasMore ?? this.hasMore,
      isPaginating: isPaginating ?? this.isPaginating,
      paginationFailed: paginationFailed ?? this.paginationFailed,
      currentPage: currentPage ?? this.currentPage,
      realtimeStatus: realtimeStatus ?? this.realtimeStatus,
      hasEverBeenConnected:
          hasEverBeenConnected ?? this.hasEverBeenConnected,
      seenServerIds: seenServerIds ?? this.seenServerIds,
      event: event ?? this.event,
      eventVersion: eventVersion ?? this.eventVersion,
      sendCooldownUntil: clearSendCooldown
          ? null
          : (sendCooldownUntil ?? this.sendCooldownUntil),
    );
  }

  @override
  List<Object?> get props => [
        conversationId,
        initialStatus,
        messages,
        loadErrorKey,
        hasMore,
        isPaginating,
        paginationFailed,
        currentPage,
        realtimeStatus,
        hasEverBeenConnected,
        seenServerIds,
        event,
        eventVersion,
        sendCooldownUntil,
      ];
}
