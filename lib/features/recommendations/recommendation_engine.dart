import '../../app/config.dart';
import '../../data/exercises.dart';
import '../../data/nutrition.dart';
import '../../models/assessment.dart';
import '../../models/exercise.dart';
import '../../models/meal.dart';
import '../../models/plan.dart';
import '../../services/anatomy_service.dart';
import '../safety/safety_engine.dart';

/// Turns an assessment into a plan. The safety engine always runs first and
/// its verdict is final: nothing is recommended unless the state is
/// general_wellness_eligible.
class RecommendationEngine {
  RecommendationEngine({
    SafetyEngine? safetyEngine,
    AnatomyService? anatomy,
    List<Exercise>? exercises,
    List<Meal>? meals,
    bool? allowDraftContent,
  })  : _safety = safetyEngine ?? const SafetyEngine(),
        _anatomy = anatomy ?? AnatomyService(),
        _exercises = exercises ?? kExercises,
        _meals = meals ?? kMeals,
        _allowDraft = allowDraftContent ?? AppConfig.allowDraftContent;

  static const int maxExercises = 4;
  static const int mealsPerType = 2;

  static const String hydrationNote =
      'Sip water regularly through the day. If a doctor has asked you to '
      'limit fluids, follow that advice instead.';

  final SafetyEngine _safety;
  final AnatomyService _anatomy;
  final List<Exercise> _exercises;
  final List<Meal> _meals;
  final bool _allowDraft;

  Exercise? exerciseById(String id) {
    for (final e in _exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  RecommendationPlan build(Assessment input) {
    final a = input.copy();
    final safety = _safety.evaluate(a);
    final region = a.regionId == null ? null : _anatomy.byId(a.regionId!);

    if (!safety.allowsRecommendations || region == null) {
      return RecommendationPlan(
        safety: safety,
        assessment: a,
        regionLabel: region?.label,
      );
    }

    final candidates =
        _exercises.where((e) => _matches(e, a, region.family)).toList();
    final shown = candidates
        .where((e) => e.isClinicallyReviewed || _allowDraft)
        .toList()
      ..sort((x, y) {
        final d = x.difficulty.index.compareTo(y.difficulty.index);
        return d != 0 ? d : x.name.compareTo(y.name);
      });
    final exercises = shown.take(maxExercises).toList();

    String? noExerciseMessage;
    String? contentNotice;
    if (exercises.isEmpty) {
      if (candidates.isNotEmpty) {
        contentNotice = 'Exercise content for this area is awaiting clinical '
            'review and is not available in this version of the app.';
        noExerciseMessage = contentNotice;
      } else {
        noExerciseMessage =
            'None of the reviewed exercises in this app match your '
            'circumstances. A professional assessment may be needed instead.';
      }
    }

    final meals = <MealType, List<Meal>>{};
    for (final type in MealType.values) {
      final picks = _meals
          .where((m) => m.type == type)
          .where((m) => m.isClinicallyReviewed || _allowDraft)
          .where((m) => _mealSuits(m, a))
          .take(mealsPerType)
          .toList();
      if (picks.isNotEmpty) meals[type] = picks;
    }

    final usesDraft = exercises.any((e) => !e.isClinicallyReviewed) ||
        meals.values.any((l) => l.any((m) => !m.isClinicallyReviewed));
    if (usesDraft) {
      contentNotice ??= 'Prototype build: exercise and nutrition content is '
          'draft text that has not been reviewed by a clinician or dietitian.';
    }

    return RecommendationPlan(
      safety: safety,
      assessment: a,
      regionLabel: region.label,
      exercises: exercises,
      noExerciseMessage: noExerciseMessage,
      mealsByType: meals,
      nutritionNotes: _nutritionNotes(a),
      hydrationNote: hydrationNote,
      contentNotice: contentNotice,
      usesDraftContent: usesDraft,
    );
  }

  bool _matches(Exercise e, Assessment a, String family) {
    if (!e.applicableFamilies.contains(family)) return false;
    final pain = a.painIntensity;
    if (pain == null || pain > e.maxPainIntensity) return false;
    if (e.excludedSensations.any(a.sensations.contains)) return false;
    if (a.onset != null && e.excludedOnsets.contains(a.onset)) return false;
    if (e.contraindicatedConditions.any(a.conditions.contains)) return false;
    if (a.movementWorsens == true && !e.suitableWhenMovementWorsens) {
      return false;
    }
    if (e.posture == Posture.lying &&
        a.limitations.contains(ExerciseLimitation.cannotLieOnFloor)) {
      return false;
    }
    if (e.posture == Posture.standing &&
        a.limitations.contains(ExerciseLimitation.cannotStandLong)) {
      return false;
    }
    return true;
  }

  /// With no stated preference we show vegetarian meals only (the most
  /// inclusive default) and say so in the notes.
  bool _mealSuits(Meal m, Assessment a) {
    final diet = a.dietPreference ?? DietPreference.vegetarian;
    switch (diet) {
      case DietPreference.vegan:
        if (m.containsMeat ||
            m.containsFish ||
            m.containsEgg ||
            m.containsDairy) {
          return false;
        }
      case DietPreference.vegetarian:
        if (m.containsMeat || m.containsFish || m.containsEgg) return false;
      case DietPreference.eggetarian:
        if (m.containsMeat || m.containsFish) return false;
      case DietPreference.nonVegetarian:
        break;
    }
    if (m.allAllergens.any(a.allergens.contains)) return false;
    if (a.restrictions.contains(DietaryRestriction.noOnionGarlic) &&
        m.containsOnionGarlic) {
      return false;
    }
    return true;
  }

  List<String> _nutritionNotes(Assessment a) {
    final notes = <String>[
      'Balanced meals with vegetables, fruit, whole grains, pulses and a '
          'protein source support general wellbeing. No food cures or '
          'treats pain.',
    ];
    if (a.dietPreference == null) {
      notes.add('Showing vegetarian ideas. Set your food preference in '
          'Profile to see other options.');
    }
    if (a.restrictions.contains(DietaryRestriction.lowSalt)) {
      notes.add('For low salt, season food with spices, lemon and herbs '
          'instead of extra salt, pickles or papad.');
    }
    const needsDietitian = <HealthCondition>{
      HealthCondition.diabetes,
      HealthCondition.heartCondition,
      HealthCondition.highBloodPressure,
      HealthCondition.pregnancy,
    };
    if (a.conditions.any(needsDietitian.contains)) {
      notes.add('Because of a health condition you listed, please ask a '
          'doctor or registered dietitian for individual nutrition advice. '
          'These are general ideas only.');
    }
    return notes;
  }
}
