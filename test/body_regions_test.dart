import 'dart:ui';

import 'package:bodywise3d/data/body_regions.dart';
import 'package:bodywise3d/models/body_region.dart';
import 'package:bodywise3d/services/anatomy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final anatomy = AnatomyService();

  test('region ids are unique', () {
    final ids = kBodyRegions.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every required region exists and nothing extra is defined', () {
    final ids = kBodyRegions.map((r) => r.id).toSet();
    expect(ids, equals(kRequiredRegionIds.toSet()));
    expect(kBodyRegions.length, 36);
  });

  test('every region is visible in at least one view with a valid rect', () {
    for (final r in kBodyRegions) {
      expect(r.visibleIn(BodyView.front) || r.visibleIn(BodyView.back), isTrue,
          reason: r.id);
      for (final view in BodyView.values) {
        final rect = r.rectFor(view);
        if (rect == null) continue;
        expect(rect.left, greaterThanOrEqualTo(0), reason: r.id);
        expect(rect.top, greaterThanOrEqualTo(0), reason: r.id);
        expect(rect.right, lessThanOrEqualTo(1), reason: r.id);
        expect(rect.bottom, lessThanOrEqualTo(1), reason: r.id);
        expect(rect.width, greaterThan(0), reason: r.id);
        expect(rect.height, greaterThan(0), reason: r.id);
      }
    }
  });

  test('left/right ids, labels and sides agree', () {
    for (final r in kBodyRegions) {
      if (r.id.startsWith('left_')) {
        expect(r.side, BodySide.left, reason: r.id);
        expect(r.label.startsWith('Left '), isTrue, reason: r.id);
      } else if (r.id.startsWith('right_')) {
        expect(r.side, BodySide.right, reason: r.id);
        expect(r.label.startsWith('Right '), isTrue, reason: r.id);
      } else {
        expect(r.side, BodySide.midline, reason: r.id);
      }
    }
  });

  test('anatomical sides sit on the correct side of the screen', () {
    // Front view: the person's LEFT is on the viewer's RIGHT.
    // Back view: the person's LEFT is on the viewer's LEFT.
    for (final r in kBodyRegions) {
      if (r.side == BodySide.midline) continue;
      final front = r.frontRect;
      final back = r.backRect;
      final leftSide = r.side == BodySide.left;
      if (front != null) {
        expect(front.center.dx > 0.5, leftSide, reason: '${r.id} front');
      }
      if (back != null) {
        expect(back.center.dx < 0.5, leftSide, reason: '${r.id} back');
      }
    }
  });

  test('left and right regions mirror each other', () {
    for (final r in kBodyRegions.where((r) => r.side == BodySide.left)) {
      final twin = anatomy.byId(r.id.replaceFirst('left_', 'right_'))!;
      for (final view in BodyView.values) {
        final a = r.rectFor(view);
        final b = twin.rectFor(view);
        expect(a == null, b == null, reason: r.id);
        if (a != null && b != null) {
          expect(a.left, closeTo(1 - b.right, 1e-9), reason: r.id);
          expect(a.right, closeTo(1 - b.left, 1e-9), reason: r.id);
        }
      }
    }
  });

  test('view-specific regions are only visible in the right view', () {
    expect(anatomy.byId('chest')!.visibleIn(BodyView.back), isFalse);
    expect(anatomy.byId('lower_back')!.visibleIn(BodyView.front), isFalse);
    expect(anatomy.byId('left_shin')!.visibleIn(BodyView.back), isFalse);
    expect(anatomy.byId('left_calf')!.visibleIn(BodyView.front), isFalse);
    expect(anatomy.byId('jaw')!.visibleIn(BodyView.back), isFalse);
    expect(anatomy.byId('back_neck')!.visibleIn(BodyView.front), isFalse);
  });

  test('hit testing resolves expected regions', () {
    expect(anatomy.hitTest(BodyView.front, const Offset(0.65, 0.19))?.id,
        'left_shoulder');
    expect(anatomy.hitTest(BodyView.front, const Offset(0.35, 0.19))?.id,
        'right_shoulder');
    expect(anatomy.hitTest(BodyView.back, const Offset(0.35, 0.19))?.id,
        'left_shoulder');
    expect(anatomy.hitTest(BodyView.back, const Offset(0.5, 0.42))?.id,
        'lower_back');
    expect(anatomy.hitTest(BodyView.front, const Offset(0.5, 0.2))?.id,
        'chest');
    expect(anatomy.hitTest(BodyView.front, const Offset(0.6, 0.85))?.id,
        'left_shin');
  });

  test('smaller overlapping region wins (jaw over head)', () {
    expect(anatomy.hitTest(BodyView.front, const Offset(0.5, 0.10))?.id, 'jaw');
    expect(anatomy.hitTest(BodyView.front, const Offset(0.5, 0.05))?.id, 'head');
  });

  test('taps outside any region select nothing', () {
    expect(anatomy.hitTest(BodyView.front, const Offset(0.05, 0.5)), isNull);
    expect(anatomy.hitTest(BodyView.back, const Offset(0.95, 0.05)), isNull);
  });

  test('unknown mesh names resolve to nothing (3D mapping not yet added)', () {
    expect(anatomy.regionForMesh('Femur_L'), isNull);
  });
}
