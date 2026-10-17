import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_scope.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/body_region.dart';
import '../../widgets/common.dart';
import 'body_map_view.dart';

class BodySelectorScreen extends StatelessWidget {
  const BodySelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final map = _MapPanel(controller: c);
          final details = _DetailsPanel(controller: c);
          if (wide) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: map),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(child: details),
                  ),
                ],
              ),
            );
          }
          final mapHeight = math.min(constraints.maxHeight * 0.6, 520.0);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              SizedBox(height: mapHeight, child: map),
              const SizedBox(height: 16),
              details,
            ],
          );
        },
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: <Widget>[
        SegmentedButton<BodyView>(
          segments: const <ButtonSegment<BodyView>>[
            ButtonSegment<BodyView>(value: BodyView.front, label: Text('Front')),
            ButtonSegment<BodyView>(value: BodyView.back, label: Text('Back')),
          ],
          selected: <BodyView>{c.selectorView},
          onSelectionChanged: (s) => c.setSelectorView(s.first),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BodyMapView(
            anatomy: c.anatomy,
            view: c.selectorView,
            selectedId: c.selectedRegionId,
            onRegionSelected: c.selectRegion,
          ),
        ),
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final selected =
        c.selectedRegionId == null ? null : c.anatomy.byId(c.selectedRegionId!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Explore your body',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.deepBlue,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const NoticeBanner(
          message: 'This is the 2D fallback body selector. The interactive 3D '
              'skeleton is not available in this version yet.',
          icon: Icons.layers_outlined,
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                selected == null ? 'Tap where it hurts' : selected.label,
                key: const Key('selected_region_label'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (selected != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  selected.group.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('continue_button'),
                onPressed: selected == null
                    ? null
                    : () {
                        c.startAssessment();
                        Navigator.of(context).pushNamed(AppRoutes.assessment);
                      },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: const Text('Prefer a list? Choose an area'),
          children: <Widget>[
            for (final group in RegionGroup.values) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    group.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final r in c.anatomy.inGroup(group))
                        ChoiceChip(
                          label: Text(r.label),
                          selected: r.id == c.selectedRegionId,
                          onSelected: (_) => c.selectRegion(r.id),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
        const SizedBox(height: 12),
        const DisclaimerBanner(),
      ],
    );
  }
}
