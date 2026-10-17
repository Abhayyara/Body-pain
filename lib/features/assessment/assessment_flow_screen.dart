import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/assessment.dart';
import '../../models/body_region.dart';
import '../../widgets/common.dart';
import 'assessment_validator.dart';

class AssessmentFlowScreen extends StatefulWidget {
  const AssessmentFlowScreen({super.key});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen> {
  static const List<String> _titles = <String>[
    'Body area',
    'Your pain',
    'Impact',
    'Warning signs',
    'About you (optional)',
    'Review',
  ];

  int _step = 0;
  List<String> _errors = const <String>[];
  bool _submitting = false;

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _step -= 1;
        _errors = const <String>[];
      });
    }
  }

  Future<void> _next(AppController c) async {
    final errors = AssessmentValidator.validateStep(c.draft, _step);
    final urgent =
        _step == AssessmentValidator.warningStep && c.draft.redFlags.isNotEmpty;
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    if (urgent || _step == AssessmentValidator.reviewStep) {
      await _submit(c);
      return;
    }
    setState(() {
      _step += 1;
      _errors = const <String>[];
    });
  }

  Future<void> _submit(AppController c) async {
    setState(() => _submitting = true);
    await c.submitAssessment();
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed(AppRoutes.results);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    final a = c.draft;
    final urgent =
        _step == AssessmentValidator.warningStep && a.redFlags.isNotEmpty;
    final last = _step == AssessmentValidator.reviewStep;
    return Scaffold(
      appBar: AppBar(title: const Text('Pain assessment')),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(value: (_step + 1) / _titles.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Text(
                  'Step ${_step + 1} of ${_titles.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _titles[_step],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.deepBlue,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (_errors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoticeBanner(
                      key: const Key('validation_errors'),
                      message: _errors.join('\n'),
                      icon: Icons.error_outline,
                      background: AppColors.dangerLight,
                      foreground: AppColors.danger,
                    ),
                  ),
                _buildStep(context, c, a),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _back,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: const Key('next_button'),
                      onPressed: _submitting ? null : () => _next(c),
                      child: Text(
                        urgent
                            ? 'Get urgent guidance'
                            : (last ? 'See my results' : 'Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppController c, Assessment a) {
    switch (_step) {
      case AssessmentValidator.regionStep:
        return _regionStep(c, a);
      case AssessmentValidator.painStep:
        return _painStep(a);
      case AssessmentValidator.impactStep:
        return _impactStep(a);
      case AssessmentValidator.warningStep:
        return _warningStep(a);
      case AssessmentValidator.aboutStep:
        return _aboutStep(a);
      default:
        return _reviewStep(c, a);
    }
  }

  // ---- steps ---------------------------------------------------------------
  Widget _regionStep(AppController c, Assessment a) {
    final region = a.regionId == null ? null : c.anatomy.byId(a.regionId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Where do you feel the pain?'),
        const SizedBox(height: 12),
        for (final group in RegionGroup.values) ...<Widget>[
          Text(group.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final r in c.anatomy.inGroup(group))
                ChoiceChip(
                  label: Text(r.label),
                  selected: r.id == a.regionId,
                  onSelected: (_) => setState(() {
                    c.selectRegion(r.id);
                    a.sideDetail = null;
                    _errors = const <String>[];
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (region != null && region.isMidline) ...<Widget>[
          const SizedBox(height: 4),
          const Text('Which side (optional)?'),
          const SizedBox(height: 8),
          SingleChoiceChips<SideDetail>(
            options: SideDetail.values,
            value: a.sideDetail,
            labelOf: (s) => s.label,
            onChanged: (v) => setState(() => a.sideDetail = v),
          ),
        ],
      ],
    );
  }

  Widget _painStep(Assessment a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Question('How strong is the pain right now?'),
        Text('0 = no pain, 10 = worst pain imaginable',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SingleChoiceChips<int>(
          options: <int>[
            for (var i = kMinPainIntensity; i <= kMaxPainIntensity; i++) i,
          ],
          value: a.painIntensity,
          labelOf: (i) => '$i',
          onChanged: (v) => setState(() => a.painIntensity = v),
        ),
        const SizedBox(height: 20),
        const _Question('How long has it lasted?'),
        SingleChoiceChips<PainDuration>(
          options: PainDuration.values,
          value: a.duration,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => a.duration = v),
        ),
        const SizedBox(height: 20),
        const _Question('How does it feel? (choose all that apply)'),
        MultiChoiceChips<PainSensation>(
          options: PainSensation.values,
          values: a.sensations,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.sensations
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 20),
        const _Question('How did it start?'),
        SingleChoiceChips<Onset>(
          options: Onset.values,
          value: a.onset,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => a.onset = v),
        ),
      ],
    );
  }

  Widget _impactStep(Assessment a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Question('Does moving make the pain worse?'),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: true, label: Text('Yes')),
            ButtonSegment<bool>(value: false, label: Text('No')),
          ],
          emptySelectionAllowed: true,
          selected: a.movementWorsens == null
              ? <bool>{}
              : <bool>{a.movementWorsens!},
          onSelectionChanged: (s) => setState(
            () => a.movementWorsens = s.isEmpty ? null : s.first,
          ),
        ),
        const SizedBox(height: 20),
        const _Question('Is the pain affecting any of these?'),
        MultiChoiceChips<ImpactArea>(
          options: ImpactArea.values,
          values: a.impacts,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.impacts
              ..clear()
              ..addAll(v);
          }),
        ),
      ],
    );
  }

  Widget _warningStep(Assessment a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Do any of these apply to you right now?'),
        const SizedBox(height: 8),
        for (final flag in RedFlag.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(flag.label),
            value: a.redFlags.contains(flag),
            onChanged: (checked) => setState(() {
              if (checked ?? false) {
                a.redFlags.add(flag);
                a.redFlagsReviewed = true;
              } else {
                a.redFlags.remove(flag);
                if (a.redFlags.isEmpty) a.redFlagsReviewed = false;
              }
              _errors = const <String>[];
            }),
          ),
        const SizedBox(height: 8),
        if (a.redFlags.isNotEmpty)
          const NoticeBanner(
            message: 'You selected a warning sign. Tap "Get urgent guidance" '
                'for what to do now.',
            icon: Icons.warning_amber_rounded,
            background: AppColors.dangerLight,
            foreground: AppColors.danger,
          )
        else
          OutlinedButton.icon(
            key: const Key('none_apply_button'),
            onPressed: () => setState(() {
              a.redFlagsReviewed = !a.redFlagsReviewed;
              _errors = const <String>[];
            }),
            icon: Icon(a.redFlagsReviewed
                ? Icons.check_circle
                : Icons.radio_button_unchecked),
            label: const Text('None of these apply to me'),
          ),
        const SizedBox(height: 12),
        Text(
          'Answering "none" does not prove nothing is wrong. If you are '
          'worried, seek medical advice.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _aboutStep(Assessment a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Everything on this page is optional. It stays on your device and '
          'helps tailor suggestions.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const _Question('Age range'),
        SingleChoiceChips<AgeRange>(
          options: AgeRange.values,
          value: a.ageRange,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => a.ageRange = v),
        ),
        const SizedBox(height: 20),
        const _Question('Exercise limitations'),
        MultiChoiceChips<ExerciseLimitation>(
          options: ExerciseLimitation.values,
          values: a.limitations,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.limitations
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 20),
        const _Question('Relevant health conditions'),
        MultiChoiceChips<HealthCondition>(
          options: HealthCondition.values,
          values: a.conditions,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.conditions
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 20),
        const _Question('Food preference'),
        SingleChoiceChips<DietPreference>(
          options: DietPreference.values,
          value: a.dietPreference,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() => a.dietPreference = v),
        ),
        const SizedBox(height: 20),
        const _Question('Food allergies'),
        MultiChoiceChips<Allergen>(
          options: Allergen.values,
          values: a.allergens,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.allergens
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 20),
        const _Question('Other dietary restrictions'),
        MultiChoiceChips<DietaryRestriction>(
          options: DietaryRestriction.values,
          values: a.restrictions,
          labelOf: (v) => v.label,
          onChanged: (v) => setState(() {
            a.restrictions
              ..clear()
              ..addAll(v);
          }),
        ),
        const SizedBox(height: 20),
        const _Question('Anything else about your symptoms?'),
        TextFormField(
          initialValue: a.additionalDetails,
          maxLength: AssessmentValidator.maxDetailsLength,
          maxLines: 3,
          onChanged: (v) => a.additionalDetails = v,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Optional',
            helperText: 'Kept on your device and never sent to an AI service. '
                'The safety check scans it for concerning words.',
            helperMaxLines: 3,
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(AppController c, Assessment a) {
    final region = a.regionId == null ? null : c.anatomy.byId(a.regionId!);
    String yesNo(bool? v) => v == null ? '-' : (v ? 'Yes' : 'No');
    String list(Iterable<String> v) => v.isEmpty ? '-' : v.join(', ');
    final rows = <MapEntry<String, String>>[
      MapEntry<String, String>('Area', region?.label ?? '-'),
      if (region != null && region.isMidline)
        MapEntry<String, String>('Side', a.sideDetail?.label ?? '-'),
      MapEntry<String, String>(
          'Pain (0-10)', a.painIntensity?.toString() ?? '-'),
      MapEntry<String, String>('Duration', a.duration?.label ?? '-'),
      MapEntry<String, String>('Feels', list(a.sensations.map((e) => e.label))),
      MapEntry<String, String>('Started', a.onset?.label ?? '-'),
      MapEntry<String, String>('Worse with movement', yesNo(a.movementWorsens)),
      MapEntry<String, String>('Affects', list(a.impacts.map((e) => e.label))),
      MapEntry<String, String>(
          'Warning signs',
          a.redFlags.isEmpty ? 'None' : '${a.redFlags.length} selected'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Please check your answers. Use Back to change anything.'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: <Widget>[
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Text(row.key,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(flex: 3, child: Text(row.value)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DisclaimerBanner(),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
