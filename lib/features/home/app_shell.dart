import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../body_selector/body_selector_screen.dart';
import '../plan/my_plan_screen.dart';
import '../profile/profile_screen.dart';
import '../progress/progress_screen.dart';
import 'home_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const int homeTab = 0;
  static const int exploreTab = 1;
  static const int planTab = 2;
  static const int progressTab = 3;
  static const int profileTab = 4;

  @override
  Widget build(BuildContext context) {
    final c = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: c.tabIndex,
          children: const <Widget>[
            HomeScreen(),
            BodySelectorScreen(),
            MyPlanScreen(),
            ProgressScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: c.tabIndex,
        onDestinationSelected: c.goToTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.accessibility_new_outlined),
              selectedIcon: Icon(Icons.accessibility_new),
              label: 'Explore Body'),
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'My Plan'),
          NavigationDestination(
              icon: Icon(Icons.show_chart),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Progress'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
