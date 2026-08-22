import 'package:flutter/widgets.dart';

/// Which match card currently has its journey open, offered to the cards
/// below it.
///
/// An inherited scope rather than constructor parameters, on the
/// [HomeShellScope] pattern: the card that needs this sits four widgets down
/// — list, card shell, stage card, journey card — and threading two
/// parameters through all four would touch three files that have nothing to
/// do with the question.
///
/// Absent scope means every card keeps its own state, which is what the
/// journey card's own tests rely on.
class MatchJourneyScope extends InheritedWidget {
  const MatchJourneyScope({
    super.key,
    required this.openLikeRequestId,
    required this.onOpenChanged,
    required super.child,
  });

  /// Null when nothing is open.
  final int? openLikeRequestId;

  /// Reports the card and the state it is asking for. Closing sends `false`
  /// for the card being closed, not null.
  final void Function(int likeRequestId, bool open) onOpenChanged;

  bool isOpen(int likeRequestId) => openLikeRequestId == likeRequestId;

  static MatchJourneyScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchJourneyScope>();

  @override
  bool updateShouldNotify(MatchJourneyScope oldWidget) =>
      openLikeRequestId != oldWidget.openLikeRequestId;
}
