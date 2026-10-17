# 3D skeleton asset (Phase 2 - not yet added)

No skeleton model is included in this project. A real anatomical skeleton GLB
must be sourced under a licence that permits commercial use inside a mobile
app (record the licence text and attribution in this folder). Candidates must
be inspected for named meshes; if the model does not split into the regions in
`lib/data/body_regions.dart`, add invisible proxy meshes/collision volumes and
map them in `assets/data/mesh_map.json` (mesh name -> region id), which
`AnatomyService.regionForMesh` will load.

Until then the app uses the clearly labelled 2D fallback selector.
