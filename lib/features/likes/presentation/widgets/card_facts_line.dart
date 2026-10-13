import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Country of residence, job and age under a member's name on an Interests
/// card — Sent, Received and Mutual — in the client's order (run 7, item 5).
/// Each shows only when the row carries it; the server decides what arrives
/// (TQ16).
class CardFactsLine extends StatelessWidget {
  const CardFactsLine({super.key, this.age, this.residence, this.job});

  final int? age;
  final String? residence;
  final String? job;

  /// Nothing to show: the card leaves the line, and its gap, out.
  bool get isEmpty =>
      age == null && (residence?.isEmpty ?? true) && (job?.isEmpty ?? true);

  @override
  Widget build(BuildContext context) {
    final facts = <({IconData icon, String text})>[
      if (residence?.isNotEmpty == true)
        (icon: Icons.location_on_outlined, text: residence!),
      if (job?.isNotEmpty == true)
        (icon: Icons.work_outline_rounded, text: job!),
      if (age != null)
        (
          icon: Icons.cake_outlined,
          text: LocaleKeys.matchmaker_users_age_years.t(
            context,
            namedArgs: {'age': '$age'},
          ),
        ),
    ];
    return Wrap(
      spacing: QeranSpacing.s12,
      runSpacing: QeranSpacing.s4,
      children: [for (final fact in facts) _Fact(fact.icon, fact.text)],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: QeranColors.inkMuted),
        QeranSpacing.hs4,
        Flexible(
          child: Text(
            text,
            style: QeranTypography.caption.copyWith(color: QeranColors.inkBody),
          ),
        ),
      ],
    );
  }
}
