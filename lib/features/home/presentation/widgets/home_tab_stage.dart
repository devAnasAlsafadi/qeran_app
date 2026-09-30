import 'package:flutter/material.dart';
import 'package:qeran/core/widgets/locale_rebuild_scope.dart';

import '../home_tab_switcher.dart';

/// Keeps visited tabs alive while giving the active pair a transform-only
/// page transition. No full-screen Opacity/saveLayer is introduced.
class HomeTabStage extends StatelessWidget {
  const HomeTabStage({super.key, required this.tabs, required this.tabBuilder});

  final HomeTabSwitcher tabs;
  final Widget Function(int index) tabBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final direction = tabs.direction * (isRtl ? -1 : 1);
        return ClipRect(
          child: AnimatedBuilder(
            animation: tabs.curve,
            builder: (context, _) {
              final previous = tabs.previousTab;
              final t = previous == null ? 1.0 : tabs.curve.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  for (final index in tabs.visited)
                    if (index != tabs.currentTab && index != previous)
                      _entry(index, enabled: false, offstage: true),
                  if (previous != null)
                    _entry(
                      previous,
                      enabled: true,
                      offset: Offset(-direction * width * 0.18 * t, 0),
                    ),
                  _entry(
                    tabs.currentTab,
                    enabled: true,
                    offset: Offset(direction * width * (1.0 - t), 0),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _entry(
    int index, {
    required bool enabled,
    bool offstage = false,
    Offset offset = Offset.zero,
  }) {
    return KeyedSubtree(
      key: ValueKey<String>('home-tab-$index'),
      child: Offstage(
        offstage: offstage,
        child: Transform.translate(
          offset: offset,
          child: TickerMode(
            enabled: enabled,
            child: IgnorePointer(
              ignoring: !enabled || tabs.isAnimating,
              // Tabs stay mounted, so without this a language switch would
              // leave every already-fetched tab in the old language until the
              // user pulled to refresh it by hand.
              child: RepaintBoundary(
                child: LocaleRebuildScope(child: tabBuilder(index)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
