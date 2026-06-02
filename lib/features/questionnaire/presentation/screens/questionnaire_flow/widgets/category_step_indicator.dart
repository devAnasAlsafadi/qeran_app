import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'category_progress_calculator.dart';

class CategoryStepIndicator extends StatelessWidget {
  final List<CategoryStep> steps;
  final int currentQuestionIndex;
  final List<QuestionEntity> questions;
  final Map<String, dynamic> answers;

  const CategoryStepIndicator({
    super.key,
    required this.steps,
    required this.currentQuestionIndex,
    required this.questions,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      final status = CategoryProgressCalculator.statusOf(
        steps[i],
        currentQuestionIndex,
      );
      children.add(_StepDot(status: status));
      if (i < steps.length - 1) {
        children.add(
          _StepConnector(
            fillFraction: _fillFractionFor(steps[i], status),
          ),
        );
      }
    }

    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  /// Solid-fill fraction for the connector immediately AFTER [step].
  /// - completed section → fully filled (1.0)
  /// - current section   → answered count / section length
  /// - upcoming section  → 0.0
  double _fillFractionFor(CategoryStep step, CategoryStepStatus status) {
    if (status == CategoryStepStatus.completed) return 1.0;
    if (status == CategoryStepStatus.upcoming) return 0.0;
    final length = step.lastIndex - step.firstIndex + 1;
    if (length <= 0) return 0.0;
    int answered = 0;
    for (int i = step.firstIndex; i <= step.lastIndex; i++) {
      if (answers.containsKey(questions[i].questionId)) answered++;
    }
    return (answered / length).clamp(0.0, 1.0);
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  final CategoryStepStatus status;

  const _StepDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      CategoryStepStatus.completed => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: QeranColors.wine,
        ),
        child: const Icon(Icons.check, size: 14, color: QeranColors.paper),
      ),
      CategoryStepStatus.current => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: QeranColors.creamCanvas,
          border: Border.all(color: QeranColors.wine, width: 2),
        ),
      ),
      CategoryStepStatus.upcoming => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: QeranColors.creamCanvas,
          border: Border.all(color: QeranColors.wine20, width: 2),
        ),
      ),
    };
  }
}

class _StepConnector extends StatelessWidget {
  final double fillFraction;

  const _StepConnector({required this.fillFraction});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: _ProgressConnectorPainter._thickness,
        child: CustomPaint(
          painter: _ProgressConnectorPainter(
            fillFraction: fillFraction.clamp(0.0, 1.0),
            direction: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _ProgressConnectorPainter extends CustomPainter {
  final double fillFraction;
  final TextDirection direction;

  const _ProgressConnectorPainter({
    required this.fillFraction,
    required this.direction,
  });

  static const double _thickness = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final fillEnd = (size.width * fillFraction).clamp(0.0, size.width);

    final railPaint = Paint()
      ..color = QeranColors.wine.withValues(alpha: 0.12)
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), railPaint);

    if (fillEnd > 0) {
      final fillPaint = Paint()
        ..color = QeranColors.wine
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round;
      // RTL: anchor the fill at the trailing edge so the connector grows
      // toward the next (visually leftward) step dot, matching how the
      // Row reverses the step order in Arabic.
      final isRtl = direction == TextDirection.rtl;
      final start = Offset(isRtl ? size.width : 0.0, y);
      final end = Offset(isRtl ? size.width - fillEnd : fillEnd, y);
      canvas.drawLine(start, end, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressConnectorPainter oldDelegate) =>
      oldDelegate.fillFraction != fillFraction ||
      oldDelegate.direction != direction;
}
