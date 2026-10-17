import 'dart:ui' show Offset;

import '../data/body_regions.dart';
import '../models/body_region.dart';

/// Region lookup and 2D hit-testing. Phase 2 extends this with
/// mesh-name -> region resolution for the 3D skeleton.
class AnatomyService {
  AnatomyService({List<BodyRegion>? regions})
      : _regions = List<BodyRegion>.unmodifiable(regions ?? kBodyRegions) {
    for (final r in _regions) {
      _byId[r.id] = r;
      for (final m in r.meshNames) {
        _byMesh[m] = r;
      }
    }
  }

  final List<BodyRegion> _regions;
  final Map<String, BodyRegion> _byId = <String, BodyRegion>{};
  final Map<String, BodyRegion> _byMesh = <String, BodyRegion>{};

  List<BodyRegion> get regions => _regions;

  BodyRegion? byId(String id) => _byId[id];

  /// Phase 2: resolves a tapped 3D mesh/proxy name to a region.
  BodyRegion? regionForMesh(String meshName) => _byMesh[meshName];

  List<BodyRegion> visibleIn(BodyView view) =>
      _regions.where((r) => r.visibleIn(view)).toList(growable: false);

  List<BodyRegion> inGroup(RegionGroup group) =>
      _regions.where((r) => r.group == group).toList(growable: false);

  /// [normalised] is a point in the 0..1 box. When several regions overlap,
  /// the one with the smallest area wins (e.g. jaw over head).
  BodyRegion? hitTest(BodyView view, Offset normalised) {
    BodyRegion? best;
    double bestArea = double.infinity;
    for (final r in _regions) {
      final rect = r.rectFor(view);
      if (rect == null || !rect.contains(normalised)) continue;
      final area = rect.width * rect.height;
      if (area < bestArea) {
        best = r;
        bestArea = area;
      }
    }
    return best;
  }
}
