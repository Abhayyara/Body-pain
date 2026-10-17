import '../models/assessment.dart';
import '../models/meal.dart';

// DRAFT CONTENT: general balanced-meal ideas, not clinician or dietitian
// reviewed (reviewDate == null). No meal here is claimed to treat pain.

const String _draftSource =
    'DRAFT - not yet reviewed by a dietitian (prototype placeholder)';

const List<Meal> kMeals = <Meal>[
  // Breakfast
  Meal(
    id: 'b_poha',
    type: MealType.breakfast,
    name: 'Vegetable poha with a few peanuts',
    description: 'Flattened rice cooked with vegetables. Add a piece of fruit on the side.',
    containsOnionGarlic: true,
    allergens: <Allergen>{Allergen.peanuts},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'b_moong_chilla',
    type: MealType.breakfast,
    name: 'Moong dal chilla with mint chutney',
    description: 'Savoury lentil pancakes with a fresh herb chutney.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'b_idli_sambar',
    type: MealType.breakfast,
    name: 'Idli with vegetable sambar',
    description: 'Steamed rice-and-lentil cakes with a vegetable lentil stew.',
    containsOnionGarlic: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'b_upma_curd',
    type: MealType.breakfast,
    name: 'Vegetable upma with a small bowl of curd',
    description: 'Semolina cooked with vegetables, served with plain curd.',
    containsDairy: true,
    containsOnionGarlic: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'b_egg_bhurji',
    type: MealType.breakfast,
    name: 'Egg bhurji with a whole-wheat roti',
    description: 'Scrambled eggs with vegetables and one roti.',
    containsEgg: true,
    containsOnionGarlic: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'b_boiled_egg_toast',
    type: MealType.breakfast,
    name: 'Boiled egg, whole-grain toast and a fruit',
    description: 'A simple, quick breakfast.',
    containsEgg: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  // Lunch
  Meal(
    id: 'l_dal_rice_veg',
    type: MealType.lunch,
    name: 'Dal, rice, seasonal vegetables and salad',
    description: 'Plain dal tempered with cumin, steamed rice, a vegetable side and a fresh salad.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'l_dal_roti_curd',
    type: MealType.lunch,
    name: 'Dal, roti, sabzi, salad and curd',
    description: 'A classic balanced thali-style plate.',
    containsDairy: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'l_khichdi_curd',
    type: MealType.lunch,
    name: 'Vegetable khichdi with curd',
    description: 'Rice and lentils cooked with vegetables and mild spices.',
    containsDairy: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'l_rajma_rice',
    type: MealType.lunch,
    name: 'Rajma or chole with rice and cucumber salad',
    description: 'Beans or chickpeas in a light gravy with rice and a cooling salad.',
    containsOnionGarlic: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'l_fish_rice',
    type: MealType.lunch,
    name: 'Fish curry (light gravy) with rice and vegetables',
    description: 'Fish cooked with a light, not-too-oily gravy.',
    containsFish: true,
    containsOnionGarlic: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'l_chicken_roti',
    type: MealType.lunch,
    name: 'Chicken curry (light gravy) with roti and salad',
    description: 'A lean protein option with a vegetable salad.',
    containsMeat: true,
    containsOnionGarlic: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  // Dinner
  Meal(
    id: 'd_veg_dal_roti',
    type: MealType.dinner,
    name: 'Mixed-vegetable dal with one or two rotis',
    description: 'A light dinner with lentils and vegetables.',
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_lauki_dal_rice',
    type: MealType.dinner,
    name: 'Lauki or tori sabzi with dal and rice',
    description: 'Gently spiced gourd curry with dal and a small portion of rice.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_paneer_roti',
    type: MealType.dinner,
    name: 'Paneer bhurji with roti and sauteed vegetables',
    description: 'Crumbled paneer with vegetables and one roti.',
    containsDairy: true,
    containsOnionGarlic: true,
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_daliya',
    type: MealType.dinner,
    name: 'Vegetable daliya (broken wheat) with lentils',
    description: 'A warm, filling one-pot meal.',
    allergens: <Allergen>{Allergen.gluten},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_egg_curry',
    type: MealType.dinner,
    name: 'Egg curry with rice and vegetables',
    description: 'Eggs in a light gravy with rice and a vegetable side.',
    containsEgg: true,
    containsOnionGarlic: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_fish_veg',
    type: MealType.dinner,
    name: 'Lightly spiced fish with steamed vegetables',
    description: 'Grilled or pan-seared fish with plenty of vegetables.',
    containsFish: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 'd_chicken_veg',
    type: MealType.dinner,
    name: 'Grilled chicken with sauteed vegetables and a little rice',
    description: 'A lean protein dinner with vegetables.',
    containsMeat: true,
    reviewedSource: _draftSource,
  ),
  // Snacks
  Meal(
    id: 's_roasted_chana',
    type: MealType.snack,
    name: 'Roasted chana',
    description: 'A small handful of roasted chickpeas.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_fruit',
    type: MealType.snack,
    name: 'Fresh seasonal fruit',
    description: 'One or two portions of whole fruit.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_sprouts',
    type: MealType.snack,
    name: 'Sprouts salad with lemon',
    description: 'Steamed or raw sprouts with chopped cucumber, tomato and lemon.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_makhana',
    type: MealType.snack,
    name: 'Lightly roasted makhana (fox nuts)',
    description: 'Dry-roasted with a pinch of spice.',
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_curd_fruit',
    type: MealType.snack,
    name: 'Plain curd with fruit',
    description: 'A small bowl of unsweetened curd with chopped fruit.',
    containsDairy: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_chaas',
    type: MealType.snack,
    name: 'Buttermilk (chaas)',
    description: 'Plain or lightly spiced buttermilk.',
    containsDairy: true,
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_nuts',
    type: MealType.snack,
    name: 'A small handful of mixed nuts',
    description: 'A few almonds and walnuts.',
    allergens: <Allergen>{Allergen.treeNuts},
    reviewedSource: _draftSource,
  ),
  Meal(
    id: 's_boiled_egg',
    type: MealType.snack,
    name: 'Boiled egg',
    description: 'One boiled egg with pepper.',
    containsEgg: true,
    reviewedSource: _draftSource,
  ),
];

Meal? mealById(String id) {
  for (final m in kMeals) {
    if (m.id == id) return m;
  }
  return null;
}
