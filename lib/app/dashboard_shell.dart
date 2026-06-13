import 'package:flutter/material.dart';

import '../prep_store.dart';
import '../screens/calendar_screen.dart';
import '../screens/home_screen.dart';
import '../screens/mocks_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/syllabus_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({required this.store, super.key});

  final PrepStore store;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final body = AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            return _screenForIndex(_selectedIndex);
          },
        );

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1180,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _changeSection,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: _LogoMark(extended: constraints.maxWidth >= 1180),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.checklist_outlined),
                      selectedIcon: Icon(Icons.checklist),
                      label: Text('Syllabus'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.assessment_outlined),
                      selectedIcon: Icon(Icons.assessment),
                      label: Text('Mocks'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Calendar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.route_outlined),
                      selectedIcon: Icon(Icons.route),
                      label: Text('Plan'),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: ThemeToggleButton(store: widget.store),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('CAT 2026 Dashboard'),
            actions: [ThemeToggleButton(store: widget.store)],
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _changeSection,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Syllabus',
              ),
              NavigationDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: 'Mocks',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route),
                label: 'Plan',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreen(store: widget.store);
      case 1:
        return SyllabusScreen(store: widget.store);
      case 2:
        return MocksScreen(store: widget.store);
      case 3:
        return CalendarScreen(store: widget.store);
      case 4:
        return PlanScreen(store: widget.store);
      default:
        return HomeScreen(store: widget.store);
    }
  }

  void _changeSection(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({required this.store, super.key});

  final PrepStore store;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: store.darkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: IconButton(
        icon: Icon(store.darkMode ? Icons.light_mode : Icons.dark_mode),
        onPressed: () => store.setDarkMode(!store.darkMode),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'CAT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          const Text(
            'Prep Tracker',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}
