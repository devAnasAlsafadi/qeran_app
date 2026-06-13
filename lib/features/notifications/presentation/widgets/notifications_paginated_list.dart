import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';

/// Pull-to-refresh + infinite-scroll shell for the notifications inbox.
///
/// User-local (a lean sibling of the matchmaker's paginated list — promotion to
/// a shared core widget is deliberately deferred):
///   • [onRefresh] runs on pull-down (wine-tinted RefreshIndicator).
///   • [onLoadMore] fires once when the viewport nears the end and [hasMore] is
///     true; reentrancy-guarded so one scroll never fires it twice.
///
/// Pass the rendered `ListView` as [child].
class NotificationsPaginatedList extends StatefulWidget {
  const NotificationsPaginatedList({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
    this.loadMoreThreshold = 280,
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final bool hasMore;

  /// Pixels from the end at which `onLoadMore` fires.
  final double loadMoreThreshold;

  @override
  State<NotificationsPaginatedList> createState() =>
      _NotificationsPaginatedListState();
}

class _NotificationsPaginatedListState
    extends State<NotificationsPaginatedList> {
  bool _loadingMoreInFlight = false;

  bool _onScrollNotification(ScrollNotification n) {
    if (!widget.hasMore || _loadingMoreInFlight) return false;
    final remaining = n.metrics.maxScrollExtent - n.metrics.pixels;
    if (remaining <= widget.loadMoreThreshold) {
      _loadingMoreInFlight = true;
      widget.onLoadMore().whenComplete(() {
        if (mounted) _loadingMoreInFlight = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: QeranColors.wine,
      backgroundColor: QeranColors.paper,
      onRefresh: widget.onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.child,
      ),
    );
  }
}

/// "Loading more" footer — drop in as the last item while the cubit reports
/// `isLoadingMore: true`.
class NotificationsLoadMoreFooter extends StatelessWidget {
  const NotificationsLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s20),
      child: Center(child: QeranLoader.inline()),
    );
  }
}
