import 'package:flutter/material.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';

/// Drum-style date picker with three scroll wheels (day, month, year).
/// Matches the Figma reference with center-highlighted row.
class QuestionDateWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onChanged;

  const QuestionDateWidget({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  State<QuestionDateWidget> createState() => _QuestionDateWidgetState();
}

class _QuestionDateWidgetState extends State<QuestionDateWidget> {
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;

  static const int _minYear = 1950;
  static const int _maxYear = 2010;
  static const double _itemExtent = 44;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? DateTime(1996, 2, 15);
    _selectedDay = initial.day;
    _selectedMonth = initial.month;
    _selectedYear = initial.year;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedYear - _minYear);

    // Emit initial value so the question has an answer from the start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitDate();
    });
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _emitDate() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > daysInMonth) _selectedDay = daysInMonth;
    widget.onChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _itemExtent * 5,
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
          Row(
            children: [
              // Day wheel
              Expanded(child: _buildWheel(
                controller: _dayController,
                itemCount: 31,
                labelBuilder: (i) => '${i + 1}',
                onChanged: (i) {
                  _selectedDay = i + 1;
                  _emitDate();
                },
              )),
              // Month wheel
              Expanded(child: _buildWheel(
                controller: _monthController,
                itemCount: 12,
                labelBuilder: (i) => _months[i],
                onChanged: (i) {
                  _selectedMonth = i + 1;
                  _emitDate();
                },
              )),
              // Year wheel
              Expanded(child: _buildWheel(
                controller: _yearController,
                itemCount: _maxYear - _minYear + 1,
                labelBuilder: (i) => '${_minYear + i}',
                onChanged: (i) {
                  _selectedYear = _minYear + i;
                  _emitDate();
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      overAndUnderCenterOpacity: 0.4,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (context, index) {
          return Center(
            child: Text(
              labelBuilder(index),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
