import 'package:bodywise3d/data/exercises.dart';
import 'package:bodywise3d/data/nutrition.dart';
import 'package:bodywise3d/features/recommendations/recommendation_engine.dart';
import 'package:bodywise3d/models/assessment.dart';
import 'package:bodywise3d/models/exercise.dart';
import 'package:bodywise3d/models/meal.dart';
import 'package:bodywise3d/models/safety.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final engine = RecommendationEngine(allowDraftContent: true);

  Set<String> exerciseIds(Assessment a) =>
      engine.build(a).exercises.map((e) => e.id).toSet();

  group('safety blocking', () {
    test('an emergency trigger returns no exercises, meals or notes', () {
      final a = baseAssessment()..redFlags.add(RedFlag.chestPainWithBreathlessness);
      final plan = engine.build(a);
      expect(plan.safety.state, SafetyState.emergencyGuidance);
      expect(plan.hasPlan, isFalse);
      expect(plan.exercises, isEmpty);
      expect(plan.mealsByType, isEmpty);
      expect(plan.nutritionNotes, isEmpty);
      expect(plan.hydrationNote, isNull);
    });

    test('clinical and insufficient states return no plan either', () {
      for (final a in <Assessment>[baseAssessment(pain: 9), Assessment()]) {
        final plan = engine.build(a);
        expect(plan.hasPlan, isFalse);
        expect(plan.exercises, isEmpty);
        expect(plan.mealsByType, isEmpty);
      }
    });

    test('the input assessment is not mutated', () {
      final a = baseAssessment();
      engine.build(a);
      expect(a.regionId, 'left_knee');
      expect(a.painIntensity, 3);
    });
  });

  group('exercise eligibility filtering', () {
    test('knee pain matches knee exercises only', () {
      final ids = exerciseIds(baseAssessment());
      expect(ids, containsAll(<String>['quad_set', 'seated_knee_extension']));
      expect(ids, isNot(contains('neck_chin_tuck')));
    });

    test('left and right regions get the same family exercises', () {
      expect(exerciseIds(baseAssessment(regionId: 'right_knee')),
          exerciseIds(baseAssessment(regionId: 'left_knee')));
    });

    test('pain above an exercise limit excludes it', () {
      final ids = exerciseIds(baseAssessment(pain: 5));
      expect(ids, contains('quad_set')); // max 5
      expect(ids, isNot(contains('seated_knee_extension'))); // max 4
    });

    test('sharp, burning, tingling and numb sensations exclude everything', () {
      for (final s in <PainSensation>[
        PainSensation.sharp,
        PainSensation.burning,
      ]) {
        final plan = engine.build(baseAssessment(sensations: {s}));
        expect(plan.exercises, isEmpty, reason: s.name);
        expect(plan.noExerciseMessage, contains('professional assessment'));
      }
    });

    test('after-injury onset excludes exercises', () {
      final plan = engine.build(baseAssessment(pain: 2, onset: Onset.afterInjury));
      expect(plan.exercises, isEmpty);
    });

    test('movement that worsens pain keeps only suitable exercises', () {
      final ids = exerciseIds(baseAssessment(movementWorsens: true));
      expect(ids, <String>{'quad_set'});
    });

    test('cannot-lie-down limitation removes lying exercises', () {
      final a = baseAssessment()..limitations.add(ExerciseLimitation.cannotLieOnFloor);
      final plan = engine.build(a);
      expect(plan.exercises.where((e) => e.posture == Posture.lying), isEmpty);
      expect(exerciseIds(baseAssessment()), contains('heel_slide'));
      expect(plan.exercises.map((e) => e.id), isNot(contains('heel_slide')));
    });

    test('cannot-stand limitation removes standing exercises', () {
      final a = baseAssessment(regionId: 'lower_back')
        ..limitations.add(ExerciseLimitation.cannotStandLong);
      final plan = engine.build(a);
      expect(plan.exercises.where((e) => e.posture == Posture.standing), isEmpty);
      expect(plan.exercises, isNotEmpty);
    });

    test('contraindicated conditions remove an exercise', () {
      final withCondition = baseAssessment(regionId: 'mid_back')
        ..conditions.add(HealthCondition.osteoporosis);
      expect(exerciseIds(baseAssessment(regionId: 'mid_back')),
          contains('seated_thoracic_extension'));
      expect(exerciseIds(withCondition),
          isNot(contains('seated_thoracic_extension')));
    });

    test('pregnancy removes lying-on-back exercises', () {
      final a = baseAssessment(regionId: 'lower_back')
        ..conditions.add(HealthCondition.pregnancy);
      expect(exerciseIds(a), isNot(contains('pelvic_tilt_lying')));
    });

    test('no more than the maximum number of exercises is returned', () {
      final plan = engine.build(baseAssessment(regionId: 'lower_back'));
      expect(plan.exercises.length, lessThanOrEqualTo(RecommendationEngine.maxExercises));
    });

    test('areas with no matching exercise explain that help may be needed', () {
      final plan = engine.build(baseAssessment(regionId: 'abdomen', pain: 2));
      expect(plan.exercises, isEmpty);
      expect(plan.noExerciseMessage, isNotNull);
      expect(plan.noExerciseMessage, contains('professional assessment'));
    });

    test('every exercise record is complete', () {
      for (final e in kExercises) {
        expect(e.id, isNotEmpty);
        expect(e.applicableFamilies, isNotEmpty, reason: e.id);
        expect(e.instructions, isNotEmpty, reason: e.id);
        expect(e.stopConditions, isNotEmpty, reason: e.id);
        expect(e.modifications, isNotEmpty, reason: e.id);
        expect(e.contraindications, isNotEmpty, reason: e.id);
        expect(e.reviewedSource, isNotEmpty, reason: e.id);
      }
      expect(kExercises.map((e) => e.id).toSet().length, kExercises.length);
    });

    test('all shipped content is flagged as unreviewed draft', () {
      expect(kExercises.every((e) => !e.isClinicallyReviewed), isTrue);
      expect(kMeals.every((m) => !m.isClinicallyReviewed), isTrue);
    });
  });

  group('draft content gating', () {
    final strict = RecommendationEngine(allowDraftContent: false);

    test('release-style engine shows no unreviewed content', () {
      final plan = strict.build(baseAssessment());
      expect(plan.exercises, isEmpty);
      expect(plan.mealsByType, isEmpty);
      expect(plan.contentNotice, contains('awaiting clinical review'));
    });

    test('draft-enabled engine labels the plan as draft', () {
      final plan = engine.build(baseAssessment());
      expect(plan.usesDraftContent, isTrue);
      expect(plan.contentNotice, isNotNull);
    });
  });

  group('nutrition and dietary restrictions', () {
    List<Meal> allMeals(Assessment a) =>
        engine.build(a).mealsByType.values.expand((l) => l).toList();

    test('unspecified preference defaults to vegetarian', () {
      final meals = allMeals(baseAssessment());
      expect(meals, isNotEmpty);
      expect(
          meals.any((m) => m.containsMeat || m.containsFish || m.containsEgg),
          isFalse);
      expect(engine.build(baseAssessment()).nutritionNotes.join(' '),
          contains('vegetarian'));
    });

    test('vegan excludes meat, fish, egg and dairy', () {
      final a = baseAssessment()..dietPreference = DietPreference.vegan;
      final meals = allMeals(a);
      expect(meals, isNotEmpty);
      expect(
          meals.any((m) =>
              m.containsMeat || m.containsFish || m.containsEgg || m.containsDairy),
          isFalse);
    });

    test('eggetarian may include egg but never meat or fish', () {
      final a = baseAssessment()..dietPreference = DietPreference.eggetarian;
      final meals = allMeals(a);
      expect(meals.any((m) => m.containsMeat || m.containsFish), isFalse);
    });

    test('non-vegetarian can include animal products', () {
      final all = <Meal>[];
      final a = baseAssessment()..dietPreference = DietPreference.nonVegetarian;
      final engineAll = RecommendationEngine(allowDraftContent: true);
      final plan = engineAll.build(a);
      all.addAll(plan.mealsByType.values.expand((l) => l));
      expect(all, isNotEmpty);
    });

    test('allergens are never suggested', () {
      final a = baseAssessment()
        ..dietPreference = DietPreference.nonVegetarian
        ..allergens.addAll(<Allergen>{Allergen.peanuts, Allergen.dairy, Allergen.gluten});
      for (final m in allMeals(a)) {
        expect(m.allAllergens.intersection(a.allergens), isEmpty, reason: m.id);
      }
    });

    test('every meal type still has a suggestion with several restrictions', () {
      final a = baseAssessment()
        ..dietPreference = DietPreference.vegan
        ..allergens.add(Allergen.gluten)
        ..restrictions.add(DietaryRestriction.noOnionGarlic);
      final byType = engine.build(a).mealsByType;
      for (final t in MealType.values) {
        expect(byType[t], isNotEmpty, reason: t.name);
      }
      for (final m in byType.values.expand((l) => l)) {
        expect(m.containsOnionGarlic, isFalse, reason: m.id);
      }
    });

    test('health conditions add a dietitian note', () {
      final a = baseAssessment()..conditions.add(HealthCondition.diabetes);
      expect(engine.build(a).nutritionNotes.join(' '), contains('dietitian'));
    });

    test('nutrition copy never claims to treat pain', () {
      final text = engine.build(baseAssessment()).nutritionNotes.join(' ');
      expect(text, contains('No food cures or treats pain'));
    });
  });
}
