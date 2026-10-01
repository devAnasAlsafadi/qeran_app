import 'package:flutter/material.dart';

import '../design_system/tokens/qeran_colors.dart';
import '../design_system/tokens/qeran_spacing.dart';
import '../design_system/widgets/qeran_loader.dart';

/// Pull-to-refresh + infinite-scroll wrapper for every paginated list in
/// the app (pairs with `PaginatedListState`). The caller owns the data and
/// the cubit; this widget is purely a shell:
///   • [onRefresh] runs on pull-down (wine-tinted RefreshIndicator).
///   • [onLoadMore] fires once when the viewport approaches the end and
///     [hasMore] is true. Reentrancy guarded internally so a single
///     scroll never fires it twice.
///
/// Pass the rendered scrollable (`ListView`, `GridView`, `CustomScrollView`)
/// as [child]; its scroll notifications drive [onLoadMore].
class PaginatedList extends StatefulWidget {
  const PaginatedList({
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
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  bool _loadingMoreInFlight = false;

  bool _onScrollNotification(ScrollNotification n) {
    if (!widget.hasMore) return false;
    if (_loadingMoreInFlight) return false;
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

/// Compact "loading more" footer for paginated lists. Drop in as the
/// last item when the cubit reports `isLoadingMore: true`.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s20),
      child: Center(child: QeranLoader(size: 24)),
    );
  }
}
