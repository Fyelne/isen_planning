import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_theme.dart';
import 'bloc/calendar/calendar_navigation_cubit.dart';
import 'bloc/schedule/schedule_bloc.dart';
import 'bloc/schedule/schedule_event.dart';
import 'bloc/settings/settings_cubit.dart';
import 'bloc/settings/settings_state.dart';
import 'data/schedule_repository.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/preferences_service.dart';

class IsenPlanningApp extends StatelessWidget {
  const IsenPlanningApp({super.key, required this.preferencesService});

  final PreferencesService preferencesService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PreferencesService>.value(value: preferencesService),
        RepositoryProvider<ScheduleRepository>(
          create: (_) => ScheduleRepository(preferencesService: preferencesService),
        ),
      ],
      child: BlocProvider(
        create: (_) => SettingsCubit(preferencesService)..load(),
        child: _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  _AppView();

  /// Permet de déclencher un `pop` (ex : bouton "retour" de la souris) sans
  /// dépendre d'un BuildContext situé sous le Navigator.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        final hasStudentNumber =
            settings.studentNumber != null && settings.studentNumber!.isNotEmpty;

        return MaterialApp(
          title: 'Mon Planning ISEN',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          themeMode: settings.themeMode,
          theme: AppTheme.light(settings.accentColor),
          darkTheme: AppTheme.dark(settings.accentColor),
          home: hasStudentNumber ? const MainShell() : const OnboardingScreen(),
          // IMPORTANT : ScheduleBloc et CalendarNavigationCubit sont fournis
          // ici, dans `builder`, qui englobe le Navigator dans son
          // intégralité — et pas seulement `home`. `home` ne correspond qu'à
          // la toute première page ; tout écran poussé ensuite (sous-écrans
          // des Réglages...) est un frère de cette page dans l'arbre des
          // widgets, pas un descendant. Un provider placé seulement autour
          // de `home` serait invisible pour ces écrans (ProviderNotFoundError).
          builder: (context, child) {
            Widget content = child ?? const SizedBox.shrink();

            // Bouton "retour" de la souris (bouton latéral, PC/Mac/Linux) :
            // revient à l'écran précédent, comme un navigateur web.
            content = Listener(
              onPointerDown: (event) {
                if (event.buttons & kBackMouseButton != 0) {
                  _navigatorKey.currentState?.maybePop();
                }
              },
              child: content,
            );

            if (hasStudentNumber) {
              content = MultiBlocProvider(
                providers: [
                  BlocProvider<ScheduleBloc>(
                    key: ValueKey(settings.studentNumber),
                    create: (context) => ScheduleBloc(
                      repository: context.read<ScheduleRepository>(),
                    )..add(ScheduleStarted(settings.studentNumber!)),
                  ),
                  BlocProvider<CalendarNavigationCubit>(
                    create: (_) => CalendarNavigationCubit(),
                  ),
                ],
                child: content,
              );
            }

            return content;
          },
        );
      },
    );
  }
}
