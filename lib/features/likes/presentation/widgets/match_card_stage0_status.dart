import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/photo_exchange_pending.dart';

/// What a stage-0 card's status line says and shows, given the photo-exchange
/// block the server sent.
///
/// Lifted out of `MatchCardStage0` when sub-step 5d added the cancel X and the
/// file had no room left under the 200-line cap. The pair moved together
/// because they answer one question between them in the same three branches —
/// splitting the icon from the words it labels is how they drift apart.
///
/// [live] is checked FIRST in both. A lapsed request still arrives as a
/// Pending block with a real `expiresAt`, and reading it as "awaiting a reply"
/// told the member to keep waiting for an answer that could no longer come —
/// the countdown vanished but the copy still said pending. It now says the
/// window closed.
class MatchCardStage0Status {
  const MatchCardStage0Status._();

  static IconData icon(
    PhotoExchangePending? pending, {
    required bool canRespond,
    required bool live,
  }) {
    if (pending != null && !live) return Icons.timer_off_rounded;
    if (pending != null && !canRespond) return Icons.access_time_rounded;
    return Icons.lock_outline_rounded;
  }

  static String text(
    BuildContext context,
    PhotoExchangePending? pending, {
    required bool canRespond,
    required bool live,
  }) {
    if (pending != null && !live) {
      return LocaleKeys.likes_status_expired.t(context);
    }
    if (pending != null && !canRespond) {
      return LocaleKeys.likes_matches_stage_waiting_photos_pending.t(context);
    }
    return LocaleKeys.likes_matches_stage_waiting_photos_title.t(context);
  }
}
