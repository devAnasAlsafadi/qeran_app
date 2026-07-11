import 'package:flutter/material.dart';

import '../tokens/qeran_colors.dart';
import '../tokens/qeran_radii.dart';
import '../tokens/qeran_spacing.dart';
import '../tokens/qeran_typography.dart';

/// Progress of a single step relative to the current one.
enum QeranStepState { done, current, future }

/// Colour flavour of the *current* step: a normal in-progress step, a
/// successful completion, or a non-success ending (rejected / closed).
/// Ignored for `done` / `future` steps.
enum QeranStepTone { normal, success, ended }

/// One row of a [QeranStepper].
class QeranStepData {
  const QeranStepData({
    required this.label,
    required this.state,
    this.tone = QeranStepTone.normal,
  });

  final String label;
  final QeranStepState state;
  final QeranStepTone tone;
}

/// A vertical progress stepper: N nodes on a start-edge rail joined by
/// connectors, one marked current. Fully data-driven and reusable — the
/// caller decides how backend state projects onto [QeranStepData].
///
/// Orientation is stable across RTL/LTR (the rail always leads the start
/// edge); only the labels mirror. Node system:
///   • done    → gold node + check, gold connector.
///   • current → wine node, gold ring + gold-12 halo, `radio_button_checked`,
///               bold ink-strong label + a "current" pill (normal tone);
///               gold check (success tone) or danger cross (ended tone).
///   • future  → paper node, wine-20 border, wine-12 connector, faint label.
class QeranStepper extends StatelessWidget {
  const QeranStepper({
    super.key,
    required this.steps,
    required this.currentLabel,
  });

  final List<QeranStepData> steps;

  /// Localized "current stage" pill text, shown on the current normal step.
  final String currentLabel;

  static const double _rail = 32;
  static const double _node = 26;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            currentLabel: currentLabel,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isLast,
    required this.currentLabel,
  });

  final QeranStepData step;
  final bool isLast;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    final isCurrentNormal =
        step.state == QeranStepState.current && step.tone == QeranStepTone.normal;
    // Done steps (and a successful current) leave a gold trail behind them.
    final connectorGold = step.state == QeranStepState.done ||
        (step.state == QeranStepState.current &&
            step.tone == QeranStepTone.success);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: QeranStepper._rail,
            child: Column(
              children: [
                _Node(step: step),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: connectorGold
                          ? QeranColors.gold
                          : QeranColors.wine12,
                    ),
                  ),
              ],
            ),
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: isLast ? 0 : QeranSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(step.label, style: _labelStyle(step)),
                  if (isCurrentNormal) ...[
                    QeranSpacing.vs8,
                    _CurrentPill(label: currentLabel),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _labelStyle(QeranStepData step) {
    switch (step.state) {
      case QeranStepState.current:
        final color = step.tone == QeranStepTone.ended
            ? QeranColors.danger
            : QeranColors.inkStrong;
        return QeranTypography.subtitle
            .copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: color);
      case QeranStepState.done:
        return QeranTypography.label.copyWith(color: QeranColors.inkBody);
      case QeranStepState.future:
        return QeranTypography.label.copyWith(color: QeranColors.inkFaint);
    }
  }
}

/// The circular node. Concentric build lets the current node carry a gold
/// ring + a soft gold-12 halo without shifting the rail width.
class _Node extends StatelessWidget {
  const _Node({required this.step});

  final QeranStepData step;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case QeranStepState.done:
        return _disc(QeranColors.gold, Icons.check_rounded, QeranColors.wine);
      case QeranStepState.future:
        return _ring(QeranColors.paper, QeranColors.wine20);
      case QeranStepState.current:
        return switch (step.tone) {
          QeranStepTone.success =>
            _disc(QeranColors.gold, Icons.check_rounded, QeranColors.wine),
          QeranStepTone.ended =>
            _disc(QeranColors.danger, Icons.close_rounded, QeranColors.paper),
          QeranStepTone.normal => _currentDisc(),
        };
    }
  }

  /// Wine node behind a gold ring behind a gold-12 halo — the "you are here".
  Widget _currentDisc() {
    return Container(
      width: QeranStepper._rail,
      height: QeranStepper._rail,
      decoration: const BoxDecoration(
        color: QeranColors.gold12,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: QeranStepper._node,
        height: QeranStepper._node,
        decoration: const BoxDecoration(
          color: QeranColors.wine,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: QeranColors.gold, width: 3),
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.radio_button_checked_rounded,
          size: 12,
          color: QeranColors.paper,
        ),
      ),
    );
  }

  Widget _disc(Color color, IconData icon, Color iconColor) {
    return Container(
      width: QeranStepper._node,
      height: QeranStepper._node,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: iconColor),
    );
  }

  Widget _ring(Color fill, Color border) {
    return Container(
      width: QeranStepper._node,
      height: QeranStepper._node,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
    );
  }
}

class _CurrentPill extends StatelessWidget {
  const _CurrentPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: QeranColors.gold12,
        borderRadius: QeranRadii.pill,
        border: Border.all(color: QeranColors.gold40, width: 1),
      ),
      child: Text(
        label,
        style: QeranTypography.caption.copyWith(
          color: QeranColors.goldDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
