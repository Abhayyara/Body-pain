import 'assessment.dart';

class AssessmentRecord {
  const AssessmentRecord({
    required this.id,
    required this.createdAt,
    required this.assessment,
    required this.safetyStateId,
    this.exerciseIds = const <String>[],
  });

  final String id;
  final DateTime createdAt;

  /// Stored WITHOUT free-text details.
  final Assessment assessment;
  final String safetyStateId;
  final List<String> exerciseIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'assessment': assessment.toJson(),
        'safetyState': safetyStateId,
        'exerciseIds': exerciseIds,
      };

  factory AssessmentRecord.fromJson(Map<String, Object?> json) =>
      AssessmentRecord(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        assessment: Assessment.fromJson(
            Map<String, Object?>.from(json['assessment'] as Map)),
        safetyStateId: json['safetyState'] as String,
        exerciseIds: (json['exerciseIds'] as List? ?? const <Object?>[])
            .map((e) => e as String)
            .toList(),
      );
}

class SavedPlan {
  const SavedPlan({
    required this.regionId,
    required this.exerciseIds,
    required this.mealIds,
    required this.savedAt,
  });

  final String regionId;
  final List<String> exerciseIds;
  final List<String> mealIds;
  final DateTime savedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'regionId': regionId,
        'exerciseIds': exerciseIds,
        'mealIds': mealIds,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedPlan.fromJson(Map<String, Object?> json) => SavedPlan(
        regionId: json['regionId'] as String,
        exerciseIds:
            (json['exerciseIds'] as List).map((e) => e as String).toList(),
        mealIds: (json['mealIds'] as List).map((e) => e as String).toList(),
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}

class PainLogEntry {
  const PainLogEntry({
    required this.id,
    required this.createdAt,
    required this.score,
    this.regionId,
  });

  final String id;
  final DateTime createdAt;
  final int score;
  final String? regionId;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'score': score,
        'regionId': regionId,
      };

  factory PainLogEntry.fromJson(Map<String, Object?> json) => PainLogEntry(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        score: json['score'] as int,
        regionId: json['regionId'] as String?,
      );
}

/// Optional profile answers, kept on-device and used to pre-fill assessments.
class UserPreferences {
  UserPreferences({
    this.ageRange,
    this.dietPreference,
    Set<Allergen>? allergens,
    Set<DietaryRestriction>? restrictions,
    Set<ExerciseLimitation>? limitations,
    Set<HealthCondition>? conditions,
  })  : allergens = Set<Allergen>.of(allergens ?? const <Allergen>{}),
        restrictions = Set<DietaryRestriction>.of(
            restrictions ?? const <DietaryRestriction>{}),
        limitations = Set<ExerciseLimitation>.of(
            limitations ?? const <ExerciseLimitation>{}),
        conditions =
            Set<HealthCondition>.of(conditions ?? const <HealthCondition>{});

  AgeRange? ageRange;
  DietPreference? dietPreference;
  final Set<Allergen> allergens;
  final Set<DietaryRestriction> restrictions;
  final Set<ExerciseLimitation> limitations;
  final Set<HealthCondition> conditions;

  void applyTo(Assessment a) {
    a.ageRange ??= ageRange;
    a.dietPreference ??= dietPreference;
    a.allergens.addAll(allergens);
    a.restrictions.addAll(restrictions);
    a.limitations.addAll(limitations);
    a.conditions.addAll(conditions);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'ageRange': ageRange?.name,
        'dietPreference': dietPreference?.name,
        'allergens': allergens.map((e) => e.name).toList(),
        'restrictions': restrictions.map((e) => e.name).toList(),
        'limitations': limitations.map((e) => e.name).toList(),
        'conditions': conditions.map((e) => e.name).toList(),
      };

  factory UserPreferences.fromJson(Map<String, Object?> json) =>
      UserPreferences(
        ageRange: enumByName(AgeRange.values, json['ageRange']),
        dietPreference:
            enumByName(DietPreference.values, json['dietPreference']),
        allergens: enumSetByNames(Allergen.values, json['allergens']),
        restrictions:
            enumSetByNames(DietaryRestriction.values, json['restrictions']),
        limitations:
            enumSetByNames(ExerciseLimitation.values, json['limitations']),
        conditions: enumSetByNames(HealthCondition.values, json['conditions']),
      );
}
