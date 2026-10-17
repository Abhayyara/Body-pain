import 'package:bodywise3d/app/app_controller.dart';
import 'package:bodywise3d/models/assessment.dart';
import 'package:bodywise3d/models/records.dart';
import 'package:bodywise3d/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<StorageService> _storage([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return StorageService.create();
}

void main() {
  test('records can be added, listed and deleted individually', () async {
    final s = await _storage();
    final a = AssessmentRecord(
      id: '1',
      createdAt: DateTime(2026, 1, 2),
      assessment: baseAssessment(),
      safetyStateId: 'general_wellness_eligible',
      exerciseIds: const <String>['quad_set'],
    );
    final b = AssessmentRecord(
      id: '2',
      createdAt: DateTime(2026, 1, 3),
      assessment: baseAssessment(regionId: 'back_neck'),
      safetyStateId: 'general_wellness_eligible',
    );
    await s.addRecord(a);
    await s.addRecord(b);
    expect(s.loadRecords().map((r) => r.id), <String>['1', '2']);
    expect(s.loadRecords().first.exerciseIds, <String>['quad_set']);
    await s.deleteRecord('1');
    expect(s.loadRecords().map((r) => r.id), <String>['2']);
  });

  test('saved plan round trips and can be cleared', () async {
    final s = await _storage();
    await s.savePlan(SavedPlan(
      regionId: 'left_knee',
      exerciseIds: const <String>['quad_set'],
      mealIds: const <String>['s_fruit'],
      savedAt: DateTime(2026, 1, 2),
    ));
    expect(s.loadPlan()!.regionId, 'left_knee');
    await s.clearPlan();
    expect(s.loadPlan(), isNull);
  });

  test('completions, hydration and pain log persist', () async {
    final s = await _storage();
    await s.saveCompletions(<String, Set<String>>{
      '2026-01-02': <String>{'quad_set'},
    });
    await s.saveHydration(<String, int>{'2026-01-02': 3});
    await s.savePainLog(<PainLogEntry>[
      PainLogEntry(id: 'p', createdAt: DateTime(2026, 1, 2), score: 4),
    ]);
    expect(s.loadCompletions()['2026-01-02'], <String>{'quad_set'});
    expect(s.loadHydration()['2026-01-02'], 3);
    expect(s.loadPainLog().single.score, 4);
  });

  test('preferences round trip', () async {
    final s = await _storage();
    await s.savePreferences(UserPreferences(
      dietPreference: DietPreference.vegan,
      allergens: <Allergen>{Allergen.soy},
    ));
    final p = s.loadPreferences();
    expect(p.dietPreference, DietPreference.vegan);
    expect(p.allergens, <Allergen>{Allergen.soy});
  });

  test('deleteAllData removes every BodyWise key and nothing else', () async {
    final s = await _storage(<String, Object>{'other_app_key': 'keep me'});
    await s.addRecord(AssessmentRecord(
      id: '1',
      createdAt: DateTime(2026, 1, 2),
      assessment: baseAssessment(),
      safetyStateId: 'general_wellness_eligible',
    ));
    await s.saveHydration(<String, int>{'2026-01-02': 2});
    await s.savePreferences(UserPreferences(ageRange: AgeRange.age18to39));
    await s.deleteAllData();
    expect(s.loadRecords(), isEmpty);
    expect(s.loadHydration(), isEmpty);
    expect(s.loadPlan(), isNull);
    expect(s.loadPreferences().ageRange, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), <String>{'other_app_key'});
  });

  test('corrupted stored data is ignored instead of crashing', () async {
    final s = await _storage(<String, Object>{
      'bw_records_v1': '{not json',
      'bw_plan_v1': '123',
      'bw_hydration_v1': '[]',
    });
    expect(s.loadRecords(), isEmpty);
    expect(s.loadPlan(), isNull);
    expect(s.loadHydration(), isEmpty);
  });

  group('AppController', () {
    test('submitting stores the record WITHOUT free text and logs pain',
        () async {
      final s = await _storage();
      final c = AppController(
        storage: s,
        clock: () => DateTime(2026, 3, 4, 10),
      );
      c.draft = baseAssessment()..additionalDetails = 'private note';
      final plan = await c.submitAssessment();
      expect(plan.hasPlan, isTrue);
      expect(c.records, hasLength(1));
      expect(c.records.single.assessment.additionalDetails, '');
      expect(s.loadRecords().single.assessment.additionalDetails, '');
      expect(s.loadPainLog().single.score, 3);
    });

    test('an emergency submission is recorded but yields no plan', () async {
      final s = await _storage();
      final c = AppController(storage: s);
      c.draft = baseAssessment()..redFlags.add(RedFlag.severeBreathingDifficulty);
      final plan = await c.submitAssessment();
      expect(plan.hasPlan, isFalse);
      expect(c.records.single.safetyStateId, 'emergency_guidance');
      expect(c.records.single.exerciseIds, isEmpty);
    });

    test('savePlan only saves eligible plans', () async {
      final s = await _storage();
      final c = AppController(storage: s);
      c.draft = baseAssessment(pain: 9);
      await c.submitAssessment();
      await c.savePlan();
      expect(c.savedPlan, isNull);
      expect(s.loadPlan(), isNull);

      c.draft = baseAssessment();
      await c.submitAssessment();
      await c.savePlan();
      expect(c.savedPlan!.regionId, 'left_knee');
      expect(s.loadPlan(), isNotNull);
    });

    test('hydration and exercise tracking are per day and clamp at zero',
        () async {
      final s = await _storage();
      var now = DateTime(2026, 3, 4, 9);
      final c = AppController(storage: s, clock: () => now);
      await c.changeWater(-1);
      expect(c.waterToday, 0);
      await c.changeWater(2);
      expect(c.waterToday, 2);
      await c.toggleExercise('quad_set');
      expect(c.isCompletedToday('quad_set'), isTrue);
      await c.toggleExercise('quad_set');
      expect(c.isCompletedToday('quad_set'), isFalse);
      now = DateTime(2026, 3, 5, 9);
      expect(c.waterToday, 0);
    });

    test('out-of-range pain log entries are ignored', () async {
      final s = await _storage();
      final c = AppController(storage: s);
      await c.logPain(11);
      await c.logPain(-1);
      expect(c.painLog, isEmpty);
      await c.logPain(0);
      await c.logPain(10);
      expect(c.painLog.map((e) => e.score), <int>[0, 10]);
    });

    test('deleteAllData wipes memory and storage', () async {
      final s = await _storage();
      final c = AppController(storage: s);
      c.draft = baseAssessment();
      await c.submitAssessment();
      await c.savePlan();
      await c.changeWater(1);
      await c.deleteAllData();
      expect(c.records, isEmpty);
      expect(c.savedPlan, isNull);
      expect(c.latestPlan, isNull);
      expect(c.waterToday, 0);
      expect(s.loadRecords(), isEmpty);
      expect(s.loadPlan(), isNull);
      expect(s.loadPainLog(), isEmpty);
    });

    test('startAssessment pre-fills saved preferences without overwriting',
        () async {
      final s = await _storage();
      final c = AppController(storage: s);
      await c.updatePreferences(UserPreferences(
        dietPreference: DietPreference.vegan,
        allergens: <Allergen>{Allergen.peanuts},
      ));
      c.selectRegion('right_knee');
      c.startAssessment();
      expect(c.draft.regionId, 'right_knee');
      expect(c.draft.dietPreference, DietPreference.vegan);
      expect(c.draft.allergens, contains(Allergen.peanuts));
    });

    test('selecting a region only visible in the other view flips the view',
        () async {
      final s = await _storage();
      final c = AppController(storage: s);
      expect(c.selectorView.name, 'front');
      c.selectRegion('lower_back');
      expect(c.selectorView.name, 'back');
      c.selectRegion('not_a_region');
      expect(c.selectedRegionId, 'lower_back');
    });
  });
}
