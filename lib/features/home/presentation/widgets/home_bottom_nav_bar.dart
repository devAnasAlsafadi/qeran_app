import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/generated/locale_keys.g.dart';

// ── Design constants ──────────────────────────────────────────────────────────
const double _kRadius = 34.0;   // pill container corner radius
const double _kHMargin = 20.0;  // horizontal distance from screen edges
const double _kBMargin = 12.0;  // gap between pill bottom and SafeArea edge
const double _kVPad = 10.0;     // pill container top/bottom padding
const double _kHInnerPad = 8.0; // pill container horizontal padding
const double _kIndicatorInset = 4.0; // gap between the sliding pill and its tab cell edge
const Duration _kDur = Duration(milliseconds: 250);
const Duration _kSlideDur = Duration(milliseconds: 320);
const Curve _kCurve = Curves.easeOutCubic;

/// Premium floating-pill bottom navigation bar for the Qeran home shell.
///
/// A single burgundy-tinted pill slides smoothly from the previous active
/// tab to the new one (320 ms easeOutCubic) instead of cross-fading
/// per-tab backgrounds — feels like a soft settling movement, RTL-safe
/// via `AnimatedPositionedDirectional`. The icon scale (1.0 → 1.10) and
/// label colour transitions stay per-tab so the active item still reads
/// distinctly.
class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.diamond_outlined, Icons.diamond,
          LocaleKeys.home_nav_marriage.t(context)),
      _NavItem(Icons.favorite_border, Icons.favorite,
          LocaleKeys.home_nav_likes.t(context)),
      _NavItem(Icons.chat_bubble_outline, Icons.chat_bubble,
          LocaleKeys.home_nav_messages.t(context)),
      _NavItem(Icons.person_outline, Icons.person,
          LocaleKeys.home_nav_profile.t(context)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _kHMargin, 0, _kHMargin, _kBMargin,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.all(Radius.circular(_kRadius)),
            boxShadow: [
              // Warm primary tint — gives depth without looking generic.
              BoxShadow(
                color: Color(0x12431C33), // primary @ ~7 %
                blurRadius: 28,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x08000000), // black @ ~3 %
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kHInnerPad,
              vertical: _kVPad,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: _kSlideDur,
                      curve: _kCurve,
                      start: currentIndex * tabWidth + _kIndicatorInset,
                      top: 0,
                      bottom: 0,
                      width: tabWidth - _kIndicatorInset * 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        items.length,
                        (i) => Expanded(
                          child: _NavButton(
                            item: items[i],
                            isActive: i == currentIndex,
                            onTap: () => onTabSelected(i),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

/// Per-tab contents — icon + label with a synchronised scale + colour
/// transition. The active pill itself is rendered by the parent's
/// `AnimatedPositionedDirectional`, so this widget intentionally has no
/// background of its own.
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  static const Color _active = AppColors.primary;
  static const Color _inactive = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Single TweenAnimationBuilder drives both scale (1.0→1.10)
            // and icon colour (inactive→active) in sync.
            TweenAnimationBuilder<double>(
              tween: Tween(end: isActive ? 1.0 : 0.0),
              duration: _kDur,
              curve: _kCurve,
              builder: (_, t, _) => Transform.scale(
                scale: 1.0 + 0.10 * t,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: Color.lerp(_inactive, _active, t),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: _kDur,
              curve: _kCurve,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? _active : _inactive,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
