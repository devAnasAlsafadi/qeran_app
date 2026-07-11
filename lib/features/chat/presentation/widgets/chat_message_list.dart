import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/chat_message.dart';
import 'chat_date_separator.dart';
import 'chat_message_bubble.dart';

/// Scrolling chat list. `reverse: true` so the newest message lives
/// at the visual bottom while the in-memory list stays newest-first.
/// Scrolling **up** loads older pages.
class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final String me;

  /// Peer display name — powers the empty-state monogram + "start with {peer}".
  final String peerName;
  final bool hasMore;
  final bool isPaginating;
  final bool paginationFailed;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRetryPagination;
  final Future<void> Function() onRefresh;
  final void Function(ChatMessage failed)? onRetryFailedSend;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.me,
    required this.peerName,
    required this.hasMore,
    required this.isPaginating,
    required this.paginationFailed,
    required this.onLoadMore,
    required this.onRetryPagination,
    required this.onRefresh,
    this.onRetryFailedSend,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// In a reversed list, scrolling toward older messages drives
  /// `position.pixels` toward `maxScrollExtent`. Fire when within
  /// 200 dp of that limit.
  void _onScroll() {
    if (!widget.hasMore) return;
    if (widget.isPaginating) return;
    if (widget.paginationFailed) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _EmptyState(
        onRefresh: widget.onRefresh,
        peerName: widget.peerName,
      );
    }
    // Build items: each ChatMessage gets a bubble; insert a date
    // separator between days. List is newest-first; in a reversed
    // list the SEPARATOR sits BELOW its day's messages visually
    // (which means above older days — correct).
    final items = _buildItems(context);
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s16,
          vertical: QeranSpacing.s12,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => items[i],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final out = <Widget>[];
    DateTime? prevDay;
    // Compute index of last outgoing-sent-isRead message for the
    // subtle "Read" micro-label rule.
    int? lastReadOutgoingIndex;
    for (var i = 0; i < widget.messages.length; i++) {
      final m = widget.messages[i];
      if (m.senderId == widget.me && m.isRead && m.serverId != null) {
        lastReadOutgoingIndex = i;
        break;
      }
    }
    for (var i = 0; i < widget.messages.length; i++) {
      final m = widget.messages[i];
      final day = DateTime(m.sentAt.year, m.sentAt.month, m.sentAt.day);
      final isMine = m.senderId == widget.me;
      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s4),
        child: ChatMessageBubble(
          message: m,
          isMine: isMine,
          showReadReceipt: i == lastReadOutgoingIndex,
          onRetry: isMine ? () => widget.onRetryFailedSend?.call(m) : null,
        ),
      ));
      // Boundary: when iterating newest→oldest, the separator goes
      // AFTER the last message of a day (which is the visually older
      // edge of that day's block, since reverse:true flips order).
      if (prevDay != null && prevDay != day) {
        out.insert(out.length - 1, ChatDateSeparator(day: prevDay));
      }
      prevDay = day;
    }
    // Top of the visual list = end of items array. Add pagination
    // affordances there.
    if (widget.paginationFailed) {
      out.add(_PaginationError(onRetry: widget.onRetryPagination));
    } else if (widget.isPaginating) {
      out.add(const _PaginationSpinner());
    }
    return out;
  }
}

class _PaginationSpinner extends StatelessWidget {
  const _PaginationSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: QeranColors.wine,
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _PaginationError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s12),
      child: Center(
        child: TextButton.icon(
          onPressed: () => onRetry(),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 16,
            color: QeranColors.wine,
          ),
          label: Text(
            LocaleKeys.chat_messages_pagination_retry.t(context),
            style: QeranTypography.label.copyWith(color: QeranColors.wine),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String peerName;
  const _EmptyState({required this.onRefresh, required this.peerName});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: QeranColors.wine,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QeranMonogram(name: peerName, size: 72),
                      QeranSpacing.vs16,
                      Text(
                        LocaleKeys.chat_empty_title.t(context),
                        textAlign: TextAlign.center,
                        style: QeranTypography.subtitle.copyWith(
                          color: QeranColors.inkStrong,
                        ),
                      ),
                      QeranSpacing.vs8,
                      Text(
                        context.tr(
                          LocaleKeys.chat_empty_start_with,
                          namedArgs: {'peer': peerName},
                        ),
                        textAlign: TextAlign.center,
                        style: QeranTypography.body.copyWith(
                          color: QeranColors.inkMuted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
