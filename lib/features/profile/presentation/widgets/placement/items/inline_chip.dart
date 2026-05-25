import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';

/// Compact wine chip used by multi-value placement answers
/// (languages, traits, options). Backed by [QeranChip.inside].
class InlineChip extends StatelessWidget {
  final String label;
  const InlineChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return QeranChip(
      label: label,
      variant: QeranChipVariant.inside,
      compact: true,
    );
  }
}
