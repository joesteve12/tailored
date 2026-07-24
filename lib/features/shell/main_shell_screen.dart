import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's persistent bottom-nav scaffold. Wraps the five top-level tabs
/// (Home / Orders / Tasks / Customers / Settings) using go_router's
/// StatefulNavigationShell, which keeps each tab's navigation stack alive
/// when switching between them (an IndexedStack under the hood).
///
/// Detail and form screens (order detail, client form, employee detail, …)
/// are NOT branches here — they're top-level routes that render over this
/// shell on the root navigator, so they're full-screen with a back button,
/// matching the reference UI.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // initialLocation:true makes tapping the current tab again pop back to
    // its root, the conventional bottom-nav behaviour.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          // Tasks replaces the old Dashboard slot in the bar. Dashboard is
          // now reached from Settings.
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
