import 'package:bodywise3d/models/assessment.dart';

/// A complete, low-risk assessment that the safety engine should clear.
Assessment baseAssessment({
  String regionId = 'left_knee',
  int pain = 3,
  PainDuration duration = PainDuration.fourToFourteenDays,
  Set<PainSensation>? sensations,
  Onset onset = Onset.gradual,
  bool movementWorsens = false,
  Set<ImpactArea>? impacts,
  AgeRange ageRange = AgeRange.age40to59,
}) {
  return Assessment(
    regionId: regionId,
    painIntensity: pain,
    duration: duration,
    sensations: sensations ?? <PainSensation>{PainSensation.aching},
    onset: onset,
    movementWorsens: movementWorsens,
    impacts: impacts ?? <ImpactArea>{},
    redFlagsReviewed: true,
    ageRange: ageRange,
  );
}
