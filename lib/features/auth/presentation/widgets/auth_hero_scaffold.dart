import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';

import 'auth_back_button.dart';

/// The band is a fixed share of the screen, identical on all six auth screens.
/// 0.314 is the exact fraction that allows the 160px lockup to fit in the
/// hero while keeping login at maxScrollExtent == 0 (zero scroll) at 390x820.
const double _kBandFraction = 0.314;

/// Floor for the wine band, measured BELOW the status-bar inset, so the brand
/// survives on a very short viewport.
const double _kMinBandHeight = 100;

/// Height of the pinned chrome row (back chevron / language pill).
const double _kChromeHeight = 48;

/// Lockup is sized FIRST at 160px wide so all three parts (monogram, «قِران», «QERAN») read clearly.
const double _kLockupWidthMin = 100;

/// Shared auth shell: a compact wine band (the gold full logo lockup,
/// flanked by the back / language chrome) over a soft-white dome that
/// carries each screen's form.
///
/// Visual shell ONLY — every screen keeps its own form, blocs, controllers
/// and navigation; this just re-parents them into the hero + dome. The dome
/// scrolls internally so long forms and the on-screen keyboard never overflow.
class AuthHeroScaffold extends StatelessWidget {
  /// The screen's form, stretched in a scrollable column inside the dome.
  final List<Widget> children;

  /// Show the floating back chevron on the hero (mid-flow screens).
  final bool showBack;

  /// Fired by the hero back chevron. Preserves each screen's own back action.
  final VoidCallback? onBack;

  /// Show the language pill on the hero's trailing edge (entry screens).
  final bool showLanguageSwitch;

  const AuthHeroScaffold({
    super.key,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.showLanguageSwitch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.wine,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const hero = _AuthHero();
          final dome = _AuthDome(children: children);
          // The chrome is pinned to the top of its container rather than laid
          // out inside the band, so it sits just under the status bar and stays
          // there no matter how tall the band is on a given screen. Previously
          // it rode with the band, which made the pill and the chevron sit at a
          // different height on login (tall band) than on register (short one).
          final chrome = PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: _HeroChrome(
                showBack: showBack,
                onBack: onBack,
                showLanguageSwitch: showLanguageSwitch,
              ),
            ),
          );
          if (constraints.maxWidth <= constraints.maxHeight) {
            // The status bar sits inside the band (the band owns the SafeArea),
            // so the floor has to reserve it — otherwise it is measured
            // including the inset and the VISIBLE band collapses under it,
            // clipping the motif on exactly the devices with a tall inset.
            final band = math.max(
              constraints.maxHeight * _kBandFraction,
              _kMinBandHeight + MediaQuery.paddingOf(context).top,
            );
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: band, child: hero),
                    Expanded(child: dome),
                  ],
                ),
                chrome,
              ],
            );
          }

          // Landscape keeps the brand visible without sacrificing form height.
          // The form remains independently scrollable for keyboards and larger
          // accessibility text. The chrome is pinned to the top of the BAND
          // here, not the screen: stretched across the full width it would put
          // the language pill on the trailing edge, floating over the form.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.36,
                child: Stack(children: [hero, chrome]),
              ),
              Expanded(child: dome),
            ],
          );
        },
      ),
    );
  }
}

/// The wine band's brand mark: full logo lockup (gold symbol + white «قِران» + gold «QERAN»)
/// centred in the wine band without background circles/rings.
class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final band = constraints.maxHeight;
          final lockupSize = (band * 0.80).clamp(
            _kLockupWidthMin,
            170.0,
          );

          return Center(
            child: Image.asset(
              AppAssets.logoDark,
              width: lockupSize,
              height: lockupSize,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}

/// The chrome row: back chevron on the leading edge, language pill on the
/// trailing edge. Pinned by the scaffold to the top of the SCREEN, under the
/// status bar — not laid out inside the band. The band's height varies by
/// screen (login's form is ~120px shorter than register's, so its band is
/// ~120px taller), and while it rode with the band the pill and the chevron
/// landed at a different height on every screen.
///
/// The monogram is NOT in this row. It used to be, between two [Spacer]s, but
/// the leading slot is 48 wide while the language pill is ~110 — so the
/// Spacers split the remainder evenly and pushed the monogram off centre on
/// login (where the pill shows) while leaving it centred on register (where
/// both slots are 48). The ring motif stayed centred on the band either way,
/// so the two drifted apart. The monogram now sits in the band's Stack,
/// concentric with the rings on every screen.
class _HeroChrome extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLanguageSwitch;

  const _HeroChrome({
    required this.showBack,
    required this.onBack,
    required this.showLanguageSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: QeranSpacing.s20,
        vertical: QeranSpacing.s8,
      ),
      child: SizedBox(
        height: _kChromeHeight,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: showBack
                  ? AuthBackButton(
                      onPressed: onBack ?? () {},
                      color: QeranColors.gold,
                    )
                  : null,
            ),
            const Spacer(),
            if (showLanguageSwitch)
              const LanguageSwitchButton(variant: LanguageSwitchVariant.light)
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// The soft-white dome that surfaces out of the wine hero and carries the
/// screen's form. Scrolls internally so the keyboard never overflows it.
class _AuthDome extends StatelessWidget {
  final List<Widget> children;

  const _AuthDome({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: QeranColors.creamCanvas,
        borderRadius: QeranRadii.domeTop,
        boxShadow: QeranShadows.eLiftUp,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // Tightened for QER-30 (was s32 top / s24 bottom) to buy back
          // vertical room without touching the form's own structure.
          padding: const EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s24,
            QeranSpacing.s24,
            QeranSpacing.s24,
            QeranSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
