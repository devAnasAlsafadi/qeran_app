import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';

/// Single drum-style picker for weight in kg.
/// Similar to height widget, with "كغ" unit label.
class QuestionWeightWidget extends StatefulWidget {
  final int? selectedWeight;
  final ValueChanged<int> onChanged;

  const QuestionWeightWidget({
    super.key,
    required this.selectedWeight,
    required this.onChanged,
  });

  @override
  State<QuestionWeightWidget> createState() => _QuestionWeightWidgetState();
}

class _QuestionWeightWidgetState extends State<QuestionWeightWidget> {
  static const int _minWeight = 30;
  static const int _maxWeight = 200;
  static const double _itemExtent = 40;

  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedWeight ?? 70;
    _controller = FixedExtentScrollController(
      initialItem: _selected - _minWeight,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(_selected);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * 7,
      child: Stack(
        children: [
          // Center highlight band
          Center(
            child: Container(
              height: _itemExtent,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: _itemExtent,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.35,
            onSelectedItemChanged: (i) {
              _selected = _minWeight + i;
              widget.onChanged(_selected);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _maxWeight - _minWeight + 1,
              builder: (context, index) {
                final value = _minWeight + index;
                final isCenter = value == _selected;
                return Center(
                  child: Text(
                    isCenter ? '$value كغ' : '$value',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: isCenter ? FontWeight.bold : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
