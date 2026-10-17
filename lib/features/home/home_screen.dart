import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/exercises.dart';
import '../../widgets/common.dart';
import 'app_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final plan = c.savedPlan;
    final region = plan == null ? null : c.anatomy.byId(plan.regionId);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.accessibility_new, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'BodyWise 3D',
              style: text.titleLarge?.copyWith(
                color: AppColors.deepBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome',
          style: text.headlineMedium?.copyWith(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find where it hurts and get gentle, general wellness ideas.',
          style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('explore_button'),
          onPressed: () => c.goToTab(AppShell.exploreTab),
          icon: const Icon(Icons.accessibility_new),
          label: const Text('Explore Your Body'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('start_assessment_button'),
          onPressed: () {
            c.startAssessment();
            Navigator.of(context).pushNamed(AppRoutes.assessment);
          },
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Start Pain Assessment'),
        ),
        const SizedBox(height: 24),
        const SectionTitle('My Wellness Plan'),
        AppCard(
          child: plan == null || region == null
              ? const Text(
                  'You have no saved plan yet. Complete an assessment and '
                  'save the plan to see it here.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(region.label,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${plan.exerciseIds.length} exercises, '
                        '${plan.mealIds.length} meal ideas'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => c.goToTab(AppShell.planTab),
                      child: const Text('Open my plan'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: _QuickCard(
                icon: Icons.self_improvement,
                label: 'Exercises',
                onTap: () => c.goToTab(AppShell.planTab),
                subtitle: '${kExercises.length} in library',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.restaurant_menu,
                label: 'Nutrition',
                onTap: () => c.goToTab(AppShell.planTab),
                subtitle: 'Balanced meals',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.show_chart,
                label: 'Progress',
                onTap: () => c.goToTab(AppShell.progressTab),
                subtitle: 'Pain log',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const DisclaimerBanner(),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, color: AppColors.teal),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
