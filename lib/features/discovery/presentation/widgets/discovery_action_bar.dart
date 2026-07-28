import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Colour palette for a single action button. Decouples the visual
/// identity (background and icon) from the behavioural
/// flags (`filled`, `overshoot`, `showHalo`, `idlePulse`) so each of the
/// three buttons can have its own premium tone without forking the
/// internal state class.
@immutable
class _ActionButtonPalette {
  final Color background;
  final Color disabledBackground;
  final Color iconColor;
  final Color disabledIconColor;

  const _ActionButtonPalette({
    required this.background,
    required this.disabledBackground,
    required this.iconColor,
    required this.disabledIconColor,
  });
}

// Skip and undo — one shared quiet paper surface with no outline. They are a
// matched pair of plain circles; the glyph, not the colour, is what tells them
// apart. Undo used to be cream and a size smaller, which read as a third,
// weaker tier rather than a sibling of skip.
const _ActionButtonPalette _kSecondaryPalette = _ActionButtonPalette(
  background: QeranColors.paper,
  disabledBackground: QeranColors.paper,
  iconColor: QeranColors.wine,
  disabledIconColor: QeranColors.wine40,
);

/// Diameter shared by skip and undo. Equal circles: neither action outranks
/// the other, and only the like CTA is allowed to be bigger.
const double _kSecondarySize = 56;
const double _kSecondaryIconSize = 26;

// Like — wine-filled primary CTA with a gold heart icon. Pure weightless CTA.
const _ActionButtonPalette _kLikePalette = _ActionButtonPalette(
  background: QeranColors.wine,
  disabledBackground: QeranColors.wine40,
  iconColor: QeranColors.gold,
  disabledIconColor: QeranColors.gold40,
);

/// Three-button action bar under the Discovery card.
///
/// Children are declared like (wine-filled primary, 72) → undo → pass, the
/// last two a matched pair of 56dp paper circles told apart by their glyph
/// alone (rewind vs dismiss). The Row mirrors automatically by locale via
/// natural Directionality (no manual flip / textDirection override): LTR
/// renders like (leading) … undo · pass (trailing); RTL mirrors it so
/// pass · undo … like reads right-to-left.
///
/// Each button owns its own `AnimationController` for press feedback
/// and is fully independent — a press on one button never affects the
/// visual of the others, and the deck animator's `isAnimating` flag
/// does NOT gate enable state here (the caller's `onLike`/`onPass`/
/// `onUndo` closures may internally bail when the deck is mid-animation,
/// but the buttons stay visually enabled to avoid the synchronized
/// color flash that was misread as "all three buttons animating
/// together").
class DiscoveryActionBar extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onUndo;
  final VoidCallback? onLike;

  /// Optional — invoked on an ENABLED Like tap with the button's
  /// screen-space center. Used by the surrounding view to spawn a
  /// flying-heart overlay that visually connects the button to the
  /// card's like overlay.
  final void Function(Offset origin)? onLikeBurst;

  const DiscoveryActionBar({
    super.key,
    required this.onPass,
    required this.onUndo,
    required this.onLike,
    this.onLikeBurst,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PressableActionButton(
          // The heart is the app's own like glyph — it is what the like
          // overlay, the likes tab and the paywall all use, so the button has
          // to match them. Wine circle, gold heart.
          icon: Icons.favorite_rounded,
          size: 72,
          iconSize: 34,
          tooltip: LocaleKeys.discovery_action_like_label.t(context),
          onPressed: onLike,
          filled: true,
          overshoot: true,
          showHalo: true,
          idlePulse: true,
          onTapOrigin: onLikeBurst,
          palette: _kLikePalette,
        ),
        const Spacer(),
        _PressableActionButton(
          // Rewind — a circular arrow, distinct at a glance from the skip X
          // now that the two circles are the same size and colour.
          icon: Icons.replay_rounded,
          size: _kSecondarySize,
          iconSize: _kSecondaryIconSize,
          tooltip: LocaleKeys.discovery_action_undo_label.t(context),
          onPressed: onUndo,
          rewindRotate: true,
          palette: _kSecondaryPalette,
        ),
        const SizedBox(width: QeranSpacing.s16),
        _PressableActionButton(
          // Dismiss.
          icon: Icons.close_rounded,
          size: _kSecondarySize,
          iconSize: _kSecondaryIconSize,
          tooltip: LocaleKeys.discovery_action_pass_label.t(context),
          onPressed: onPass,
          palette: _kSecondaryPalette,
        ),
      ],
    );
  }
}

/// Internal pressable button — handles scale press-down / release with
/// optional overshoot (Like) and a small counter-clockwise rotation
/// (Undo).
///
/// Each instance owns its own `AnimationController`. A press on one
/// button cannot move or rebuild the others.
class _PressableActionButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Filled primary CTA vs secondary surface. Drives elevation defaults.
  final bool filled;

  /// Tiny overshoot above 1.0 on release. Used for Like to give the
  /// primary CTA a touch of bounce.
  final bool overshoot;

  /// Adds a small counter-clockwise rotation during press. Used for
  /// Undo as a subtle "rewind" cue.
  final bool rewindRotate;

  /// When true, an enabled tap fires a one-shot gold halo ring behind
  /// the button. Used for the Like primary CTA only.
  final bool showHalo;

  /// Optional — when true, the button subtly pulses (scale/elevation/glow)
  /// while idle to attract attention.
  final bool idlePulse;

  /// Optional — invoked on an enabled tap with the button's
  /// screen-space center. Used by the Like button to seed a flying-
  /// heart overlay.
  final void Function(Offset origin)? onTapOrigin;

  /// Visual identity (background and icon). Decoupled
  /// from [filled] so each of the three brand tones (paper-with-wine,
  /// cream-lifted, gold-filled) can be applied without forking the
  /// state class.
  final _ActionButtonPalette palette;

  const _PressableActionButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.tooltip,
    required this.onPressed,
    required this.palette,
    this.filled = false,
    this.overshoot = false,
    this.rewindRotate = false,
    this.showHalo = false,
    this.idlePulse = false,
    this.onTapOrigin,
  });

  @override
  State<_PressableActionButton> createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton>
    with TickerProviderStateMixin {
  static const double _pressScale = 0.91;
  static const double _overshootPeak = 1.07;
  static const double _undoRotation = -0.18; // radians (~10°)

  /// Short, transform-only halo feedback aligned with the flying heart.
  static const Duration _haloDuration = Duration(milliseconds: 480);

  late final AnimationController _ctrl = AnimationController(vsync: this);

  /// Halo controller — only created when [widget.showHalo] is true.
  /// Pass / Undo don't pay for a second ticker.
  AnimationController? _haloCtrl;

  Animation<double> _scale = const AlwaysStoppedAnimation(1.0);
  Animation<double> _rotation = const AlwaysStoppedAnimation(0.0);
  Animation<double> _iconScale = const AlwaysStoppedAnimation(1.0);
  Animation<double> _elevationAnim = const AlwaysStoppedAnimation(0.0);
  Animation<double> _internalGlowOpacity = const AlwaysStoppedAnimation(0.0);

  AnimationController? _idleCtrl;
  Timer? _idleTimer;

  late final Animation<double> _idleScale;
  late final Animation<double> _idleElevation;
  late final Animation<double> _idleGlowOpacity;
  late final Animation<double> _idleOuterScale;
  late final Animation<double> _idleOuterOpacity;

  @override
  void initState() {
    super.initState();
    _elevationAnim = AlwaysStoppedAnimation(widget.filled ? 4.0 : 1.0);
    if (widget.showHalo) {
      _haloCtrl = AnimationController(vsync: this, duration: _haloDuration);
    }

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _scheduleNextIdlePulse(isInitial: false);
      }
    });

    if (widget.idlePulse) {
      _idleCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      // Idle pulse magnitude lowered (scale 1.035, glow 0.18, elevation 6)
      // to stop the Like CTA from competing with the gold bottom-nav disc
      // sitting in the same vertical column on the Discovery tab.
      _idleScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 1.035,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.035,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
      ]).animate(_idleCtrl!);
      _idleElevation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 4.0,
            end: 6.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 6.0,
            end: 4.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
      ]).animate(_idleCtrl!);
      _idleGlowOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 0.18,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.18,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
      ]).animate(_idleCtrl!);
      _idleOuterScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 1.18,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.18,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
      ]).animate(_idleCtrl!);
      _idleOuterOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1,
        ),
      ]).animate(_idleCtrl!);

      if (_enabled) {
        _scheduleNextIdlePulse(isInitial: true);
      }
    }
  }

  @override
  void didUpdateWidget(_PressableActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEnabled = oldWidget.onPressed != null;
    if (!_enabled && wasEnabled) {
      _idleCtrl?.stop();
      _idleTimer?.cancel();
    } else if (_enabled && !wasEnabled) {
      _scheduleNextIdlePulse(isInitial: true);
    }
  }

  void _scheduleNextIdlePulse({bool isInitial = false}) {
    _idleTimer?.cancel();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _idleCtrl?.dispose();
    _haloCtrl?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  /// See `discovery_deck_animation_controller.reset` doc for the same
  /// pattern: forward() must not fire synchronously during a parent's
  /// dispose (the InkWell's gesture recognizer cancels from inside its
  /// own dispose, which would notify our AnimatedBuilder while the
  /// framework tree is locked).
  void _scheduleAnimation(void Function() run) {
    if (!_enabled) return;
    scheduleMicrotask(() {
      if (!mounted || !_enabled) return;
      run();
    });
  }

  void _animatePressDown() => _scheduleAnimation(_doPressDown);
  void _animateRelease() => _scheduleAnimation(_doRelease);

  void _doPressDown() {
    _idleCtrl?.stop();
    _idleTimer?.cancel();
    _ctrl.stop();
    _scale = Tween<double>(
      begin: _scale.value,
      end: _pressScale,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
    if (widget.rewindRotate) {
      _rotation = Tween<double>(
        begin: _rotation.value,
        end: _undoRotation,
      ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
    }
    if (widget.overshoot) {
      _elevationAnim = Tween<double>(
        begin: _elevationAnim.value,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
    }
    _ctrl.duration = const Duration(milliseconds: 80);
    _ctrl.forward(from: 0);
  }

  void _doRelease() {
    _ctrl.stop();
    final fromScale = _scale.value;
    if (widget.overshoot) {
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: fromScale,
            end: _overshootPeak,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: _overshootPeak,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(_ctrl);

      final fromIconScale = _iconScale.value;
      _iconScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: fromIconScale,
            end: 1.25,
          ).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.25,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(_ctrl);

      final fromElev = _elevationAnim.value;
      _elevationAnim = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: fromElev,
            end: 7.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 7.0,
            end: 4.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(_ctrl);

      final fromGlow = _internalGlowOpacity.value;
      _internalGlowOpacity = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: fromGlow,
            end: 0.45,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.45,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 2, // Fades out slightly slower
        ),
      ]).animate(_ctrl);

      _ctrl.duration = const Duration(milliseconds: 300);
    } else {
      _scale = Tween<double>(
        begin: fromScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)).animate(_ctrl);
      _ctrl.duration = const Duration(milliseconds: 140);
    }
    if (widget.rewindRotate) {
      _rotation = Tween<double>(
        begin: _rotation.value,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl);
    }
    _ctrl.forward(from: 0);
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    // Fire the halo BEFORE the cubit action so the visual ramp starts
    // right at the tap. If a halo is already mid-flight, restart it
    // — premium feedback for rapid taps without stacking visuals.
    _haloCtrl?.forward(from: 0);
    final origin = _computeGlobalCenter();
    if (origin != null) widget.onTapOrigin?.call(origin);
    widget.onPressed!();
  }

  Offset? _computeGlobalCenter() {
    if (widget.onTapOrigin == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_enabled;
    final palette = widget.palette;
    final iconColor = disabled ? palette.disabledIconColor : palette.iconColor;
    final bgColor = disabled ? palette.disabledBackground : palette.background;
    const shape = CircleBorder();

    final button = Tooltip(
      message: widget.tooltip,
      child: AnimatedBuilder(
        animation: _idleCtrl != null
            ? Listenable.merge([_ctrl, _idleCtrl!])
            : _ctrl,
        builder: (context, child) {
          final isTapAnimActive =
              _ctrl.isAnimating || (_scale.value - 1.0).abs() > 0.0005;
          final isIdleAnimActive = _idleCtrl?.isAnimating ?? false;

          final scaleVal = isTapAnimActive
              ? _scale.value
              : (isIdleAnimActive ? _idleScale.value : 1.0);
          final rotVal = _rotation.value;

          final currentElevation = widget.filled
              ? (isTapAnimActive && widget.overshoot
                    ? _elevationAnim.value
                    : (isIdleAnimActive ? _idleElevation.value : 4.0))
              : 1.0;

          final iconScaleVal = widget.overshoot ? _iconScale.value : 1.0;
          final glowOp = widget.overshoot
              ? (isTapAnimActive
                    ? _internalGlowOpacity.value
                    : (isIdleAnimActive ? _idleGlowOpacity.value : 0.0))
              : 0.0;

          Widget content = Icon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          );

          if (widget.overshoot) {
            content = Stack(
              alignment: Alignment.center,
              children: [
                if (glowOp > 0.005)
                  IgnorePointer(
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            QeranColors.gold.withValues(alpha: glowOp),
                            QeranColors.gold.withValues(alpha: 0.0),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                if ((iconScaleVal - 1.0).abs() > 0.0005)
                  Transform.scale(scale: iconScaleVal, child: content)
                else
                  content,
              ],
            );
          }

          final mat = Material(
            color: bgColor,
            shape: shape,
            elevation: currentElevation,
            shadowColor: QeranColors.wine.withValues(alpha: 0.18),
            child: InkWell(
              onTap: _enabled ? _handleTap : null,
              onTapDown: _enabled ? (_) => _animatePressDown() : null,
              onTapUp: _enabled ? (_) => _animateRelease() : null,
              onTapCancel: _enabled ? _animateRelease : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Center(child: content),
              ),
            ),
          );

          final animatedMat = Transform.scale(
            scale: scaleVal,
            child: Transform.rotate(angle: rotVal, child: mat),
          );

          if (widget.idlePulse && isIdleAnimActive) {
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_idleOuterOpacity.value > 0.005)
                  Transform.scale(
                    scale: _idleOuterScale.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: QeranColors.wine.withValues(
                              alpha: _idleOuterOpacity.value * 0.25,
                            ),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: QeranColors.wine.withValues(
                              alpha: _idleOuterOpacity.value * 0.35,
                            ),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                animatedMat,
              ],
            );
          }

          final isIdle =
              (scaleVal - 1.0).abs() < 0.0005 && rotVal.abs() < 0.0005;
          if (isIdle) return mat;

          return animatedMat;
        },
      ),
    );

    // Like wraps the button in a Stack with the expanding halo ring
    // behind it. The Stack's layout size is determined by the button
    // (Material is 64×64 for Like); `Clip.none` lets the halo extend
    // ~15 px past the button bounds without clipping.
    if (_haloCtrl == null) return button;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _HaloRing(controller: _haloCtrl!, diameter: widget.size),
        button,
      ],
    );
  }
}

/// Premium wine halo that expands once per Like tap. Renders behind the
/// button (Z-stacked) and is `IgnorePointer` so it never blocks touches.
/// A thin wine ring matches the filled Like CTA without animating expensive
/// blurred shadows on every raster frame.
///
/// Design notes:
/// * Scale starts at 1.2× so the ring is immediately visible as an
///   8 dp border around the 64 dp button on the very first frame (not
///   hidden behind it at 1.0×). Peak is 2.05× (unchanged).
class _HaloRing extends StatelessWidget {
  final AnimationController controller;
  final double diameter;

  const _HaloRing({required this.controller, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          // Eased so the ring expands quickly then settles.
          final eased = Curves.easeOutCubic.transform(t);
          // Starts at 1.2× (immediately a visible ring around the
          // button) and expands to 2.05× (same peak as before).
          final scale = 1.2 + 0.85 * eased;
          final remaining = (1.0 - t).clamp(0.0, 1.0);
          return Opacity(
            opacity: remaining * 0.58,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: QeranColors.wine12,
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
