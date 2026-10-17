import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/plan.dart';
import '../../models/safety.dart';
import '../../widgets/common.dart';
import '../../widgets/plan_widgets.dart';
import '../home/app_shell.dart';
import '../safety/safety_engine.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final plan = c.latestPlan;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your results'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              c.goToTab(AppShell.homeTab);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: plan == null
          ? const Center(child: Text('No results yet.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _sections(context, plan),
            ),
    );
  }

  List<Widget> _sections(BuildContext context, RecommendationPlan plan) {
    switch (plan.safety.state) {
      case SafetyState.emergencyGuidance:
        return _emergency(context, plan);
      case SafetyState.clinicalAssessmentRecommended:
        return _clinical(context, plan);
      case SafetyState.insufficientInformation:
        return _insufficient(context, plan);
      case SafetyState.generalWellnessEligible:
        return _eligible(context, plan);
    }
  }

  // ---- emergency: nothing else is shown -----------------------------------
  List<Widget> _emergency(BuildContext context, RecommendationPlan plan) {
    final text = Theme.of(context).textTheme;
    return <Widget>[
      AppCard(
        key: const Key('emergency_card'),
        color: AppColors.dangerLight,
        borderColor: AppColors.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 36),
            const SizedBox(height: 8),
            Text(plan.safety.headline,
                style: text.headlineSmall?.copyWith(
                    color: AppColors.danger, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(plan.safety.guidance, style: text.bodyLarge),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const SectionTitle('Why you are seeing this'),
      for (final h in plan.safety.hits)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• ${h.message}'),
        ),
      const SizedBox(height: 20),
      const DisclaimerBanner(),
    ];
  }

  // ---- clinical assessment recommended: sections A and E only --------------
  List<Widget> _clinical(BuildContext context, RecommendationPlan plan) {
    return <Widget>[
      _assessmentCard(context, plan),
      const SizedBox(height: 16),
      AppCard(
        key: const Key('clinical_card'),
        color: AppColors.warningLight,
        borderColor: AppColors.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(plan.safety.headline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(plan.safety.guidance),
            const SizedBox(height: 8),
            const Text('Why:'),
            for (final h in plan.safety.hits) Text('• ${h.message}'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _nextSteps(context),
      const SizedBox(height: 20),
      const DisclaimerBanner(),
    ];
  }

  List<Widget> _insufficient(BuildContext context, RecommendationPlan plan) {
    return <Widget>[
      AppCard(
        key: const Key('insufficient_card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(plan.safety.headline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.deepBlue, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(plan.safety.guidance),
            const SizedBox(height: 8),
            for (final h in plan.safety.hits) Text('• ${h.message}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.assessment),
              child: const Text('Edit my answers'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const DisclaimerBanner(),
    ];
  }

  // ---- eligible: sections A-E ------------------------------------------------
  List<Widget> _eligible(BuildContext context, RecommendationPlan plan) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    return <Widget>[
      if (plan.contentNotice != null) ...<Widget>[
        NoticeBanner(message: plan.contentNotice!),
        const SizedBox(height: 12),
      ],
      _assessmentCard(context, plan),
      const SizedBox(height: 16),
      const SectionTitle('B. Your movement plan'),
      if (plan.exercises.isEmpty)
        AppCard(
          child: Text(plan.noExerciseMessage ??
              'No exercises are available for this area.'),
        )
      else
        for (final e in plan.exercises) ExerciseCard(exercise: e),
      const SizedBox(height: 8),
      const SectionTitle('C. Nutrition guidance'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final n in plan.nutritionNotes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(n, style: text.bodyMedium),
              ),
            MealsByType(mealsByType: plan.mealsByType),
            if (plan.hydrationNote != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(plan.hydrationNote!, style: text.bodySmall),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      const SectionTitle('D. Daily wellness'),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            HydrationTracker(),
            SizedBox(height: 8),
            Text('Tip: change position and take a short movement break about '
                'once an hour. Tick exercises as "Done today" above.'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _nextSteps(context),
      const SizedBox(height: 16),
      if (plan.exercises.isNotEmpty || plan.mealsByType.isNotEmpty)
        FilledButton.icon(
          key: const Key('save_plan_button'),
          onPressed: () async {
            await c.savePlan();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plan saved on this device.')),
            );
          },
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save this plan'),
        ),
      const SizedBox(height: 20),
      const DisclaimerBanner(),
    ];
  }

  Widget _assessmentCard(BuildContext context, RecommendationPlan plan) {
    final a = plan.assessment;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('A. Your assessment'),
          Text('Area: ${plan.regionLabel ?? '-'}'),
          Text('Pain: ${a.painIntensity ?? '-'} out of 10'),
          Text('Lasting: ${a.duration?.label ?? '-'}'),
          const SizedBox(height: 8),
          for (final n in plan.safety.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(n, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _nextSteps(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle('E. Next steps'),
          const Text('See a healthcare professional if you notice:'),
          const SizedBox(height: 6),
          for (final s in SafetyEngine.warningSignsToWatch)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $s'),
            ),
        ],
      ),
    );
  }
}
