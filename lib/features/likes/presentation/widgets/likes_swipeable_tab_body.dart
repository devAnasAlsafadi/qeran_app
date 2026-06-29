import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/chat/presentation/screens/chat_entry_screen.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/likes_tab.dart';
import '../blocs/likes_cubit.dart';
import '../blocs/likes_state.dart';
import '../screens/likes_received_section.dart';
import '../screens/likes_sent_section.dart';
import '../screens/matches_section.dart';

/// Horizontally swipeable body for the three Likes tabs.
///
/// Single source of truth is the cubit's `state.activeTab`:
/// • Swipe → `onPageChanged` writes it via `switchTab` (reusing the
///   existing lazy-load).
/// • Segment tap → writes it directly via `switchTab`; the new
///   `activeTab` flows back here and `didUpdateWidget` animates the page.
/// Either way the gold indicator (driven by `activeTab`) and the visible
/// page can never desync. Page order mirrors `LikesSegmentedTabs._order`.
class LikesSwipeableTabBody extends StatefulWidget {
  final LikesState state;
  const LikesSwipeableTabBody({super.key, required this.state});

  @override
  State<LikesSwipeableTabBody> createState() => _LikesSwipeableTabBodyState();
}

class _LikesSwipeableTabBodyState extends State<LikesSwipeableTabBody> {
  /// Visual page order — MUST match `LikesSegmentedTabs._order` so the
  /// page index, the segment, and the gold indicator all agree. RTL is
  /// handled by the ambient `Directionality` (page 0 sits on the right
  /// in Arabic); no per-locale index swap is needed here.
  static const List<LikesTab> _order = [
    LikesTab.sent,
    LikesTab.received,
    LikesTab.matches,
  ];

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _order.indexOf(widget.state.activeTab),
    );
  }

  @override
  void didUpdateWidget(covariant LikesSwipeableTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reconcile the page when `activeTab` changed from outside (segment
    // tap, deep-link, accept-success invalidation, etc). Guard against
    // re-animating to the page we're already on (avoids fighting a
    // settling swipe).
    final targetIndex = _order.indexOf(widget.state.activeTab);
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? targetIndex;
    if (current != targetIndex) {
      _pageController.animateToPage(
        targetIndex,
        duration: QeranMotion.standard,
        curve: QeranCurves.standard,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // The lone writer of cubit tab state for swipes; reuses the cubit's
    // built-in lazy-load. No-op inside `switchTab` if the tab is already
    // active (e.g. when this fires from a tap-driven `animateToPage`).
    context.read<LikesCubit>().switchTab(_order[index]);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        for (final tab in _order) _pageFor(tab, state),
      ],
    );
  }

  Widget _pageFor(LikesTab tab, LikesState state) {
    switch (tab) {
      case LikesTab.sent:
        return LikesSentSection(state: state);
      case LikesTab.received:
        return LikesReceivedSection(state: state);
      case LikesTab.matches:
        return MatchesSection(
          state: state,
          onContactMatchmaker: _onContactMatchmaker,
        );
    }
  }

  void _onContactMatchmaker(BuildContext context, String? conversationId) {
    // The user has exactly one matchmaker conversation, resolved by the
    // chat screen via `/api/chat/my-matchmaker`. `conversationId` is null
    // until a formalRequest exists (Stage 0), so we no longer gate on it
    // — the inquiry / formal-step button opens the matchmaker chat at
    // every stage. Preferred path: switch the bottom nav to the Messages
    // tab (preserves navigation state — no extra push).
    final shell = HomeShellScope.maybeOf(context);
    if (shell != null) {
      shell.openMessagesTab();
      return;
    }
    // Non-shell scope (deep link / widget test): push the real chat entry,
    // which self-resolves the single matchmaker conversation via
    // `/api/chat/my-matchmaker` (so the id arg isn't needed here).
    if (conversationId != null && conversationId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) =>
              ChatEntryScreen(onBack: () => Navigator.of(ctx).pop()),
        ),
      );
      return;
    }
    AppSnackBar.show(
      context,
      message:
          LocaleKeys.likes_matches_stage_matchmaker_will_contact.t(context),
      type: SnackBarType.info,
    );
  }
}
