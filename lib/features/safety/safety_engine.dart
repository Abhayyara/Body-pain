import '../../data/body_regions.dart';
import '../../models/assessment.dart';
import '../../models/safety.dart';

/// Deterministic safety screening. Runs BEFORE any recommendation or AI call
/// and can never be overridden by them.
///
/// Precedence (most cautious wins):
///   emergency_guidance > clinical_assessment_recommended
///   > insufficient_information > general_wellness_eligible
///
/// Every rule below is a PLACEHOLDER pending review by a qualified clinician.
/// See docs/SAFETY_RULES.md. A negative result is never proof of safety.
class SafetyEngine {
  const SafetyEngine();

  static const String disclaimer =
      'This application provides general wellness information and does not '
      'diagnose medical conditions or replace professional medical care.';

  static const String emergencyGuidance =
      'Please contact your local emergency services now (for example 112 in '
      'India or the EU, 911 in the US, 999 in the UK) or go to the nearest '
      'emergency department. Do not wait for symptoms to settle and do not '
      'drive yourself if you feel unwell. This app will not show exercises or '
      'diet suggestions in this situation.';

  static const String crisisGuidance =
      'You deserve support right now. Please contact your local emergency '
      'number or a crisis helpline, or reach out to someone you trust and '
      'stay with them. This app cannot provide the help you need here.';

  static const String clinicalGuidance =
      'Based on your answers, we recommend that a qualified healthcare '
      'professional assesses this soon. This app will not suggest exercises '
      'or diet changes for this pain. Seek urgent care if you develop any '
      'warning sign listed below.';

  static const List<String> warningSignsToWatch = <String>[
    'Pain that is getting worse, or is not improving after a couple of weeks',
    'New numbness, tingling, or weakness in an arm or leg',
    'Fever, unexplained weight loss, or pain that wakes you at night',
    'Swelling, redness, or heat in a joint',
    'Trouble walking, balance problems, or loss of bladder or bowel control',
    'Chest pain, difficulty breathing, face drooping, or slurred speech: '
        'get emergency help immediately',
  ];

  static final Set<String> _knownRegionIds =
      kBodyRegions.map((r) => r.id).toSet();

  static const Map<RedFlag, String> _redFlagRuleIds = <RedFlag, String>{
    RedFlag.chestPainWithBreathlessness: 'E1',
    RedFlag.faceDroopOrSpeechTrouble: 'E2',
    RedFlag.majorTraumaOrDeformity: 'E3',
    RedFlag.bladderBowelOrGroinNumbness: 'E4',
    RedFlag.hotSwollenJointWithFever: 'E5',
    RedFlag.severeBreathingDifficulty: 'E6',
    RedFlag.suddenSevereHeadache: 'E7',
  };

  static const List<String> _breathingTerms = <String>[
    "can't breathe",
    'cant breathe',
    'cannot breathe',
    'unable to breathe',
    'struggling to breathe',
    'unconscious',
    'passed out',
    'collapsed',
  ];

  static const List<String> _selfHarmTerms = <String>[
    'suicid',
    'kill myself',
    'end my life',
    'self-harm',
    'self harm',
    'hurt myself',
  ];

  static const List<String> _concerningTerms = <String>[
    'fever',
    'lump',
    'weight loss',
    'night sweats',
    'cannot move',
    "can't move",
    'cannot walk',
    "can't walk",
    'broken',
    'fracture',
    'dislocat',
    'weakness',
  ];

  SafetyResult evaluate(Assessment a) {
    final emergency = _emergencyHits(a);
    if (emergency.isNotEmpty) {
      final onlyCrisis = emergency.every((h) => h.ruleId == 'E9');
      final hasCrisis = emergency.any((h) => h.ruleId == 'E9');
      return SafetyResult(
        state: SafetyState.emergencyGuidance,
        headline: onlyCrisis
            ? 'Please reach out for support now'
            : 'Get urgent medical help now',
        guidance: onlyCrisis
            ? crisisGuidance
            : (hasCrisis
                ? '$emergencyGuidance\n\n$crisisGuidance'
                : emergencyGuidance),
        hits: emergency,
      );
    }

    final clinical = _clinicalHits(a);
    if (clinical.isNotEmpty) {
      return SafetyResult(
        state: SafetyState.clinicalAssessmentRecommended,
        headline: 'A professional assessment is recommended',
        guidance: clinicalGuidance,
        hits: clinical,
      );
    }

    final missing = _informationHits(a);
    if (missing.isNotEmpty) {
      return SafetyResult(
        state: SafetyState.insufficientInformation,
        headline: 'We need a little more information',
        guidance: 'Please complete or correct the items below so the safety '
            'check can run before any suggestions are shown.',
        hits: missing,
      );
    }

    return const SafetyResult(
      state: SafetyState.generalWellnessEligible,
      headline: 'General wellness suggestions are available',
      guidance: 'No warning signs were identified from the answers you gave.',
      notes: <String>[
        'This is not proof that you are safe or that nothing is wrong.',
        'Stop and seek advice if symptoms worsen or new symptoms appear.',
      ],
    );
  }

  List<SafetyRuleHit> _emergencyHits(Assessment a) {
    final hits = <SafetyRuleHit>[];
    for (final flag in a.redFlags) {
      hits.add(SafetyRuleHit(
        ruleId: _redFlagRuleIds[flag]!,
        severity: RuleSeverity.emergency,
        message: flag.label,
      ));
    }
    final text = a.additionalDetails.toLowerCase();
    if (_containsAny(text, _breathingTerms)) {
      hits.add(const SafetyRuleHit(
        ruleId: 'E8',
        severity: RuleSeverity.emergency,
        message: 'Your notes mention trouble breathing or collapsing',
      ));
    }
    if (_containsAny(text, _selfHarmTerms)) {
      hits.add(const SafetyRuleHit(
        ruleId: 'E9',
        severity: RuleSeverity.emergency,
        message: 'Your notes mention thoughts of harming yourself',
      ));
    }
    return hits;
  }

  List<SafetyRuleHit> _clinicalHits(Assessment a) {
    final hits = <SafetyRuleHit>[];
    void add(String id, String message) => hits.add(SafetyRuleHit(
        ruleId: id, severity: RuleSeverity.clinical, message: message));

    final pain = a.painIntensity;
    final region = a.regionId;

    if (pain != null && pain >= 8) {
      add('C1', 'Severe pain (8 or more out of 10)');
    }
    if (a.onset == Onset.afterInjury && pain != null && pain >= 4) {
      add('C2', 'Pain that began after an injury');
    }
    if (a.sensations.contains(PainSensation.numbness)) {
      add('C3', 'Numbness');
    }
    if (a.sensations.contains(PainSensation.tingling) &&
        a.duration != null &&
        a.duration!.index >= PainDuration.fourToFourteenDays.index) {
      add('C4', 'Tingling lasting several days');
    }
    if (a.duration == PainDuration.moreThanFourteenDays &&
        pain != null &&
        pain >= 4) {
      add('C5', 'Pain lasting more than two weeks');
    }
    if (pain != null && pain >= 6 && a.impacts.isNotEmpty) {
      add('C6', 'Significant pain that affects daily life');
    }
    if (a.onset == Onset.sudden && pain != null && pain >= 6) {
      add('C7', 'Sudden, significant pain');
    }
    if (region == 'chest' && pain != null && pain > 0) {
      add('C8', 'Chest pain should be assessed by a professional');
    }
    if (region == 'abdomen' &&
        pain != null &&
        (pain >= 6 || a.onset == Onset.sudden)) {
      add('C9', 'Significant or sudden abdominal pain');
    }
    if (a.ageRange == AgeRange.under18) {
      add('C10', 'Advice for under-18s should come from a doctor or guardian');
    }
    if (a.conditions.contains(HealthCondition.recentSurgery)) {
      add('C11', "Recent surgery: follow your surgical team's advice");
    }
    if (_containsAny(a.additionalDetails.toLowerCase(), _concerningTerms)) {
      add('C12', 'Your notes mention a symptom that needs professional review');
    }
    const heartLinked = <String>{'jaw', 'left_shoulder', 'left_upper_arm'};
    if (a.conditions.contains(HealthCondition.heartCondition) &&
        region != null &&
        heartLinked.contains(region) &&
        pain != null &&
        pain > 0) {
      add('C13',
          'Pain in this area together with a heart condition should be checked');
    }
    return hits;
  }

  List<SafetyRuleHit> _informationHits(Assessment a) {
    final hits = <SafetyRuleHit>[];
    void add(String id, String message) => hits.add(SafetyRuleHit(
        ruleId: id, severity: RuleSeverity.information, message: message));

    if (a.regionId == null || !_knownRegionIds.contains(a.regionId)) {
      add('I1', 'Select the body area where you feel pain');
    }
    final pain = a.painIntensity;
    if (pain == null) {
      add('I2', 'Choose a pain intensity from 0 to 10');
    } else if (pain < kMinPainIntensity || pain > kMaxPainIntensity) {
      add('I3', 'Pain intensity must be between 0 and 10');
    }
    if (a.duration == null) add('I4', 'Tell us how long the pain has lasted');
    if (a.sensations.isEmpty) add('I5', 'Choose how the pain feels');
    if (a.onset == null) add('I6', 'Tell us how the pain started');
    if (a.movementWorsens == null) {
      add('I7', 'Tell us whether movement makes it worse');
    }
    if (!a.redFlagsReviewed && a.redFlags.isEmpty) {
      add('I8', 'Complete the warning-signs check');
    }
    if (pain == 0 && (a.movementWorsens == true || a.impacts.isNotEmpty)) {
      add('I9',
          'You rated pain 0 but also said it affects movement or daily life. '
          'Please review these answers.');
    }
    return hits;
  }

  static bool _containsAny(String text, List<String> terms) {
    if (text.isEmpty) return false;
    for (final t in terms) {
      if (text.contains(t)) return true;
    }
    return false;
  }
}
