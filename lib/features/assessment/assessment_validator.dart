import '../../data/body_regions.dart';
import '../../models/assessment.dart';

/// Validates questionnaire steps. Only fields needed for a safe result are
/// required; everything personal is optional.
class AssessmentValidator {
  const AssessmentValidator._();

  static const int stepCount = 6;
  static const int regionStep = 0;
  static const int painStep = 1;
  static const int impactStep = 2;
  static const int warningStep = 3;
  static const int aboutStep = 4;
  static const int reviewStep = 5;
  static const int maxDetailsLength = 500;

  static final Set<String> _knownRegions =
      kBodyRegions.map((r) => r.id).toSet();

  static List<String> validateStep(Assessment a, int step) {
    final errors = <String>[];
    switch (step) {
      case regionStep:
        if (a.regionId == null || !_knownRegions.contains(a.regionId)) {
          errors.add('Please choose the body area where you feel pain.');
        }
      case painStep:
        final p = a.painIntensity;
        if (p == null) {
          errors.add('Please choose a pain intensity from 0 to 10.');
        } else if (p < kMinPainIntensity || p > kMaxPainIntensity) {
          errors.add('Pain intensity must be between 0 and 10.');
        }
        if (a.duration == null) {
          errors.add('Please tell us how long the pain has lasted.');
        }
        if (a.sensations.isEmpty) {
          errors.add('Please choose at least one way the pain feels.');
        }
        if (a.onset == null) {
          errors.add('Please tell us how the pain started.');
        }
      case impactStep:
        if (a.movementWorsens == null) {
          errors.add('Please tell us whether movement makes the pain worse.');
        }
      case warningStep:
        if (!a.redFlagsReviewed && a.redFlags.isEmpty) {
          errors.add('Please tick any warning signs that apply, or confirm '
              'that none of them do.');
        }
      case aboutStep:
        if (a.additionalDetails.length > maxDetailsLength) {
          errors.add('Additional details must be $maxDetailsLength characters '
              'or fewer.');
        }
    }
    return errors;
  }

  static List<String> validateAll(Assessment a) => <String>[
        for (var s = 0; s < stepCount; s++) ...validateStep(a, s),
      ];
}
