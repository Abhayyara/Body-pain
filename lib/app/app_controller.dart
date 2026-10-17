import 'package:flutter/widgets.dart';

import '../features/recommendations/recommendation_engine.dart';
import '../models/assessment.dart';
import '../models/body_region.dart';
import '../models/plan.dart';
import '../models/records.dart';
import '../services/anatomy_service.dart';
import '../services/storage_service.dart';

/// Single app-wide state holder (ChangeNotifier) exposed through [AppScope].
class AppController extends ChangeNotifier {
  AppController({
    required this.storage,
    AnatomyService? anatomy,
    RecommendationEngine? engine,
    DateTime Function()? clock,
  })  : anatomy = anatomy ?? AnatomyService(),
        _clock = clock ?? DateTime.now {
    this.engine = engine ?? RecommendationEngine(anatomy: this.anatomy);
  }

  final StorageService storage;
  final AnatomyService anatomy;
  late final RecommendationEngine engine;
  final DateTime Function() _clock;

  int tabIndex = 0;
  BodyView selectorView = BodyView.front;
  String? selectedRegionId;
  Assessment draft = Assessment();
  RecommendationPlan? latestPlan;

  List<AssessmentRecord> records = <AssessmentRecord>[];
  List<PainLogEntry> painLog = <PainLogEntry>[];
  SavedPlan? savedPlan;
  UserPreferences preferences = UserPreferences();
  Map<String, Set<String>> completions = <String, Set<String>>{};
  Map<String, int> hydration = <String, int>{};

  String get todayKey => dateKey(_clock());

  Future<void> load() async {
    records = storage.loadRecords();
    painLog = storage.loadPainLog();
    savedPlan = storage.loadPlan();
    preferences = storage.loadPreferences();
    completions = storage.loadCompletions();
    hydration = storage.loadHydration();
    notifyListeners();
  }

  // ---- navigation / selection -----------------------------------------
  void goToTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setSelectorView(BodyView view) {
    selectorView = view;
    notifyListeners();
  }

  void selectRegion(String id) {
    final region = anatomy.byId(id);
    if (region == null) return;
    selectedRegionId = id;
    draft.regionId = id;
    if (!region.visibleIn(selectorView)) {
      selectorView =
          selectorView == BodyView.front ? BodyView.back : BodyView.front;
    }
    notifyListeners();
  }

  /// Starts a fresh assessment, pre-filled from saved preferences.
  void startAssessment() {
    final fresh = Assessment(regionId: selectedRegionId);
    preferences.applyTo(fresh);
    draft = fresh;
    notifyListeners();
  }

  // ---- assessment -----------------------------------------------------
  Future<RecommendationPlan> submitAssessment() async {
    final plan = engine.build(draft);
    latestPlan = plan;
    final now = _clock();
    final stamp = now.microsecondsSinceEpoch.toString();

    // Free text is never persisted with the record.
    final stored = draft.copy()..additionalDetails = '';
    final record = AssessmentRecord(
      id: stamp,
      createdAt: now,
      assessment: stored,
      safetyStateId: plan.safety.state.id,
      exerciseIds: plan.exercises.map((e) => e.id).toList(),
    );
    records = <AssessmentRecord>[...records, record];
    await storage.addRecord(record);

    final pain = draft.painIntensity;
    if (pain != null && pain >= kMinPainIntensity && pain <= kMaxPainIntensity) {
      await _appendPain(pain, draft.regionId);
    }
    notifyListeners();
    return plan;
  }

  Future<void> savePlan() async {
    final plan = latestPlan;
    if (plan == null || !plan.hasPlan || plan.assessment.regionId == null) {
      return;
    }
    final saved = SavedPlan(
      regionId: plan.assessment.regionId!,
      exerciseIds: plan.exercises.map((e) => e.id).toList(),
      mealIds: <String>[
        for (final list in plan.mealsByType.values) ...list.map((m) => m.id),
      ],
      savedAt: _clock(),
    );
    savedPlan = saved;
    await storage.savePlan(saved);
    notifyListeners();
  }

  Future<void> clearSavedPlan() async {
    savedPlan = null;
    await storage.clearPlan();
    notifyListeners();
  }

  // ---- daily tracking -------------------------------------------------
  bool isCompletedToday(String exerciseId) =>
      completions[todayKey]?.contains(exerciseId) ?? false;

  Future<void> toggleExercise(String exerciseId) async {
    final set = Set<String>.of(completions[todayKey] ?? const <String>{});
    if (!set.add(exerciseId)) set.remove(exerciseId);
    completions = <String, Set<String>>{...completions, todayKey: set};
    await storage.saveCompletions(completions);
    notifyListeners();
  }

  int get waterToday => hydration[todayKey] ?? 0;

  Future<void> changeWater(int delta) async {
    final int next = (waterToday + delta).clamp(0, 30).toInt();
    hydration = <String, int>{...hydration, todayKey: next};
    await storage.saveHydration(hydration);
    notifyListeners();
  }

  // ---- pain log -------------------------------------------------------
  Future<void> _appendPain(int score, String? regionId) async {
    final now = _clock();
    painLog = <PainLogEntry>[
      ...painLog,
      PainLogEntry(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        score: score,
        regionId: regionId,
      ),
    ];
    await storage.savePainLog(painLog);
  }

  Future<void> logPain(int score, {String? regionId}) async {
    if (score < kMinPainIntensity || score > kMaxPainIntensity) return;
    await _appendPain(score, regionId ?? savedPlan?.regionId);
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    records = records.where((r) => r.id != id).toList();
    await storage.deleteRecord(id);
    notifyListeners();
  }

  // ---- preferences / deletion -----------------------------------------
  Future<void> updatePreferences(UserPreferences next) async {
    preferences = next;
    await storage.savePreferences(next);
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    await storage.deleteAllData();
    records = <AssessmentRecord>[];
    painLog = <PainLogEntry>[];
    savedPlan = null;
    preferences = UserPreferences();
    completions = <String, Set<String>>{};
    hydration = <String, int>{};
    latestPlan = null;
    draft = Assessment();
    selectedRegionId = null;
    notifyListeners();
  }
}
