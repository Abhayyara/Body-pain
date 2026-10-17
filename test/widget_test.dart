import 'package:bodywise3d/app/app_controller.dart';
import 'package:bodywise3d/app/app_scope.dart';
import 'package:bodywise3d/features/body_selector/body_map_view.dart';
import 'package:bodywise3d/features/recommendations/recommendation_engine.dart';
import 'package:bodywise3d/features/recommendations/results_screen.dart';
import 'package:bodywise3d/models/assessment.dart';
import 'package:bodywise3d/models/body_region.dart';
import 'package:bodywise3d/services/anatomy_service.dart';
import 'package:bodywise3d/services/storage_service.dart';
import 'package:bodywise3d/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<void> _tapNormalised(WidgetTester tester, double nx, double ny) async {
  final rect = tester.getRect(find.byKey(BodyMapView.hitAreaKey));
  await tester.tapAt(
    Offset(rect.left + nx * rect.width, rect.top + ny * rect.height),
  );
  await tester.pump();
}

Widget _mapHarness(BodyView view, ValueChanged<String> onPick) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 600,
            child: BodyMapView(
              anatomy: AnatomyService(),
              view: view,
              selectedId: null,
              onRegionSelected: onPick,
            ),
          ),
        ),
      ),
    );

Future<AppController> _controller(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final storage =
      await tester.runAsync(() => StorageService.create()) as StorageService;
  return AppController(
    storage: storage,
    engine: RecommendationEngine(allowDraftContent: true),
  );
}

Widget _resultsHarness(AppController c) => AppScope(
      controller: c,
      child: const MaterialApp(home: ResultsScreen()),
    );

void main() {
  group('BodyMapView (2D fallback)', () {
    testWidgets('front view: screen-right shoulder is the LEFT shoulder',
        (tester) async {
      String? picked;
      await tester.pumpWidget(_mapHarness(BodyView.front, (id) => picked = id));
      await _tapNormalised(tester, 0.65, 0.19);
      expect(picked, 'left_shoulder');
      await _tapNormalised(tester, 0.35, 0.19);
      expect(picked, 'right_shoulder');
    });

    testWidgets('back view: screen-left shoulder is the LEFT shoulder',
        (tester) async {
      String? picked;
      await tester.pumpWidget(_mapHarness(BodyView.back, (id) => picked = id));
      await _tapNormalised(tester, 0.35, 0.19);
      expect(picked, 'left_shoulder');
      await _tapNormalised(tester, 0.5, 0.42);
      expect(picked, 'lower_back');
    });

    testWidgets('tapping empty space selects nothing', (tester) async {
      String? picked;
      await tester.pumpWidget(_mapHarness(BodyView.front, (id) => picked = id));
      await _tapNormalised(tester, 0.05, 0.5);
      expect(picked, isNull);
    });
  });

  group('ResultsScreen', () {
    testWidgets('emergency result shows guidance and no plan sections',
        (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final c = await _controller(tester);
      c.latestPlan = c.engine.build(
        baseAssessment()..redFlags.add(RedFlag.chestPainWithBreathlessness),
      );
      await tester.pumpWidget(_resultsHarness(c));
      expect(find.byKey(const Key('emergency_card')), findsOneWidget);
      expect(find.textContaining('emergency'), findsWidgets);
      expect(find.textContaining('movement plan'), findsNothing);
      expect(find.textContaining('Nutrition guidance'), findsNothing);
      expect(find.byKey(const Key('save_plan_button')), findsNothing);
    });

    testWidgets('clinical result shows the recommendation and no exercises',
        (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final c = await _controller(tester);
      c.latestPlan = c.engine.build(baseAssessment(pain: 9));
      await tester.pumpWidget(_resultsHarness(c));
      expect(find.byKey(const Key('clinical_card')), findsOneWidget);
      expect(find.textContaining('movement plan'), findsNothing);
      expect(find.text('E. Next steps'), findsOneWidget);
    });

    testWidgets('eligible result shows sections A to E and the disclaimer',
        (tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final c = await _controller(tester);
      c.latestPlan = c.engine.build(baseAssessment());
      await tester.pumpWidget(_resultsHarness(c));
      expect(find.text('A. Your assessment'), findsOneWidget);
      expect(find.text('B. Your movement plan'), findsOneWidget);
      expect(find.text('C. Nutrition guidance'), findsOneWidget);
      expect(find.text('D. Daily wellness'), findsOneWidget);
      expect(find.text('E. Next steps'), findsOneWidget);
      expect(find.text(kDisclaimer), findsWidgets);
      expect(find.byKey(const Key('save_plan_button')), findsOneWidget);
    });
  });
}
