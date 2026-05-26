import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/like_profile_image.dart';
import '../../domain/entities/like_request_card.dart';
import '../../domain/entities/like_request_status.dart';
import 'like_countdown_formatter.dart';

/// One row in the Likes / Interests list.
///
/// Three visual variants share the same shell:
/// * **Locked** — identity redacted; tap-anywhere routes to packages.
/// * **Pending** — name + soft-blurred avatar + gold "waiting" status
///   + live countdown chip; (incoming only) accept / reject buttons.
/// * **Archived** — name + image + muted status pill (accepted /
///   rejected / expired); no actions.
class LikeUserCard extends StatelessWidget {
  final LikeRequestCard card;

  /// Fired when the user taps Accept on an incoming pending row. The
  /// screen wires this to `LikesCubit.acceptLike(card.likeRequestId)`.
  final VoidCallback? onAccept;

  /// Fired when the user taps Reject. Wired to
  /// `LikesCubit.rejectLike(card.likeRequestId)`.
  final VoidCallback? onReject;

  /// Fired when the user taps a locked card / its overlay. The screen
  /// pushes the Packages route.
  final VoidCallback? onUnlock;

  /// Fired when the user taps anywhere on a non-locked row's content
  /// area (avatar / name). The Likes screen wires this to push the
  /// reusable Full Profile Details screen. Null disables the tap.
  final VoidCallback? onOpenProfile;

  /// True while the accept API call is in flight for this row — the
  /// heart button shows a spinner and both circular buttons are
  /// disabled (rapid taps must not stack requests).
  final bool isAccepting;

  /// True while the reject API call is in flight.
  final bool isRejecting;

  const LikeUserCard({
    super.key,
    required this.card,
    this.onAccept,
    this.onReject,
    this.onUnlock,
    this.onOpenProfile,
    this.isAccepting = false,
    this.isRejecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: card.isLocked
          ? _LockedContent(onUnlock: onUnlock)
          : _VisibleContent(
              card: card,
              onAccept: onAccept,
              onReject: onReject,
              onOpenProfile: onOpenProfile,
              isAccepting: isAccepting,
              isRejecting: isRejecting,
            ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.p12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12431C33),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.p16),
        child: child,
      ),
    );
  }
}

class _VisibleContent extends StatelessWidget {
  final LikeRequestCard card;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onOpenProfile;
  final bool isAccepting;
  final bool isRejecting;

  const _VisibleContent({
    required this.card,
    required this.onAccept,
    required this.onReject,
    required this.onOpenProfile,
    required this.isAccepting,
    required this.isRejecting,
  });

  bool get _isPending => card.status == LikeRequestStatus.pending;
  bool get _showActions =>
      _isPending && (card.canAccept || card.canReject);

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.p8),
              _StatusRow(card: card),
              if (_isPending && card.remainingSeconds != null) ...[
                const SizedBox(height: AppDimens.p8),
                _CountdownChip(initialSeconds: card.remainingSeconds!),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimens.p12),
        _Avatar(image: card.profileImage),
      ],
    );
    final headerTappable = onOpenProfile == null
        ? header
        : InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: header,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        headerTappable,
        if (_showActions) ...[
          const SizedBox(height: AppDimens.p16),
          _ActionRow(
            onAccept: onAccept,
            onReject: onReject,
            isAccepting: isAccepting,
            isRejecting: isRejecting,
          ),
        ],
      ],
    );
  }
}

/// Status chip — gold-toned clock for pending (matches Figma "waiting"
/// hue), wine heart for accepted (success in Qeran wears wine/gold,
/// never Material green), muted icons for archived states.
class _StatusRow extends StatelessWidget {
  final LikeRequestCard card;
  const _StatusRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final (icon, key, color) = _statusVisual(card);
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            key.t(context),
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Pending uses a warmer gold/burgundy hue that reads as "waiting"
  // instead of a flat burgundy. `primaryLight` (#E4C094) is the
  // identity's gold accent.
  static const Color _pendingColor = Color(0xFFB18454);

  (IconData, String, Color) _statusVisual(LikeRequestCard card) {
    switch (card.status) {
      case LikeRequestStatus.pending:
        return (
          Icons.access_time_rounded,
          LocaleKeys.likes_status_pending,
          _pendingColor,
        );
      case LikeRequestStatus.accepted:
        return (
          Icons.favorite_rounded,
          LocaleKeys.likes_status_accepted,
          QeranColors.wine,
        );
      case LikeRequestStatus.rejected:
        return (
          Icons.close_rounded,
          LocaleKeys.likes_status_rejected,
          AppColors.textMuted,
        );
      case LikeRequestStatus.expired:
      case LikeRequestStatus.unknown:
        return (
          Icons.hourglass_disabled_rounded,
          LocaleKeys.likes_status_expired,
          AppColors.textMuted,
        );
    }
  }
}

/// Compact chip showing the remaining time on a pending row.
///
/// Owns its own [Timer.periodic] so the countdown ticks live without
/// triggering a parent rebuild — only this `setState` runs. The timer
/// is cancelled in `dispose`. Tick cadence is 30 s, which is precise
/// enough for the d/h/m bucketing in [LikeCountdownFormatter] and
/// cheap enough that even a list full of pending rows is fine.
class _CountdownChip extends StatefulWidget {
  final int initialSeconds;
  const _CountdownChip({required this.initialSeconds});

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  static const Duration _tick = Duration(seconds: 30);

  late int _seconds;
  late DateTime _anchor;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
    _anchor = DateTime.now();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  @override
  void didUpdateWidget(_CountdownChip old) {
    super.didUpdateWidget(old);
    // Cubit refresh emitted a new remaining value — reset the anchor
    // so the next tick subtracts from the freshly-received baseline,
    // not from the stale local one.
    if (widget.initialSeconds != old.initialSeconds) {
      _seconds = widget.initialSeconds;
      _anchor = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final elapsed = DateTime.now().difference(_anchor).inSeconds;
    final next = (widget.initialSeconds - elapsed).clamp(0, 1 << 31);
    if (next == _seconds) return;
    setState(() => _seconds = next);
    if (next == 0) {
      // Local countdown hit zero. We do NOT call any archive endpoint
      // — backend owns the final state. The next refresh will move
      // this row into `archived` with status: Expired.
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFF6EFE5); // soft warm cream
    const Color foreground = Color(0xFFB18454); // gold-burgundy
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            LikeCountdownFormatter.format(context, _seconds),
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isAccepting;
  final bool isRejecting;
  const _ActionRow({
    required this.onAccept,
    required this.onReject,
    required this.isAccepting,
    required this.isRejecting,
  });

  @override
  Widget build(BuildContext context) {
    // While EITHER action is in flight on this row, both buttons are
    // disabled — a second tap on the other button would race the first
    // request, and the cubit-side guard would silently drop it. Keeping
    // both disabled gives the right visual signal too.
    final actionInFlight = isAccepting || isRejecting;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _CircularActionButton(
          onTap: actionInFlight ? null : onAccept,
          icon: Icons.favorite_rounded,
          backgroundColor: QeranColors.gold,
          iconColor: QeranColors.wine,
          hasShadow: true,
          showSpinner: isAccepting,
          tooltipKey: LocaleKeys.likes_action_accept,
        ),
        const SizedBox(width: AppDimens.p12),
        _CircularActionButton(
          onTap: actionInFlight ? null : onReject,
          icon: Icons.close_rounded,
          backgroundColor: QeranColors.creamSurface,
          iconColor: QeranColors.wine,
          hasShadow: false,
          showSpinner: isRejecting,
          tooltipKey: LocaleKeys.likes_action_reject,
        ),
      ],
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final bool hasShadow;
  final bool showSpinner;
  final String tooltipKey;

  const _CircularActionButton({
    required this.onTap,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.hasShadow = false,
    this.showSpinner = false,
    required this.tooltipKey,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltipKey.t(context),
      button: true,
      child: Tooltip(
        message: tooltipKey.t(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: QeranColors.wine.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: showSpinner
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                        ),
                      )
                    : Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final LikeProfileImage? image;
  const _Avatar({required this.image});

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final url = image?.url;
    return ClipOval(
      child: Container(
        width: _size,
        height: _size,
        color: AppColors.primary.withValues(alpha: 0.06),
        child: url == null || url.isEmpty
            ? const Icon(
                Icons.person_rounded,
                size: 36,
                color: AppColors.textMuted,
              )
            : _MaybeBlurredImage(url: url, blur: image?.isBlurred ?? false),
      ),
    );
  }
}

class _MaybeBlurredImage extends StatelessWidget {
  final String url;
  final bool blur;
  const _MaybeBlurredImage({required this.url, required this.blur});

  // Soft blur — strong enough to obscure facial features without
  // wiping the image into a uniform gray disc. The Figma reference
  // shows a recognisable silhouette + colour mood; 6 sigma matches.
  static const double _sigma = 6.0;

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person_rounded,
        size: 36,
        color: AppColors.textMuted,
      ),
    );
    if (!blur) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: _sigma, sigmaY: _sigma),
      child: image,
    );
  }
}

/// Locked variant — identity redacted on the server. Whole card is a
/// tap target that routes to the Packages screen.
class _LockedContent extends StatelessWidget {
  final VoidCallback? onUnlock;
  const _LockedContent({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUnlock,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.likes_locked_card_title.t(context),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p8),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          LocaleKeys.likes_locked_card_subtitle.t(context),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.p12),
            ClipOval(
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.primary.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
