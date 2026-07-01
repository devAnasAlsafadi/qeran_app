import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/usecases/get_notification_count_usecase.dart';

/// App-wide unread-badge source for the matchmaker bell (a lazy singleton, so
/// every `MatchmakerAppBar` and the inbox screen share one instance).
///
/// The backend exposes no read-state, so unread is a LOCAL heuristic:
/// `max(0, currentTotal − lastSeenCount)`, where `lastSeenCount` is the total
/// stored the last time the inbox was opened. State is the unread count.
class MatchmakerNotificationBadgeCubit extends Cubit<int> {
  final GetNotificationCountUseCase _getCount;
  final SharedPrefService _prefs;

  int _total = 0;

  /// Coalesces concurrent count fetches (the `CurrentSubscriptionCubit`
  /// pattern). Without it, a resume (`refresh`) followed immediately by
  /// opening the inbox (`markAllSeen`) fires two `/count` requests back to
  /// back; sharing the in-flight future collapses them into one.
  Future<Either<Failure, int>>? _inflight;

  MatchmakerNotificationBadgeCubit({
    required GetNotificationCountUseCase getCount,
    required SharedPrefService prefs,
  })  : _getCount = getCount,
        _prefs = prefs,
        super(0);

  Future<Either<Failure, int>> _fetchCount() {
    final existing = _inflight;
    if (existing != null) return existing;
    final task = _getCount();
    _inflight = task;
    task.whenComplete(() => _inflight = null);
    return task;
  }

  /// Re-fetches the total and recomputes unread against the stored last-seen.
  /// Silent on failure (the badge just keeps its last value).
  Future<void> refresh() async {
    final result = await _fetchCount();
    await result.fold(
      (_) async {},
      (count) async {
        _total = count;
        final seen =
            await _prefs.get<int>(StorageKeys.matchmakerNotifLastSeenCount) ?? 0;
        if (!isClosed) emit((count - seen).clamp(0, count));
      },
    );
  }

  /// Marks everything seen — stores the current total as the new baseline and
  /// clears the badge. Called when the inbox is opened.
  Future<void> markAllSeen() async {
    final result = await _fetchCount();
    final total = result.fold((_) => _total, (c) => c);
    _total = total;
    await _prefs.save(StorageKeys.matchmakerNotifLastSeenCount, total);
    if (!isClosed) emit(0);
  }
}
