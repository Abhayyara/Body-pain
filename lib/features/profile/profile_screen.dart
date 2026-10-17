import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/theme.dart';
import '../../models/assessment.dart';
import '../../models/records.dart';
import '../../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final p = c.preferences;

    UserPreferences copy() => UserPreferences(
          ageRange: p.ageRange,
          dietPreference: p.dietPreference,
          allergens: p.allergens,
          restrictions: p.restrictions,
          limitations: p.limitations,
          conditions: p.conditions,
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Profile',
            style: text.headlineSmall?.copyWith(
                color: AppColors.deepBlue, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const SectionTitle('Where your data lives'),
        const AppCard(
          child: Text(
            'In this version everything is stored only on this device. There '
            'is no account, no cloud sync, and no analytics. Free-text notes '
            'are never saved with your assessments.',
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Optional sign-in and cloud backup are planned for a later phase '
            'and are not available yet.',
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Preferences'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Age range'),
              const SizedBox(height: 6),
              SingleChoiceChips<AgeRange>(
                options: AgeRange.values,
                value: p.ageRange,
                labelOf: (v) => v.label,
                onChanged: (v) => c.updatePreferences(copy()..ageRange = v),
              ),
              const SizedBox(height: 16),
              const Text('Food preference'),
              const SizedBox(height: 6),
              SingleChoiceChips<DietPreference>(
                options: DietPreference.values,
                value: p.dietPreference,
                labelOf: (v) => v.label,
                onChanged: (v) =>
                    c.updatePreferences(copy()..dietPreference = v),
              ),
              const SizedBox(height: 16),
              const Text('Food allergies'),
              const SizedBox(height: 6),
              MultiChoiceChips<Allergen>(
                options: Allergen.values,
                values: p.allergens,
                labelOf: (v) => v.label,
                onChanged: (v) => c.updatePreferences(UserPreferences(
                  ageRange: p.ageRange,
                  dietPreference: p.dietPreference,
                  allergens: v,
                  restrictions: p.restrictions,
                  limitations: p.limitations,
                  conditions: p.conditions,
                )),
              ),
              const SizedBox(height: 16),
              const Text('Dietary restrictions'),
              const SizedBox(height: 6),
              MultiChoiceChips<DietaryRestriction>(
                options: DietaryRestriction.values,
                values: p.restrictions,
                labelOf: (v) => v.label,
                onChanged: (v) => c.updatePreferences(UserPreferences(
                  ageRange: p.ageRange,
                  dietPreference: p.dietPreference,
                  allergens: p.allergens,
                  restrictions: v,
                  limitations: p.limitations,
                  conditions: p.conditions,
                )),
              ),
              const SizedBox(height: 16),
              const Text('Exercise limitations'),
              const SizedBox(height: 6),
              MultiChoiceChips<ExerciseLimitation>(
                options: ExerciseLimitation.values,
                values: p.limitations,
                labelOf: (v) => v.label,
                onChanged: (v) => c.updatePreferences(UserPreferences(
                  ageRange: p.ageRange,
                  dietPreference: p.dietPreference,
                  allergens: p.allergens,
                  restrictions: p.restrictions,
                  limitations: v,
                  conditions: p.conditions,
                )),
              ),
              const SizedBox(height: 16),
              const Text('Relevant health conditions'),
              const SizedBox(height: 6),
              MultiChoiceChips<HealthCondition>(
                options: HealthCondition.values,
                values: p.conditions,
                labelOf: (v) => v.label,
                onChanged: (v) => c.updatePreferences(UserPreferences(
                  ageRange: p.ageRange,
                  dietPreference: p.dietPreference,
                  allergens: p.allergens,
                  restrictions: p.restrictions,
                  limitations: p.limitations,
                  conditions: v,
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Delete my data'),
        OutlinedButton.icon(
          key: const Key('delete_all_button'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () => _confirmDelete(context, c),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Delete all saved data'),
        ),
        const SizedBox(height: 20),
        const DisclaimerBanner(),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppController c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all saved data?'),
        content: const Text(
            'This removes your saved plan, assessments, pain log, tracking '
            'and preferences from this device. It cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await c.deleteAllData();
  }
}
