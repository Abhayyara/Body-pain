import 'assessment.dart';

enum ExerciseDifficulty {
  gentle('Gentle'),
  easy('Easy');

  const ExerciseDifficulty(this.label);
  final String label;
}

enum Posture {
  seated('Seated'),
  standing('Standing'),
  lying('Lying down');

  const Posture(this.label);
  final String label;
}

/// A reviewed-content exercise record. Content is only treated as reviewed when
/// [reviewDate] is set; until then it is draft placeholder text.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.purpose,
    required this.applicableFamilies,
    required this.posture,
    required this.difficulty,
    required this.maxPainIntensity,
    required this.suitabilityNotes,
    required this.contraindications,
    required this.instructions,
    required this.repetitionsOrDuration,
    required this.modifications,
    required this.stopConditions,
    required this.reviewedSource,
    this.excludedSensations = const <PainSensation>{},
    this.excludedOnsets = const <Onset>{},
    this.contraindicatedConditions = const <HealthCondition>{},
    this.suitableWhenMovementWorsens = false,
    this.equipment = const <String>[],
    this.reviewDate,
  });

  final String id;
  final String name;
  final String purpose;

  /// Body-region families (see BodyRegion.family) this exercise applies to.
  final Set<String> applicableFamilies;
  final Posture posture;
  final ExerciseDifficulty difficulty;

  // Machine-checked suitability rules.
  final int maxPainIntensity;
  final Set<PainSensation> excludedSensations;
  final Set<Onset> excludedOnsets;
  final Set<HealthCondition> contraindicatedConditions;
  final bool suitableWhenMovementWorsens;

  // Human-readable content.
  final List<String> suitabilityNotes;
  final List<String> contraindications;
  final List<String> instructions;
  final String repetitionsOrDuration;
  final List<String> equipment;
  final List<String> modifications;
  final List<String> stopConditions;
  final String reviewedSource;
  final DateTime? reviewDate;

  bool get isClinicallyReviewed => reviewDate != null;
}
