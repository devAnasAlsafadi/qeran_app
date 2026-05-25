import 'package:flutter/material.dart';

import '../tokens/qeran_motion.dart';
import 'soft_scale_in.dart';

/// Reveals children one after another with a fixed inter-child delay.
/// Use for lists/grids of >4 items, chip wraps, settings rows.
///
/// Pure layout — wraps each child in a [SoftScaleIn] with a staggered
/// delay. No business logic, no list virtualization (callers using
/// `ListView.builder` should apply per-item entry there instead).
class StaggeredChildren extends StatelessWidget {
  const StaggeredChildren({
    super.key,
    required this.children,
    this.axis = Axis.vertical,
    this.step = QeranMotion.staggerStep,
    this.itemDuration = QeranMotion.standard,
    this.curve = QeranCurves.standard,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Axis axis;
  final Duration step;
  final Duration itemDuration;
  final Curve curve;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    final wrapped = <Widget>[
      for (var i = 0; i < children.length; i++)
        SoftScaleIn(
          duration: itemDuration,
          curve: curve,
          delay: step * i,
          child: children[i],
        ),
    ];

    return axis == Axis.vertical
        ? Column(
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: wrapped,
          )
        : Row(
            mainAxisSize: mainAxisSize,
            children: wrapped,
          );
  }
}
