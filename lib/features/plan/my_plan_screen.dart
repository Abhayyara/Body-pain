import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../data/nutrition.dart';
import '../../models/exercise.dart';
import '../../models/meal.dart';
import '../../widgets/common.dart';
import '../../widgets/plan_widgets.dart';
import '../home/app_shell.dart';

class MyPlanScreen extends StatelessWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final plan = c.savedPlan;
    final region = plan == null ? null : c.anatomy.byId(plan.regionId);

    final children = <Widget>[
      Text('My Plan',
          style: text.headlineSmall?.copyWith(
              color: AppColors.deepBlue, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
    ];

    if (plan == null || region == null) {
      children.addAll(<Widget>[
        const AppCard(
          child: Text('You have not saved a plan yet. Choose a body area, '
              'answer a few questions, and save the suggestions you get.'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => c.goToTab(AppShell.exploreTab),
          child: const Text('Explore your body'),
        ),
      ]);
    } else {
      final exercises = <Exercise>[
        for (final id in plan.exerciseIds)
          if (exerciseById(id) != null) exerciseById(id)!,
      ];
      final meals = <MealType, List<Meal>>{};
      for (final id in plan.mealIds) {
        final m = mealById(id);
        if (m != null) meals.putIfAbsent(m.type, () => <Meal>[]).add(m);
      }
      children.addAll(<Widget>[
        AppCard(
          child: Text('Saved plan for: ${region.label}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Today'),
        const AppCard(child: HydrationTracker()),
        const SizedBox(height: 16),
        const SectionTitle('Movement'),
        if (exercises.isEmpty)
          const AppCard(child: Text('No exercises in this plan.'))
        else
          for (final e in exercises) ExerciseCard(exercise: e),
        const SizedBox(height: 8),
        const SectionTitle('Nutrition ideas'),
        AppCard(child: MealsByType(mealsByType: meals)),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => c.clearSavedPlan(),
          child: const Text('Remove saved plan'),
        ),
      ]);
    }
    children.addAll(const <Widget>[
      SizedBox(height: 20),
      DisclaimerBanner(),
    ]);
    return ListView(padding: const EdgeInsets.all(20), children: children);
  }
}
