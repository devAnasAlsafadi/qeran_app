part of 'qeran_bottom_nav.dart';

/// The portrait island's layers, kept here so the widget's file holds its
/// parameters and the motion.
extension _Island on _QeranBottomNavState {
  /// The bar, the disc under the selected icon, and the cells over both.
  Widget _island(BuildContext context, double width) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final tabWidth = width / widget.items.length;
    final animIndex = lerpDouble(_animFrom, _animTo, _slide.value) ?? _animTo;
    final logicalCenter = (animIndex + 0.5) * tabWidth;
    final discX = isRtl ? width - logicalCenter : logicalCenter;
    return Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: QeranBottomNav.barHeight,
          child: CustomPaint(
            key: QeranBottomNav.barKey,
            painter: _BarPainter(),
          ),
        ),
        Positioned(
          left: discX - QeranBottomNav.discDiameter / 2,
          bottom:
              QeranBottomNav.barHeight -
              QeranBottomNav.iconSlotTop -
              QeranBottomNav.discDiameter,
          width: QeranBottomNav.discDiameter,
          height: QeranBottomNav.discDiameter,
          child: const _SelectedDisc(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: QeranBottomNav.barHeight,
          child: Row(children: List.generate(widget.items.length, _cell)),
        ),
      ],
    );
  }

  Widget _cell(int i) => Expanded(
    child: _TabCell(
      item: widget.items[i],
      isActive: i == widget.currentIndex,
      outlineOpacity: _outlineOpacityFor(i),
      onTap: () {
        HapticFeedback.lightImpact();
        if (i != widget.currentIndex) widget.onTap(i);
      },
    ),
  );
}

/// The island: white, rounded, with a raised wine shadow — white-on-white
/// needs a stronger, more elevated lift than e3 to read above the content.
class _BarPainter extends CustomPainter {
  const _BarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(QeranRadii.card),
        ),
      );
    canvas.drawShadow(bar, QeranColors.wine.withValues(alpha: 0.18), 24, false);
    canvas.drawPath(bar, Paint()..color = QeranColors.paper);
  }

  @override
  bool shouldRepaint(_BarPainter old) => false;
}

/// The selected tab's mark: a flat gold disc, inside the bar, behind its icon.
class _SelectedDisc extends StatelessWidget {
  const _SelectedDisc();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      key: QeranBottomNav.discKey,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
      ),
    );
  }
}
