import 'package:equatable/equatable.dart';

/// Which inbox notifications the user has read.
///
/// The backend exposes no read-state, so this is entirely local and stored in
/// two parts: a [watermark] ("everything this old and older is read", set by
/// "mark all as read") plus the handful of [readIds] above it that were opened
/// one at a time. Two parts rather than one big set so clearing the inbox stays
/// O(1) and the stored list can never grow without bound.
///
/// Distinct from the bell's "seen" heuristic: visiting the inbox clears the
/// dot, but the rows stay marked unread until they are actually opened.
class NotificationReadState extends Equatable {
  const NotificationReadState({
    this.watermark = 0,
    this.readIds = const <int>{},
  });

  /// Ids at or below this are read.
  final int watermark;

  /// Individually-read ids ABOVE [watermark].
  final Set<int> readIds;

  bool isRead(int id) => id <= watermark || readIds.contains(id);

  bool isUnread(int id) => !isRead(id);

  /// True when at least one of [ids] is still unread. Drives whether the
  /// "mark all as read" action is offered at all — a control that would do
  /// nothing is not rendered.
  bool hasUnreadAmong(Iterable<int> ids) => ids.any(isUnread);

  @override
  List<Object?> get props => [watermark, readIds];
}
