import 'package:flutter/widgets.dart';

import '../../../domain/entities/placement_item.dart';

/// Optional edit-affordance hook for text-type placement items.
///
/// When an ancestor installs this scope, [PlacementItemRenderer] shows a small
/// edit pencil next to each `type == text` item; tapping it calls [onEdit].
/// When NO scope is installed (the default — user-app discovery profile,
/// my-profile, etc.) `maybeOf` returns `null` and the renderer behaves exactly
/// as before: no pencil, no layout change.
///
/// This keeps the edit affordance MATCHMAKER-ONLY without a profile→matchmaker
/// dependency: the hook lives here (profile feature), and only the matchmaker
/// profile body provides a callback (P2c). The user must never see edit icons
/// on someone else's profile.
class TextAnswerEditScope extends InheritedWidget {
  const TextAnswerEditScope({
    super.key,
    required this.onEdit,
    this.inFlightQuestionId,
    required super.child,
  });

  /// Invoked with the tapped text item when its pencil is pressed.
  final void Function(PlacementItem item) onEdit;

  /// The `questionId` whose save is currently in flight — that item shows a
  /// small loader in place of its pencil. `null` when idle.
  final int? inFlightQuestionId;

  static TextAnswerEditScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextAnswerEditScope>();

  @override
  bool updateShouldNotify(TextAnswerEditScope oldWidget) =>
      onEdit != oldWidget.onEdit ||
      inFlightQuestionId != oldWidget.inFlightQuestionId;
}
