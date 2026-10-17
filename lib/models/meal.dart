import 'assessment.dart';

enum MealType {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snack');

  const MealType(this.label);
  final String label;
}

class Meal {
  const Meal({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.reviewedSource,
    this.containsMeat = false,
    this.containsFish = false,
    this.containsEgg = false,
    this.containsDairy = false,
    this.containsOnionGarlic = false,
    this.allergens = const <Allergen>{},
    this.reviewDate,
  });

  final String id;
  final MealType type;
  final String name;
  final String description;
  final bool containsMeat;
  final bool containsFish;
  final bool containsEgg;
  final bool containsDairy;
  final bool containsOnionGarlic;
  final Set<Allergen> allergens;
  final String reviewedSource;
  final DateTime? reviewDate;

  bool get isClinicallyReviewed => reviewDate != null;

  /// Declared allergens plus those implied by the ingredient flags.
  Set<Allergen> get allAllergens => <Allergen>{
        ...allergens,
        if (containsEgg) Allergen.eggs,
        if (containsDairy) Allergen.dairy,
        if (containsFish) Allergen.fish,
      };
}
