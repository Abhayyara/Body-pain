import 'package:bodywise3d/features/safety/safety_engine.dart';
import 'package:bodywise3d/models/assessment.dart';
import 'package:bodywise3d/models/safety.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  const engine = SafetyEngine();

  test('a low-risk complete assessment is eligible, with a caution note', () {
    final r = engine.evaluate(baseAssessment());
    expect(r.state, SafetyState.generalWellnessEligible);
    expect(r.allowsRecommendations, isTrue);
    expect(r.notes.join(' '), contains('not proof'));
  });

  group('emergency red flags', () {
    const expectedRule = <RedFlag, String>{
      RedFlag.chestPainWithBreathlessness: 'E1',
      RedFlag.faceDroopOrSpeechTrouble: 'E2',
      RedFlag.majorTraumaOrDeformity: 'E3',
      RedFlag.bladderBowelOrGroinNumbness: 'E4',
      RedFlag.hotSwollenJointWithFever: 'E5',
      RedFlag.severeBreathingDifficulty: 'E6',
      RedFlag.suddenSevereHeadache: 'E7',
    };

    for (final flag in RedFlag.values) {
      test('${flag.name} triggers emergency_guidance', () {
        final a = baseAssessment()..redFlags.add(flag);
        final r = engine.evaluate(a);
        expect(r.state, SafetyState.emergencyGuidance);
        expect(r.allowsRecommendations, isFalse);
        expect(r.ruleIds, contains(expectedRule[flag]));
        expect(r.guidance, contains('emergency'));
      });
    }

    test('every red flag has a rule id', () {
      expect(expectedRule.keys.toSet(), RedFlag.values.toSet());
    });

    test('emergency wins even when the assessment is otherwise empty', () {
      final a = Assessment()..redFlags.add(RedFlag.faceDroopOrSpeechTrouble);
      expect(engine.evaluate(a).state, SafetyState.emergencyGuidance);
    });

    test('emergency wins over clinical triggers', () {
      final a = baseAssessment(pain: 9)
        ..redFlags.add(RedFlag.severeBreathingDifficulty);
      expect(engine.evaluate(a).state, SafetyState.emergencyGuidance);
    });

    test('breathing terms in free text trigger emergency', () {
      final a = baseAssessment()..additionalDetails = "I can't breathe well";
      final r = engine.evaluate(a);
      expect(r.state, SafetyState.emergencyGuidance);
      expect(r.ruleIds, contains('E8'));
    });

    test('self-harm terms get crisis guidance, not the pain guidance', () {
      final a = baseAssessment()..additionalDetails = 'I want to kill myself';
      final r = engine.evaluate(a);
      expect(r.state, SafetyState.emergencyGuidance);
      expect(r.ruleIds, contains('E9'));
      expect(r.guidance, contains('support'));
      expect(r.guidance, isNot(contains('nearest emergency department')));
    });
  });

  group('clinical assessment recommended', () {
    void expectClinical(Assessment a, String rule) {
      final r = engine.evaluate(a);
      expect(r.state, SafetyState.clinicalAssessmentRecommended, reason: rule);
      expect(r.ruleIds, contains(rule));
      expect(r.allowsRecommendations, isFalse);
    }

    test('C1 severe pain', () => expectClinical(baseAssessment(pain: 8), 'C1'));
    test('C1 boundary: 7 does not fire C1', () {
      expect(engine.evaluate(baseAssessment(pain: 7)).ruleIds,
          isNot(contains('C1')));
    });
    test('C2 injury with notable pain',
        () => expectClinical(baseAssessment(pain: 4, onset: Onset.afterInjury), 'C2'));
    test(
        'C3 numbness',
        () => expectClinical(
            baseAssessment(sensations: {PainSensation.numbness}), 'C3'));
    test(
        'C4 persistent tingling',
        () => expectClinical(
            baseAssessment(sensations: {PainSensation.tingling}), 'C4'));
    test('tingling for under 4 days does not fire C4', () {
      final r = engine.evaluate(baseAssessment(
        sensations: {PainSensation.tingling},
        duration: PainDuration.oneToThreeDays,
      ));
      expect(r.ruleIds, isNot(contains('C4')));
    });
    test(
        'C5 persistent pain',
        () => expectClinical(
            baseAssessment(
                pain: 4, duration: PainDuration.moreThanFourteenDays),
            'C5'));
    test(
        'C6 severe-ish pain affecting daily life',
        () => expectClinical(
            baseAssessment(pain: 6, impacts: {ImpactArea.sleep}), 'C6'));
    test('C7 sudden significant pain',
        () => expectClinical(baseAssessment(pain: 6, onset: Onset.sudden), 'C7'));
    test('C8 any chest pain',
        () => expectClinical(baseAssessment(regionId: 'chest', pain: 1), 'C8'));
    test('C9 sudden abdominal pain',
        () => expectClinical(
            baseAssessment(regionId: 'abdomen', pain: 2, onset: Onset.sudden),
            'C9'));
    test('C10 under 18',
        () => expectClinical(baseAssessment(ageRange: AgeRange.under18), 'C10'));
    test('C11 recent surgery', () {
      final a = baseAssessment()..conditions.add(HealthCondition.recentSurgery);
      expectClinical(a, 'C11');
    });
    test('C12 concerning words in notes', () {
      final a = baseAssessment()..additionalDetails = 'I have had a fever';
      expectClinical(a, 'C12');
    });
    test('C13 heart condition with left shoulder pain', () {
      final a = baseAssessment(regionId: 'left_shoulder')
        ..conditions.add(HealthCondition.heartCondition);
      expectClinical(a, 'C13');
    });
    test('clinical wins over missing information', () {
      final a = Assessment(regionId: 'left_knee', painIntensity: 9);
      expect(engine.evaluate(a).state,
          SafetyState.clinicalAssessmentRecommended);
    });
  });

  group('insufficient or conflicting information', () {
    test('empty assessment is insufficient', () {
      final r = engine.evaluate(Assessment());
      expect(r.state, SafetyState.insufficientInformation);
      expect(r.ruleIds,
          containsAll(<String>['I1', 'I2', 'I4', 'I5', 'I6', 'I7', 'I8']));
      expect(r.allowsRecommendations, isFalse);
    });

    test('warning-signs check not completed is insufficient', () {
      final a = baseAssessment()..redFlagsReviewed = false;
      final r = engine.evaluate(a);
      expect(r.state, SafetyState.insufficientInformation);
      expect(r.ruleIds, contains('I8'));
    });

    test('out-of-range pain is never eligible', () {
      for (final bad in <int>[-1, 11]) {
        final a = baseAssessment()..painIntensity = bad;
        final r = engine.evaluate(a);
        expect(r.state, isNot(SafetyState.generalWellnessEligible),
            reason: '$bad');
      }
    });

    test('I3: negative pain is flagged as invalid input', () {
      final r = engine.evaluate(baseAssessment()..painIntensity = -1);
      expect(r.state, SafetyState.insufficientInformation);
      expect(r.ruleIds, contains('I3'));
    });

    test('unknown region is insufficient', () {
      final r = engine.evaluate(baseAssessment(regionId: 'tail'));
      expect(r.state, SafetyState.insufficientInformation);
      expect(r.ruleIds, contains('I1'));
    });

    test('pain 0 with movement pain is conflicting', () {
      final a = baseAssessment(pain: 0, movementWorsens: true);
      final r = engine.evaluate(a);
      expect(r.state, SafetyState.insufficientInformation);
      expect(r.ruleIds, contains('I9'));
    });

    test('pain 0 with no conflicts is accepted', () {
      expect(engine.evaluate(baseAssessment(pain: 0)).state,
          SafetyState.generalWellnessEligible);
    });
  });

  test('SafetyState ids match the specification', () {
    expect(SafetyState.emergencyGuidance.id, 'emergency_guidance');
    expect(SafetyState.clinicalAssessmentRecommended.id,
        'clinical_assessment_recommended');
    expect(SafetyState.generalWellnessEligible.id, 'general_wellness_eligible');
    expect(SafetyState.insufficientInformation.id, 'insufficient_information');
    expect(SafetyState.fromId('nope'), isNull);
  });
}
