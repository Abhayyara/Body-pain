import 'package:bodywise3d/features/assessment/assessment_validator.dart';
import 'package:bodywise3d/models/assessment.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('empty assessment fails the required steps', () {
    final a = Assessment();
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.regionStep),
        isNotEmpty);
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.painStep),
        hasLength(4));
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.impactStep),
        hasLength(1));
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.warningStep),
        hasLength(1));
  });

  test('optional step never blocks', () {
    expect(
        AssessmentValidator.validateStep(
            Assessment(), AssessmentValidator.aboutStep),
        isEmpty);
  });

  test('a complete assessment passes every step', () {
    expect(AssessmentValidator.validateAll(baseAssessment()), isEmpty);
  });

  test('pain intensity boundaries', () {
    for (final ok in <int>[0, 5, 10]) {
      final a = baseAssessment(pain: ok);
      expect(AssessmentValidator.validateStep(a, AssessmentValidator.painStep),
          isEmpty,
          reason: '$ok');
    }
    for (final bad in <int>[-1, 11, 100]) {
      final a = baseAssessment()..painIntensity = bad;
      expect(AssessmentValidator.validateStep(a, AssessmentValidator.painStep),
          isNotEmpty,
          reason: '$bad');
    }
  });

  test('unknown region id is rejected', () {
    final a = baseAssessment(regionId: 'tail');
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.regionStep),
        isNotEmpty);
  });

  test('warning-signs step needs a review or a ticked sign', () {
    final a = baseAssessment()..redFlagsReviewed = false;
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.warningStep),
        isNotEmpty);
    a.redFlags.add(RedFlag.severeBreathingDifficulty);
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.warningStep),
        isEmpty);
  });

  test('overlong free text is rejected', () {
    final a = baseAssessment()
      ..additionalDetails = 'x' * (AssessmentValidator.maxDetailsLength + 1);
    expect(AssessmentValidator.validateStep(a, AssessmentValidator.aboutStep),
        isNotEmpty);
  });

  test('json round trip keeps structured answers and drops free text by default',
      () {
    final a = baseAssessment()
      ..additionalDetails = 'secret note'
      ..allergens.add(Allergen.peanuts)
      ..conditions.add(HealthCondition.diabetes);
    final json = a.toJson();
    expect(json.containsKey('additionalDetails'), isFalse);
    final back = Assessment.fromJson(json);
    expect(back.regionId, 'left_knee');
    expect(back.allergens, contains(Allergen.peanuts));
    expect(back.conditions, contains(HealthCondition.diabetes));
    expect(back.additionalDetails, '');
    expect(a.toJson(includeFreeText: true)['additionalDetails'], 'secret note');
  });
}
