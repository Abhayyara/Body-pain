import 'dart:ui' show Rect;

import '../models/body_region.dart';

Rect _r(double l, double t, double r, double b) => Rect.fromLTRB(l, t, r, b);

Rect _mirror(Rect r) => Rect.fromLTRB(1 - r.right, r.top, 1 - r.left, r.bottom);

BodyRegion _midline({
  required String id,
  required String label,
  required String family,
  required RegionGroup group,
  Rect? front,
  Rect? back,
}) =>
    BodyRegion(
      id: id,
      label: label,
      family: family,
      group: group,
      side: BodySide.midline,
      frontRect: front,
      backRect: back,
    );

/// Builds the right/left pair for a lateralised family.
///
/// [rightFront] is the rectangle of the person's RIGHT side as seen in FRONT
/// view (i.e. on screen-left). Everything else is derived by mirroring:
///   right: front = rightFront,          back = mirror(rightFront)
///   left : front = mirror(rightFront),  back = rightFront
List<BodyRegion> _pair({
  required String family,
  required String name,
  required RegionGroup group,
  required Rect rightFront,
  bool inFront = true,
  bool inBack = true,
}) {
  return <BodyRegion>[
    BodyRegion(
      id: 'left_$family',
      label: 'Left ${name.toLowerCase()}',
      family: family,
      group: group,
      side: BodySide.left,
      frontRect: inFront ? _mirror(rightFront) : null,
      backRect: inBack ? rightFront : null,
    ),
    BodyRegion(
      id: 'right_$family',
      label: 'Right ${name.toLowerCase()}',
      family: family,
      group: group,
      side: BodySide.right,
      frontRect: inFront ? rightFront : null,
      backRect: inBack ? _mirror(rightFront) : null,
    ),
  ];
}

/// All 36 selectable regions, in display order.
final List<BodyRegion> kBodyRegions = List<BodyRegion>.unmodifiable(
  <BodyRegion>[
    // HEAD AND NECK
    _midline(
      id: 'head',
      label: 'Head',
      family: 'head',
      group: RegionGroup.headAndNeck,
      front: _r(.42, .01, .58, .11),
      back: _r(.42, .01, .58, .11),
    ),
    _midline(
      id: 'jaw',
      label: 'Jaw',
      family: 'jaw',
      group: RegionGroup.headAndNeck,
      front: _r(.44, .085, .56, .115),
    ),
    _midline(
      id: 'front_neck',
      label: 'Front of neck',
      family: 'neck',
      group: RegionGroup.headAndNeck,
      front: _r(.46, .115, .54, .16),
    ),
    _midline(
      id: 'back_neck',
      label: 'Back of neck',
      family: 'neck',
      group: RegionGroup.headAndNeck,
      back: _r(.46, .115, .54, .16),
    ),
    // TORSO
    _midline(
      id: 'chest',
      label: 'Chest',
      family: 'chest',
      group: RegionGroup.torso,
      front: _r(.42, .16, .58, .30),
    ),
    _midline(
      id: 'abdomen',
      label: 'Abdomen',
      family: 'abdomen',
      group: RegionGroup.torso,
      front: _r(.43, .30, .57, .44),
    ),
    _midline(
      id: 'upper_back',
      label: 'Upper back',
      family: 'upper_back',
      group: RegionGroup.torso,
      back: _r(.42, .16, .58, .28),
    ),
    _midline(
      id: 'mid_back',
      label: 'Mid back',
      family: 'mid_back',
      group: RegionGroup.torso,
      back: _r(.42, .28, .58, .38),
    ),
    _midline(
      id: 'lower_back',
      label: 'Lower back',
      family: 'lower_back',
      group: RegionGroup.torso,
      back: _r(.43, .38, .57, .47),
    ),
    _midline(
      id: 'pelvis',
      label: 'Pelvis',
      family: 'pelvis',
      group: RegionGroup.torso,
      front: _r(.43, .44, .57, .52),
      back: _r(.43, .47, .57, .54),
    ),
    // SHOULDERS AND ARMS
    ..._pair(
      family: 'shoulder',
      name: 'Shoulder',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.28, .16, .42, .22),
    ),
    ..._pair(
      family: 'upper_arm',
      name: 'Upper arm',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.25, .22, .33, .36),
    ),
    ..._pair(
      family: 'elbow',
      name: 'Elbow',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.24, .36, .32, .41),
    ),
    ..._pair(
      family: 'forearm',
      name: 'Forearm',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.23, .41, .31, .54),
    ),
    ..._pair(
      family: 'wrist',
      name: 'Wrist',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.22, .54, .30, .58),
    ),
    ..._pair(
      family: 'hand',
      name: 'Hand',
      group: RegionGroup.shouldersAndArms,
      rightFront: _r(.21, .58, .30, .67),
    ),
    // HIPS AND LEGS
    ..._pair(
      family: 'hip',
      name: 'Hip',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.34, .46, .43, .54),
    ),
    ..._pair(
      family: 'thigh',
      name: 'Thigh',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.37, .54, .49, .72),
    ),
    ..._pair(
      family: 'knee',
      name: 'Knee',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.38, .72, .48, .78),
    ),
    ..._pair(
      family: 'calf',
      name: 'Calf',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.39, .78, .48, .90),
      inFront: false,
    ),
    ..._pair(
      family: 'shin',
      name: 'Shin',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.39, .78, .48, .90),
      inBack: false,
    ),
    ..._pair(
      family: 'ankle',
      name: 'Ankle',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.40, .90, .47, .94),
    ),
    ..._pair(
      family: 'foot',
      name: 'Foot',
      group: RegionGroup.hipsAndLegs,
      rightFront: _r(.38, .94, .49, .99),
    ),
  ],
);

/// The IDs the product specification requires, used by tests and tooling.
const List<String> kRequiredRegionIds = <String>[
  'head', 'jaw', 'front_neck', 'back_neck',
  'chest', 'abdomen', 'upper_back', 'mid_back', 'lower_back', 'pelvis',
  'left_shoulder', 'right_shoulder', 'left_upper_arm', 'right_upper_arm',
  'left_elbow', 'right_elbow', 'left_forearm', 'right_forearm',
  'left_wrist', 'right_wrist', 'left_hand', 'right_hand',
  'left_hip', 'right_hip', 'left_thigh', 'right_thigh',
  'left_knee', 'right_knee', 'left_calf', 'right_calf',
  'left_shin', 'right_shin', 'left_ankle', 'right_ankle',
  'left_foot', 'right_foot',
];
