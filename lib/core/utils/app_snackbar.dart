import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qeran/core/di/injection_container.dart';
import '../enum/snakebar_tybe.dart';
import 'widgets/qeran_snack_bar_widget.dart';

class AppSnackBar {
  /// Hold time before auto-dismiss (matches the in/out animation timing).
  static const Duration _holdDuration = Duration(seconds: 3);

  // Single-toast state (max 1 visible + dedup). Only one toast lives at a
  // time regardless of which [OverlayState] hosts it (`show`/`showOnRoot` may
  // resolve different overlays), so this is the single source of truth and
  // every removal is guarded by `.mounted`.
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;
  static String? _currentSignature;

  /// (Re)starts the auto-dismiss timer for [entry]; on fire it dismisses it.
  static void _startTimer(OverlayEntry entry) {
    _currentTimer?.cancel();
    _currentTimer = Timer(_holdDuration, () => _dismissIfCurrent(entry));
  }

  /// Removes [entry] (guarded) and clears tracked state â€” but only if [entry]
  /// is still the live one (a newer toast may have replaced it meanwhile).
  static void _dismissIfCurrent(OverlayEntry entry) {
    if (entry.mounted) entry.remove();
    if (identical(_currentEntry, entry)) {
      _currentTimer?.cancel();
      _currentTimer = null;
      _currentEntry = null;
      _currentSignature = null;
    }
  }

  /// Show a snackbar. [overlay] defaults to `Overlay.of(context)`; pass it
  /// explicitly to bind to a specific [OverlayState] (e.g. the root overlay
  /// so the entry survives a route pop). Max 1 visible: identical back-to-back
  /// calls reset the timer (dedup); a different one replaces the live toast.
  static Future<void> show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    String? title,
    OverlayState? overlay,
  }) async {
    final signature = '$message|$type';

    // Dedup: same content already on screen â†’ just restart its hold timer.
    final current = _currentEntry;
    if (_currentSignature == signature && current != null && current.mounted) {
      _startTimer(current);
      return;
    }

    // Replace: drop any live toast before inserting the new one.
    if (current != null) _dismissIfCurrent(current);

    final overlayToUse = overlay ?? Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => PositionedDirectional(
        top: MediaQuery.of(context).padding.top + 20,
        start: 20,
        end: 20,
        child: Material(
          color: Colors.transparent,
          child: QeranSnackBarWidget(
            message: message,
            title: title,
            type: type,
            onDismiss: () => _dismissIfCurrent(overlayEntry),
          ),
        ),
      ),
    );

    overlayToUse.insert(overlayEntry);
    _currentEntry = overlayEntry;
    _currentSignature = signature;
    _startTimer(overlayEntry);
  }

  /// Shows a snackbar that survives a route pop (e.g. fired by a listener
  /// about to pop its own screen). Resolves the root navigator's
  /// [OverlayState] via `NavigatorState.overlay` â€” `navigatorKey.currentContext`
  /// sits ABOVE the Overlay, so `Overlay.of(...)` can't find one upward.
  static Future<void> showOnRoot({
    required String message,
    required SnackBarType type,
    String? title,
  }) async {
    final navState = sl<GlobalKey<NavigatorState>>().currentState;
    final overlayState = navState?.overlay;
    if (overlayState == null) return;
    // The overlay's own context lives inside the overlay subtree (lookups OK).
    return show(
      overlayState.context,
      message: message,
      type: type,
      title: title,
      overlay: overlayState,
    );
  }
}
