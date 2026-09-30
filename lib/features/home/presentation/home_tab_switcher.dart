import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qeran/core/utils/keyboard_dismissal.dart';

/// Which of the user shell's tabs shows, which are mounted, and the slide
/// between the two involved in a switch. `HomeTabStage` draws it.
///
/// Tabs mount lazily: an index enters [visited] the first time it is shown and
/// stays (the stage keeps it alive after), so each tab fetches on first visit
/// and never re-fetches on later switches. Seeded with the tab shown at shell
/// entry so only that one loads on cold start.
class HomeTabSwitcher extends ChangeNotifier {
  HomeTabSwitcher({required TickerProvider vsync, required int initialTab})
    : _currentTab = initialTab,
      _visited = {initialTab},
      _transition = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 240),
      );

  final AnimationController _transition;
  late final CurvedAnimation curve = CurvedAnimation(
    parent: _transition,
    curve: Curves.easeOutCubic,
  );

  final Set<int> _visited;
  int _currentTab;
  int? _previousTab;
  int _direction = 1;
  bool _pending = false;
  bool _disposed = false;

  int get currentTab => _currentTab;

  /// The tab sliding out, while a switch is animating; null otherwise.
  int? get previousTab => _previousTab;

  /// 1 when moving to a higher index, -1 to a lower one — in reading order,
  /// before any mirroring for the layout direction.
  int get direction => _direction;

  Iterable<int> get visited => _visited;
  bool get isAnimating => _transition.isAnimating;

  Future<void> select(int index) async {
    if (index == _currentTab || _pending) return;
    // Visited tabs stay mounted offstage. Clear a composer/form focus before
    // hiding its tab so Android cannot restore that invisible field (and its
    // keyboard) over the newly selected tab later.
    unawaited(dismissKeyboard());
    _pending = true;
    if (!_visited.contains(index)) {
      // Build the destination offstage first. Its initial layout/fetch can no
      // longer land on the first frame of the visible tab transition.
      _visited.add(index);
      notifyListeners();
      await WidgetsBinding.instance.endOfFrame;
      if (_disposed) return;
    }

    _previousTab = _currentTab;
    _direction = index > _currentTab ? 1 : -1;
    _currentTab = index;
    notifyListeners();
    try {
      await _transition.forward(from: 0);
    } finally {
      if (!_disposed) {
        _previousTab = null;
        notifyListeners();
      }
      _pending = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    curve.dispose();
    _transition.dispose();
    super.dispose();
  }
}
