import 'assessment.dart';
import 'exercise.dart';
import 'meal.dart';
import 'safety.dart';

class RecommendationPlan {
  const RecommendationPlan({
    required this.safety,
    required this.assessment,
    this.regionLabel,
    this.exercises = const <Exercise>[],
    this.noExerciseMessage,
    this.mealsByType = const <MealType, List<Meal>>{},
    this.nutritionNotes = const <String>[],
    this.hydrationNote,
    this.contentNotice,
    this.usesDraftContent = false,
  });

  final SafetyResult safety;

  /// A copy of the assessment the plan was built from.
  final Assessment assessment;
  final String? regionLabel;
  final List<Exercise> exercises;
  final String? noExerciseMessage;
  final Map<MealType, List<Meal>> mealsByType;
  final List<String> nutritionNotes;
  final String? hydrationNote;
  final String? contentNotice;
  final bool usesDraftContent;

  bool get hasPlan => safety.allowsRecommendations;
}
