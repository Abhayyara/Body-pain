enum SafetyState {
  emergencyGuidance('emergency_guidance'),
  clinicalAssessmentRecommended('clinical_assessment_recommended'),
  generalWellnessEligible('general_wellness_eligible'),
  insufficientInformation('insufficient_information');

  const SafetyState(this.id);
  final String id;

  static SafetyState? fromId(String? id) {
    for (final s in SafetyState.values) {
      if (s.id == id) return s;
    }
    return null;
  }
}

enum RuleSeverity { emergency, clinical, information }

class SafetyRuleHit {
  const SafetyRuleHit({
    required this.ruleId,
    required this.severity,
    required this.message,
  });

  final String ruleId;
  final RuleSeverity severity;
  final String message;
}

class SafetyResult {
  const SafetyResult({
    required this.state,
    required this.headline,
    required this.guidance,
    this.hits = const <SafetyRuleHit>[],
    this.notes = const <String>[],
  });

  final SafetyState state;
  final String headline;
  final String guidance;
  final List<SafetyRuleHit> hits;
  final List<String> notes;

  bool get allowsRecommendations =>
      state == SafetyState.generalWellnessEligible;

  Set<String> get ruleIds => hits.map((h) => h.ruleId).toSet();
}
