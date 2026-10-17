import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_scope.dart';
import 'router.dart';
import 'theme.dart';

class BodyWiseApp extends StatelessWidget {
  const BodyWiseApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: 'BodyWise 3D',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: AppRoutes.shell,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
