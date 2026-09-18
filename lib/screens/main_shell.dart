import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calendar/calendar_navigation_cubit.dart';
import 'home_screen.dart';
import 'search_course_screen.dart';
import 'settings_screen.dart';

/// Coquille principale de l'application une fois le numéro étudiant connu :
/// navigation à 3 onglets (Planning, Recherche, Réglages), affichée en barre
/// basse sur écran étroit (téléphone portrait) et en rail latéral sur écran
/// large ou en paysage (même seuil que la bascule jour/semaine du planning).
/// Les onglets sont gardés montés simultanément via [IndexedStack] pour
/// conserver leur état (recherche en cours, position du planning...) quand
/// on navigue entre eux.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goToPlanningTab() => setState(() => _index = 0);

  void _onDestinationSelected(int index) {
    if (index == 0 && _index == 0) {
      // Ré-appuyer sur "Planning" alors qu'il est déjà sélectionné ramène le
      // calendrier à la date du jour.
      context.read<CalendarNavigationCubit>().goToToday();
      return;
    }
    setState(() => _index = index);
  }

  static const _icons = [Icons.calendar_month_outlined, Icons.search_rounded, Icons.settings_outlined];
  static const _selectedIcons = [
    Icons.calendar_month_rounded,
    Icons.search_rounded,
    Icons.settings_rounded,
  ];
  static const _labels = ['Planning', 'Recherche', 'Réglages'];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= kWeekViewBreakpoint;

    final tabs = IndexedStack(
      index: _index,
      children: [
        const HomeScreen(),
        SearchCourseScreen(
          onGoToDay: (day) {
            context.read<CalendarNavigationCubit>().goToDay(day);
            _goToPlanningTab();
          },
        ),
        const SettingsScreen(),
      ],
    );

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              groupAlignment: 0.0,
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationRailDestination(
                    icon: Icon(_icons[i]),
                    selectedIcon: Icon(_selectedIcons[i]),
                    label: Text(_labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: tabs),
          ],
        ),
      );
    }

    return Scaffold(
      body: tabs,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_selectedIcons[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}
