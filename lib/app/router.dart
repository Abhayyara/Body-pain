import 'package:flutter/material.dart';

import '../features/assessment/assessment_flow_screen.dart';
import '../features/home/app_shell.dart';
import '../features/recommendations/results_screen.dart';

class AppRoutes {
  const AppRoutes._();
  static const String shell = '/';
  static const String assessment = '/assessment';
  static const String results = '/results';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.assessment:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AssessmentFlowScreen(),
        );
      case AppRoutes.results:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ResultsScreen(),
        );
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppShell(),
        );
    }
  }
}
