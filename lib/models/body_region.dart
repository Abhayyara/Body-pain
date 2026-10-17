import 'dart:ui' show Rect;

enum BodyView { front, back }

enum RegionGroup {
  headAndNeck('Head & neck'),
  torso('Torso'),
  shouldersAndArms('Shoulders & arms'),
  hipsAndLegs('Hips & legs');

  const RegionGroup(this.label);
  final String label;
}

enum BodySide { left, right, midline }

/// A selectable body region.
///
/// [frontRect] / [backRect] are hit areas for the 2D fallback selector in a
/// normalised 0..1 box (x to the right, y downwards, aspect 1:2). They are
/// expressed as the viewer sees the figure: in FRONT view the person's right
/// side is on screen-left; in BACK view it is on screen-right.
///
/// [meshNames] is reserved for the 3D skeleton (Phase 2).
class BodyRegion {
  const BodyRegion({
    required this.id,
    required this.label,
    required this.family,
    required this.group,
    required this.side,
    required this.frontRect,
    required this.backRect,
    this.meshNames = const <String>[],
  });

  final String id;
  final String label;

  /// Side-independent anatomical family, e.g. `knee` for left_knee/right_knee.
  final String family;
  final RegionGroup group;
  final BodySide side;
  final Rect? frontRect;
  final Rect? backRect;
  final List<String> meshNames;

  bool get isMidline => side == BodySide.midline;

  Rect? rectFor(BodyView view) =>
      view == BodyView.front ? frontRect : backRect;

  bool visibleIn(BodyView view) => rectFor(view) != null;
}
