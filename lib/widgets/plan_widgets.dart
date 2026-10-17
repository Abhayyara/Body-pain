import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/theme.dart';
import '../models/exercise.dart';
import '../models/meal.dart';
import 'common.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, this.trackable = true});

  final Exercise exercise;
  final bool trackable;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final done = c.isCompletedToday(exercise.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: PageStorageKey<String>('exercise_${exercise.id}'),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(exercise.name,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text('${exercise.difficulty.label} · '
              '${exercise.posture.label} · ${exercise.repetitionsOrDuration}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!exercise.isClinicallyReviewed) ...<Widget>[
              const NoticeBanner(
                message: 'Draft content: not yet reviewed by a clinician.',
              ),
              const SizedBox(height: 8),
            ],
            Text(exercise.purpose),
            const SizedBox(height: 10),
            Text('How to do it',
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            for (var i = 0; i < exercise.instructions.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${i + 1}. ${exercise.instructions[i]}'),
              ),
            if (exercise.equipment.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text('You will need: ${exercise.equipment.join(', ')}'),
            ],
            const SizedBox(height: 10),
            Text('Easier options',
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            for (final m in exercise.modifications)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $m'),
              ),
            const SizedBox(height: 10),
            Text('Stop and seek advice if',
                style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.danger)),
            for (final s in exercise.stopConditions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $s'),
              ),
            if (trackable) ...<Widget>[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Done today'),
                value: done,
                onChanged: (_) => c.toggleExercise(exercise.id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MealsByType extends StatelessWidget {
  const MealsByType({super.key, required this.mealsByType});

  final Map<MealType, List<Meal>> mealsByType;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final type in MealType.values)
          if (mealsByType[type]?.isNotEmpty ?? false) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(type.label,
                  style:
                      text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final m in mealsByType[type]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                          text: m.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' - ${m.description}'),
                    ],
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class HydrationTracker extends StatelessWidget {
  const HydrationTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return Row(
      children: <Widget>[
        const Icon(Icons.water_drop_outlined, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(child: Text('Water today: ${c.waterToday} glasses')),
        IconButton(
          tooltip: 'Remove a glass',
          onPressed: c.waterToday == 0 ? null : () => c.changeWater(-1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          key: const Key('add_water_button'),
          tooltip: 'Add a glass',
          onPressed: () => c.changeWater(1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
