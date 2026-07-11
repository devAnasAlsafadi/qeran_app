import 'package:flutter/material.dart';

import '../../../../core/design_system/effects/ring_motif.dart';
import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';

/// The account-screen hero — a wine-gradient panel (`wineLight → wine`,
/// [QeranShadows.eHero], [QeranRadii.panelR]) with a quiet [RingMotif] behind
/// the content. Shared by both roles; the role difference is expressed purely
/// through the optional slots:
///
/// - **matchmaker** → passes [email] (a numeric-LTR line under the name).
/// - **user** → passes [completionLabel] and/or [verified] — but only when a
///   real backend flag backs them. They are hidden while null/false so the
///   hero never fabricates a verified/complete state (the flag isn't wired
///   yet; see HANDOFF).
///
/// [avatar] is a slot (each role supplies its own photo-or-monogram widget,
/// sized ~64) so the JWT-headered matchmaker avatar and the session-photo user
/// avatar both fit without the hero knowing their source.
class SettingsProfileHero extends StatelessWidget {
  const SettingsProfileHero({
    super.key,
    required this.avatar,
    required this.name,
    required this.editLabel,
    required this.onEdit,
    this.email,
    this.completionLabel,
    this.verified = false,
  });

  final Widget avatar;
  final String name;
  final String editLabel;
  final VoidCallback onEdit;

  /// Matchmaker: the account email, rendered LTR tabular under the name.
  final String? email;

  /// User: "profile complete" line (gold check + label). Hidden when null —
  /// gate on the real backend flag, never hardcode.
  final String? completionLabel;

  /// User: the gold "موثّق" verified badge. Hidden when false — gate on the
  /// real backend flag, never hardcode.
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.eHero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.panelR,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -64,
              end: -64,
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.13,
                size: 168,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(QeranSpacing.s20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  QeranSpacing.hs16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: QeranTypography.headline.copyWith(
                            color: QeranColors.paper,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email != null && email!.isNotEmpty) ...[
                          QeranSpacing.vs4,
                          Text(
                            email!,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.start,
                            style: QeranTypography.numeric.copyWith(
                              fontSize: 13,
                              color: QeranColors.paper.withValues(alpha: 0.82),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (completionLabel != null) ...[
                          QeranSpacing.vs4,
                          _CompletionLine(label: completionLabel!),
                        ],
                        QeranSpacing.vs8,
                        _EditLink(label: editLabel, onTap: onEdit),
                      ],
                    ),
                  ),
                  if (verified) ...[
                    QeranSpacing.hs8,
                    const _VerifiedBadge(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold check + "profile complete" label, on the wine hero.
class _CompletionLine extends StatelessWidget {
  const _CompletionLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 14,
          color: QeranColors.gold,
        ),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            label,
            style: QeranTypography.bodySm.copyWith(color: QeranColors.gold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The gold "موثّق" verified pill — gold-18 fill, gold glyph + label.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        color: QeranColors.gold18,
        borderRadius: QeranRadii.pill,
      ),
      child: const Icon(
        Icons.verified_rounded,
        size: 16,
        color: QeranColors.gold,
      ),
    );
  }
}

/// Gold pencil + label link, on the wine hero.
class _EditLink extends StatelessWidget {
  const _EditLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.xsR,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 14, color: QeranColors.gold),
              QeranSpacing.hs4,
              Flexible(
                child: Text(
                  label,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
