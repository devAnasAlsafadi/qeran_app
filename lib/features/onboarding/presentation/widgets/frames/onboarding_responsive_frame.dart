import 'package:flutter/material.dart';

/// Keeps onboarding's portrait composition intact and switches to a two-pane
/// layout when width dominates height.
///
/// The content pane scrolls independently in landscape so translated copy,
/// accessibility text scaling, and short devices can never overflow.
class OnboardingResponsiveFrame extends StatelessWidget {
  const OnboardingResponsiveFrame({
    super.key,
    required this.hero,
    required this.panel,
    this.heroFlex = 10,
    this.panelFlex = 11,
  });

  final Widget hero;
  final Widget panel;
  final int heroFlex;
  final int panelFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (!isLandscape) {
          return Column(
            children: [
              Expanded(child: hero),
              panel,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: heroFlex, child: hero),
            Expanded(
              flex: panelFlex,
              child: LayoutBuilder(
                builder: (context, panelConstraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: panelConstraints.maxHeight,
                      ),
                      child: panel,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
