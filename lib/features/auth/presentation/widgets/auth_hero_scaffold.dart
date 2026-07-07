import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';

import 'auth_back_button.dart';
import 'auth_wordmark.dart';

/// Shared auth shell: a wine hero (ring motif + brand wordmark, with
/// optional floating back / language chrome) over a soft-white dome that
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
      body: Column(
        children: [
          _AuthHero(
            showBack: showBack,
            onBack: onBack,
            showLanguageSwitch: showLanguageSwitch,
          ),
          Expanded(child: _AuthDome(children: children)),
        ],
      ),
    );
  }
}

/// The wine hero band: a centred brand wordmark over a quiet ring motif,
/// with an optional chrome row (back / language) pinned to the top.
class _AuthHero extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLanguageSwitch;

  const _AuthHero({
    required this.showBack,
    required this.onBack,
    required this.showLanguageSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const Positioned(
            top: -70,
            left: 0,
            right: 0,
            child: Center(
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.10,
                size: 300,
                ringCount: 3,
                spacing: 22,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              QeranSpacing.s20,
              QeranSpacing.s8,
              QeranSpacing.s20,
              QeranSpacing.s32,
            ),
            child: Column(
              children: [
                _HeroChrome(
                  showBack: showBack,
                  onBack: onBack,
                  showLanguageSwitch: showLanguageSwitch,
                ),
                QeranSpacing.vs16,
                const AuthWordmark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero's top row: back chevron on the leading edge, language pill on
/// the trailing edge. Empty slots reserve width so the wordmark stays centred.
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
    return SizedBox(
      height: 48,
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
          padding: const EdgeInsetsDirectional.fromSTEB(
            QeranSpacing.s24,
            QeranSpacing.s32,
            QeranSpacing.s24,
            QeranSpacing.s24,
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
