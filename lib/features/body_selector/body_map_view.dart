import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/body_region.dart';
import '../../services/anatomy_service.dart';

/// 2D FALLBACK body selector. This is NOT the 3D skeleton; it is the labelled
/// fallback the spec requires so a region can always be chosen.
class BodyMapView extends StatelessWidget {
  const BodyMapView({
    super.key,
    required this.anatomy,
    required this.view,
    required this.selectedId,
    required this.onRegionSelected,
  });

  static const Key hitAreaKey = Key('body_map_hit_area');

  final AnatomyService anatomy;
  final BodyView view;
  final String? selectedId;
  final ValueChanged<String> onRegionSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 0.5,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return Semantics(
              label: 'Body map, ${view == BodyView.front ? 'front' : 'back'} '
                  'view. Tap a body area to select it.',
              child: GestureDetector(
                key: hitAreaKey,
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  if (size.width <= 0 || size.height <= 0) return;
                  final normalised = Offset(
                    details.localPosition.dx / size.width,
                    details.localPosition.dy / size.height,
                  );
                  final region = anatomy.hitTest(view, normalised);
                  if (region != null) onRegionSelected(region.id);
                },
                child: CustomPaint(
                  size: size,
                  painter: BodyMapPainter(
                    regions: anatomy.regions,
                    view: view,
                    selectedId: selectedId,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BodyMapPainter extends CustomPainter {
  BodyMapPainter({
    required this.regions,
    required this.view,
    required this.selectedId,
  });

  final List<BodyRegion> regions;
  final BodyView view;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0xFFDDEBF2)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF9DB6C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final selectedFill = Paint()
      ..color = const Color(0x990E8F8C)
      ..style = PaintingStyle.fill;
    final selectedOutline = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    RRect? selectedShape;
    for (final r in regions) {
      final rect = r.rectFor(view);
      if (rect == null) continue;
      final scaled = Rect.fromLTRB(
        rect.left * size.width,
        rect.top * size.height,
        rect.right * size.width,
        rect.bottom * size.height,
      ).deflate(1);
      final radius = Radius.circular(
        scaled.shortestSide * (r.family == 'head' ? 0.5 : 0.35),
      );
      final shape = RRect.fromRectAndRadius(scaled, radius);
      canvas.drawRRect(shape, base);
      canvas.drawRRect(shape, outline);
      if (r.id == selectedId) selectedShape = shape;
    }
    if (selectedShape != null) {
      canvas.drawRRect(selectedShape, selectedFill);
      canvas.drawRRect(selectedShape, selectedOutline);
    }

    // Left/right orientation markers (anatomical sides, as the viewer sees it).
    final rightOnScreenLeft = view == BodyView.front;
    _drawMarker(canvas, size, rightOnScreenLeft ? 'R' : 'L', 0.06);
    _drawMarker(canvas, size, rightOnScreenLeft ? 'L' : 'R', 0.94);
  }

  void _drawMarker(Canvas canvas, Size size, String text, double nx) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(nx * size.width - painter.width / 2, size.height * 0.30),
    );
  }

  @override
  bool shouldRepaint(BodyMapPainter old) =>
      old.view != view ||
      old.selectedId != selectedId ||
      old.regions != regions;
}
