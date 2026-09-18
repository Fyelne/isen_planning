import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/calendar/calendar_navigation_cubit.dart';
import '../bloc/schedule/schedule_bloc.dart';
import '../bloc/schedule/schedule_event.dart';
import '../bloc/schedule/schedule_state.dart';
import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';
import '../models/course_event.dart';
import '../widgets/calendar/day_calendar_view.dart';
import '../widgets/calendar/week_calendar_view.dart';
import '../widgets/day_strip.dart';
import '../widgets/empty_state.dart';

/// En dessous de cette largeur logique, l'écran est considéré "étroit"
/// (téléphone en portrait) et affiche une vue jour ; au-dessus, une vue
/// semaine (PC, Mac, tablette, téléphone en paysage). Réutilisé par
/// `MainShell` pour décider barre de navigation basse vs. latérale.
const double kWeekViewBreakpoint = 600;

/// Vitesse minimale (px/s) en dessous de laquelle un geste horizontal n'est
/// pas considéré comme un swipe volontaire de changement de jour/semaine.
const double kSwipeVelocityThreshold = 200;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<DateTime> _allDays;

  @override
  void initState() {
    super.initState();
    _allDays = _generateDaysAround(_today());
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _generateDaysAround(DateTime center) => List.generate(
        365,
        (index) => center.subtract(const Duration(days: 180)).add(Duration(days: index)),
      );

  DateTime _mondayOf(DateTime day) =>
      DateTime(day.year, day.month, day.day).subtract(Duration(days: day.weekday - 1));

  List<DateTime> _weekDaysAround(DateTime anchor, bool hideWeekends) {
    final monday = _mondayOf(anchor);
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));
    return hideWeekends
        ? week.where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday).toList()
        : week;
  }

  /// Filtre les événements masqués par l'utilisateur, puis ceux du jour donné.
  List<CourseEvent> _visibleEventsForDay(
    List<CourseEvent> allEvents,
    Set<String> hiddenCourses,
    DateTime day,
  ) {
    return allEvents
        .where((e) => !hiddenCourses.contains(e.filterKey))
        .where((e) => e.isSameDay(day))
        .toList();
  }

  void _refresh() {
    context.read<ScheduleBloc>().add(const ScheduleRefreshed());
  }

  void _handleSwipe(
    DragEndDetails details, {
    required bool useWeekView,
    required bool hideWeekends,
  }) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < kSwipeVelocityThreshold) return;
    final cubit = context.read<CalendarNavigationCubit>();
    // Swipe vers la gauche -> avance (+1) ; vers la droite -> recule (-1).
    final direction = velocity < 0 ? 1 : -1;

    if (useWeekView) {
      // Une semaine entière : masquer les week-ends n'affecte pas ce calcul,
      // seules les colonnes affichées changent, pas l'ancre.
      cubit.shiftDays(7 * direction);
      return;
    }

    var next = cubit.state.add(Duration(days: direction));
    if (hideWeekends) {
      while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
        next = next.add(Duration(days: direction));
      }
    }
    cubit.goToDay(next);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final selectedDay = context.watch<CalendarNavigationCubit>().state;
    final width = MediaQuery.sizeOf(context).width;
    final useWeekView = width >= kWeekViewBreakpoint;

    // Régénère la fenêtre du bandeau de jours si le jour sélectionné en est
    // sorti (ex : saut via la recherche loin dans le temps).
    if (!_allDays.any((d) => _isSameDay(d, selectedDay))) {
      _allDays = _generateDaysAround(selectedDay);
    }

    final visibleDays = settings.hideWeekends
        ? _allDays
            .where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday)
            .toList()
        : _allDays;
    final weekDays = _weekDaysAround(selectedDay, settings.hideWeekends);
    final showTime = settings.enabledFields.contains(CourseField.time);
    final showLocation = settings.enabledFields.contains(CourseField.location);

    // CallbackShortcuts doit être un ANCÊTRE du widget qui a le focus pour
    // que la touche F5 remonte bien jusqu'à lui (bubbling des événements clavier).
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _refresh,
      },
      child: Focus(
        autofocus: true,
        // Pas d'AppBar ici : le rafraîchissement reste accessible via le
        // geste de glissement vers le bas (pull-to-refresh) et F5 sur
        // desktop. SafeArea évite que le contenu passe sous l'encoche/la
        // barre de statut en l'absence d'AppBar.
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                final isLoading = state.status == ScheduleStatus.loading;

                Widget content;
                if (isLoading && !state.hasData) {
                  content = const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (state.events.isEmpty) {
                  content = ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        message: 'Aucun cours à afficher.',
                        icon: Icons.beach_access_outlined,
                      ),
                    ],
                  );
                } else if (useWeekView) {
                  content = WeekCalendarView(
                    days: weekDays,
                    eventsForDay: (day) =>
                        _visibleEventsForDay(state.events, settings.hiddenCourses, day),
                    showTime: showTime,
                    showLocation: showLocation,
                    visibleDetailFields: settings.enabledFields,
                  );
                } else {
                  content = DayCalendarView(
                    day: selectedDay,
                    events:
                        _visibleEventsForDay(state.events, settings.hiddenCourses, selectedDay),
                    showTime: showTime,
                    showLocation: showLocation,
                    visibleDetailFields: settings.enabledFields,
                  );
                }

                return Column(
                  children: [
                    if (useWeekView)
                      _WeekNavigator(weekDays: weekDays)
                    else
                      DayStrip(
                        days: visibleDays,
                        selectedDay: selectedDay,
                        onSelected: (day) =>
                            context.read<CalendarNavigationCubit>().goToDay(day),
                        eventCountFor: (day) =>
                            _visibleEventsForDay(state.events, settings.hiddenCourses, day)
                                .length,
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: GestureDetector(
                        // Swipe gauche/droite pour changer de jour (vue jour)
                        // ou de semaine (vue semaine).
                        onHorizontalDragEnd: (details) => _handleSwipe(
                          details,
                          useWeekView: useWeekView,
                          hideWeekends: settings.hideWeekends,
                        ),
                        child: RefreshIndicator(
                          onRefresh: () async {
                            _refresh();
                            await context.read<ScheduleBloc>().stream.firstWhere(
                                  (s) => s.status != ScheduleStatus.refreshing,
                                );
                          },
                          child: content,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _StatusFooter(
                      status: state.status,
                      lastUpdated: state.lastUpdated,
                      isOffline: state.isOffline,
                      errorMessage: state.errorMessage,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({required this.weekDays});

  final List<DateTime> weekDays;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM', 'fr_FR');
    final label = weekDays.isEmpty
        ? ''
        : '${formatter.format(weekDays.first)} - ${formatter.format(weekDays.last)}';
    final cubit = context.read<CalendarNavigationCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Semaine précédente',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => cubit.shiftDays(-7),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          IconButton(
            tooltip: 'Semaine suivante',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => cubit.shiftDays(7),
          ),
        ],
      ),
    );
  }
}

/// Bandeau de pied de calendrier fusionnant le statut de synchronisation
/// (succès / hors ligne / échec) et l'horodatage de dernière mise à jour.
/// Un tap ouvre le détail complet (raison de l'échec, rappel du délai
/// d'activation de l'agenda distant, etc.).
class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.status,
    required this.lastUpdated,
    required this.isOffline,
    required this.errorMessage,
  });

  final ScheduleStatus status;
  final DateTime? lastUpdated;
  final bool isOffline;
  final String? errorMessage;

  String? _formattedDate() {
    if (lastUpdated == null) return null;
    return DateFormat('dd/MM à HH:mm', 'fr_FR').format(lastUpdated!);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatted = _formattedDate();

    final IconData icon;
    final String label;
    final Color? background;
    final Color foreground;
    final String detail;

    if (status == ScheduleStatus.failure) {
      icon = Icons.wifi_off_rounded;
      label = 'Connexion impossible';
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      detail = errorMessage ?? 'Erreur de synchronisation.';
    } else if (isOffline) {
      icon = Icons.cloud_off_rounded;
      label = formatted != null ? 'Hors ligne · $formatted' : 'Hors ligne';
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      detail = 'Dernières données synchronisées'
          '${formatted != null ? ' le $formatted' : ''}. L\'application '
          'affiche la dernière version connue du planning en attendant de '
          'retrouver une connexion.';
    } else if (formatted != null) {
      icon = Icons.cloud_done_outlined;
      label = 'Mis à jour le $formatted';
      background = null;
      foreground = scheme.onSurfaceVariant;
      detail = 'Le planning a été synchronisé avec succès le $formatted.';
    } else {
      // Aucune information à afficher pour l'instant (première synchro en cours).
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _showDetail(context, icon: icon, label: label, detail: detail, color: foreground),
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded, size: 14, color: foreground.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String detail,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label, style: Theme.of(sheetContext).textTheme.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(detail, style: Theme.of(sheetContext).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}
