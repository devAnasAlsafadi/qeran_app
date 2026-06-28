import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Single drum-style picker for height in cm.
/// Matches Figma: center-highlighted row with "سم" unit label.
class QuestionHeightWidget extends StatefulWidget {
  final int? selectedHeight;
  final ValueChanged<int> onChanged;

  const QuestionHeightWidget({
    super.key,
    required this.selectedHeight,
    required this.onChanged,
  });

  @override
  State<QuestionHeightWidget> createState() => _QuestionHeightWidgetState();
}

class _QuestionHeightWidgetState extends State<QuestionHeightWidget> {
  static const int _minHeight = 100;
  static const int _maxHeight = 220;
  static const double _itemExtent = 40;

  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedHeight ?? 150;
    _controller = FixedExtentScrollController(
      initialItem: _selected - _minHeight,
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
                  horizontal: BorderSide(color: QeranColors.hairline, width: 1),
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
              _selected = _minHeight + i;
              widget.onChanged(_selected);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _maxHeight - _minHeight + 1,
              builder: (context, index) {
                final value = _minHeight + index;
                final isCenter = value == _selected;
                return Center(
                  child: Text(
                    isCenter ? '$value ${LocaleKeys.questionnaire_height_unit.t(context)}' : '$value',
                    style: QeranTypography.subtitle.copyWith(
                      color: QeranColors.inkStrong,
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
