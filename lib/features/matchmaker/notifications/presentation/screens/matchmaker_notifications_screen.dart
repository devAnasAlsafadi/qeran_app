import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_app_bar.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/data/matchmaker_notification_router.dart';
import '../../domain/entities/matchmaker_notification.dart';
import '../blocs/matchmaker_notification_read_cubit.dart';
import '../blocs/matchmaker_notifications_cubit.dart';
import '../routing/open_notified.dart';
import '../widgets/matchmaker_notifications_list.dart';

/// The matchmaker notification inbox (F5). Paginated list backed by
/// `GET /notifications`. A row tap deep-links via
/// [MatchmakerNotificationRouter].
///
/// Two separate ideas, the same split the user app makes:
/// * **seen** clears the bell — a server-side count, cleared through
///   [BadgesCubit] on the way OUT, so a load that failed never clears a badge
///   for notifications the matchmaker never saw.
/// * **read** ([MatchmakerNotificationReadCubit]) lifts a row, and stays LOCAL.
///   Coarser than the user app's: with no per-id endpoint there is no "mark
///   this one read", so a row is unread when it arrived since the last visit.
///   The watermark the rows render against is frozen at mount and advanced on
///   the way OUT, so arriving doesn't erase the very thing the user came for.
class MatchmakerNotificationsScreen extends StatefulWidget {
  const MatchmakerNotificationsScreen({super.key});

  @override
  State<MatchmakerNotificationsScreen> createState() =>
      _MatchmakerNotificationsScreenState();
}

class _MatchmakerNotificationsScreenState
    extends State<MatchmakerNotificationsScreen> {
  late final MatchmakerNotificationsCubit _cubit;
  late final MatchmakerNotificationReadCubit _readCubit;

  /// Highest id the screen has loaded — the read watermark written on exit.
  int _newestLoadedId = 0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MatchmakerNotificationsCubit>()..loadFirst();
    _readCubit = sl<MatchmakerNotificationReadCubit>()..load();
  }

  @override
  void dispose() {
    // On the way out, not on load: the rows stay lifted for the whole visit,
    // and the NEXT visit starts clean. Both are fire-and-forget, and neither
    // emits into this tree, so the close below is safe.
    //
    // The bell moved here from initState to share the guard: mark-seen is
    // server-side now, so clearing it after a load that failed would lose the
    // badge for notifications the matchmaker never saw.
    if (_newestLoadedId > 0) {
      _readCubit.markAllRead(_newestLoadedId);
      sl<BadgesCubit>().markSeen(BadgeTabKeys.notifications);
    }
    _readCubit.close();
    _cubit.close();
    super.dispose();
  }

  void _rememberNewest(List<MatchmakerNotification> items) {
    for (final n in items) {
      if (n.id > _newestLoadedId) _newestLoadedId = n.id;
    }
  }

  /// Deep-link a tapped row.
  ///
  /// Chat is PUSHED on top of this inbox, so back returns here. A Cases row
  /// cannot be: the tab lives in the shell BELOW this route, so the inbox pops
  /// and hands the intent up — the same shape the user app uses. It used to
  /// fall through to a bare `break`, which meant tapping a case row in the
  /// matchmaker inbox did nothing at all.
  void _onTap(MatchmakerNotification n) {
    final link = MatchmakerNotificationRouter.parse(n.data);
    switch (link) {
      case OpenCases():
        Navigator.of(context).pop(link);
        return;
      case IgnoreDeepLink():
        return;
      case OpenUserChat():
        openNotifiedChat(context, link);
      case OpenPost():
        unawaited(openNotifiedPost(context, link));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return MultiBlocProvider(
      providers: [
        BlocProvider<MatchmakerNotificationsCubit>.value(value: _cubit),
        BlocProvider<MatchmakerNotificationReadCubit>.value(value: _readCubit),
      ],
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        appBar: QeranAppBar(
          title: LocaleKeys.matchmaker_notifications_title.t(context),
        ),
        body: SafeArea(top: false, child: _rows(isArabic)),
      ),
    );
  }

  /// The rows, remembering the newest loaded for the way out.
  Widget _rows(bool isArabic) =>
      BlocListener<
        MatchmakerNotificationsCubit,
        PaginatedListState<MatchmakerNotification>
      >(
        listenWhen: (prev, curr) => prev.items.length != curr.items.length,
        listener: (_, state) => _rememberNewest(state.items),
        child: MatchmakerNotificationsList(isArabic: isArabic, onTap: _onTap),
      );
}
