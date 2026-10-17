const int kMinPainIntensity = 0;
const int kMaxPainIntensity = 10;

enum PainDuration {
  lessThan24Hours('Less than 24 hours'),
  oneToThreeDays('1–3 days'),
  fourToFourteenDays('4–14 days'),
  moreThanFourteenDays('More than 14 days');

  const PainDuration(this.label);
  final String label;
}

enum PainSensation {
  aching('Aching'),
  stiffness('Stiffness'),
  sharp('Sharp'),
  burning('Burning'),
  tingling('Tingling'),
  numbness('Numbness'),
  other('Other');

  const PainSensation(this.label);
  final String label;
}

enum Onset {
  sudden('Sudden'),
  gradual('Gradual'),
  afterExercise('After exercise'),
  afterInjury('After an injury');

  const Onset(this.label);
  final String label;
}

enum ImpactArea {
  dailyActivities('Daily activities'),
  walking('Walking'),
  sleep('Sleep');

  const ImpactArea(this.label);
  final String label;
}

/// Only asked for midline regions (chest, back, head, ...). Sided regions
/// (left_knee, right_knee, ...) carry their side in the region id.
enum SideDetail {
  center('Centre / not sure'),
  left('Left'),
  right('Right'),
  both('Both sides');

  const SideDetail(this.label);
  final String label;
}

enum RedFlag {
  chestPainWithBreathlessness(
    'Chest pain or pressure together with shortness of breath, sweating, '
    'nausea, or pain spreading to the arm, jaw, or back',
  ),
  faceDroopOrSpeechTrouble(
    'Sudden face drooping, slurred or difficult speech, or new weakness or '
    'numbness on one side of the body',
  ),
  majorTraumaOrDeformity(
    'A major injury (for example a road accident or fall from a height), an '
    'obvious deformity, or a bone that may be broken',
  ),
  bladderBowelOrGroinNumbness(
    'New loss of bladder or bowel control, or numbness around the groin or '
    'inner thighs',
  ),
  hotSwollenJointWithFever(
    'A hot, red, swollen joint together with fever or chills',
  ),
  severeBreathingDifficulty(
    'Severe difficulty breathing, fainting, or collapse',
  ),
  suddenSevereHeadache(
    'A sudden, severe headache unlike any you have had before',
  );

  const RedFlag(this.label);
  final String label;
}

enum AgeRange {
  under18('Under 18'),
  age18to39('18–39'),
  age40to59('40–59'),
  age60plus('60 or older');

  const AgeRange(this.label);
  final String label;
}

enum ExerciseLimitation {
  cannotLieOnFloor('I cannot lie down on a bed or the floor'),
  cannotStandLong('I cannot stand for long');

  const ExerciseLimitation(this.label);
  final String label;
}

enum HealthCondition {
  heartCondition('Heart condition'),
  highBloodPressure('High blood pressure'),
  diabetes('Diabetes'),
  osteoporosis('Osteoporosis'),
  arthritis('Arthritis'),
  pregnancy('Pregnancy'),
  recentSurgery('Recent surgery');

  const HealthCondition(this.label);
  final String label;
}

enum DietPreference {
  vegetarian('Vegetarian'),
  eggetarian('Vegetarian + eggs'),
  nonVegetarian('Non-vegetarian'),
  vegan('Vegan');

  const DietPreference(this.label);
  final String label;
}

enum Allergen {
  dairy('Dairy'),
  eggs('Eggs'),
  gluten('Gluten / wheat'),
  peanuts('Peanuts'),
  treeNuts('Tree nuts'),
  soy('Soy'),
  fish('Fish'),
  shellfish('Shellfish');

  const Allergen(this.label);
  final String label;
}

enum DietaryRestriction {
  noOnionGarlic('No onion or garlic'),
  lowSalt('Low salt');

  const DietaryRestriction(this.label);
  final String label;
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

Set<T> _enumSetByNames<T extends Enum>(List<T> values, Object? raw) {
  final out = <T>{};
  if (raw is List) {
    for (final item in raw) {
      final v = _enumByName(values, item);
      if (v != null) out.add(v);
    }
  }
  return out;
}

/// Structured assessment. Free text is kept in [additionalDetails] only; it is
/// never part of the structured payload intended for any AI service.
class Assessment {
  Assessment({
    this.regionId,
    this.sideDetail,
    this.painIntensity,
    this.duration,
    Set<PainSensation>? sensations,
    this.onset,
    this.movementWorsens,
    Set<ImpactArea>? impacts,
    Set<RedFlag>? redFlags,
    this.redFlagsReviewed = false,
    this.additionalDetails = '',
    this.ageRange,
    Set<ExerciseLimitation>? limitations,
    Set<HealthCondition>? conditions,
    this.dietPreference,
    Set<Allergen>? allergens,
    Set<DietaryRestriction>? restrictions,
  })  : sensations = Set<PainSensation>.of(sensations ?? const <PainSensation>{}),
        impacts = Set<ImpactArea>.of(impacts ?? const <ImpactArea>{}),
        redFlags = Set<RedFlag>.of(redFlags ?? const <RedFlag>{}),
        limitations = Set<ExerciseLimitation>.of(
            limitations ?? const <ExerciseLimitation>{}),
        conditions =
            Set<HealthCondition>.of(conditions ?? const <HealthCondition>{}),
        allergens = Set<Allergen>.of(allergens ?? const <Allergen>{}),
        restrictions = Set<DietaryRestriction>.of(
            restrictions ?? const <DietaryRestriction>{});

  String? regionId;
  SideDetail? sideDetail;
  int? painIntensity;
  PainDuration? duration;
  final Set<PainSensation> sensations;
  Onset? onset;
  bool? movementWorsens;
  final Set<ImpactArea> impacts;
  final Set<RedFlag> redFlags;

  /// True once the user has either ticked warning signs or explicitly
  /// confirmed that none apply.
  bool redFlagsReviewed;
  String additionalDetails;
  AgeRange? ageRange;
  final Set<ExerciseLimitation> limitations;
  final Set<HealthCondition> conditions;
  DietPreference? dietPreference;
  final Set<Allergen> allergens;
  final Set<DietaryRestriction> restrictions;

  Assessment copy() => Assessment(
        regionId: regionId,
        sideDetail: sideDetail,
        painIntensity: painIntensity,
        duration: duration,
        sensations: sensations,
        onset: onset,
        movementWorsens: movementWorsens,
        impacts: impacts,
        redFlags: redFlags,
        redFlagsReviewed: redFlagsReviewed,
        additionalDetails: additionalDetails,
        ageRange: ageRange,
        limitations: limitations,
        conditions: conditions,
        dietPreference: dietPreference,
        allergens: allergens,
        restrictions: restrictions,
      );

  Map<String, Object?> toJson({bool includeFreeText = false}) =>
      <String, Object?>{
        'regionId': regionId,
        'sideDetail': sideDetail?.name,
        'painIntensity': painIntensity,
        'duration': duration?.name,
        'sensations': sensations.map((e) => e.name).toList(),
        'onset': onset?.name,
        'movementWorsens': movementWorsens,
        'impacts': impacts.map((e) => e.name).toList(),
        'redFlags': redFlags.map((e) => e.name).toList(),
        'redFlagsReviewed': redFlagsReviewed,
        'ageRange': ageRange?.name,
        'limitations': limitations.map((e) => e.name).toList(),
        'conditions': conditions.map((e) => e.name).toList(),
        'dietPreference': dietPreference?.name,
        'allergens': allergens.map((e) => e.name).toList(),
        'restrictions': restrictions.map((e) => e.name).toList(),
        if (includeFreeText) 'additionalDetails': additionalDetails,
      };

  factory Assessment.fromJson(Map<String, Object?> json) => Assessment(
        regionId: json['regionId'] as String?,
        sideDetail: _enumByName(SideDetail.values, json['sideDetail']),
        painIntensity: json['painIntensity'] as int?,
        duration: _enumByName(PainDuration.values, json['duration']),
        sensations: _enumSetByNames(PainSensation.values, json['sensations']),
        onset: _enumByName(Onset.values, json['onset']),
        movementWorsens: json['movementWorsens'] as bool?,
        impacts: _enumSetByNames(ImpactArea.values, json['impacts']),
        redFlags: _enumSetByNames(RedFlag.values, json['redFlags']),
        redFlagsReviewed: json['redFlagsReviewed'] as bool? ?? false,
        additionalDetails: json['additionalDetails'] as String? ?? '',
        ageRange: _enumByName(AgeRange.values, json['ageRange']),
        limitations:
            _enumSetByNames(ExerciseLimitation.values, json['limitations']),
        conditions: _enumSetByNames(HealthCondition.values, json['conditions']),
        dietPreference:
            _enumByName(DietPreference.values, json['dietPreference']),
        allergens: _enumSetByNames(Allergen.values, json['allergens']),
        restrictions:
            _enumSetByNames(DietaryRestriction.values, json['restrictions']),
      );
}

T? enumByName<T extends Enum>(List<T> values, Object? name) =>
    _enumByName(values, name);

Set<T> enumSetByNames<T extends Enum>(List<T> values, Object? raw) =>
    _enumSetByNames(values, raw);
