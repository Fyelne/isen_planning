import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Autorise le glisser à la souris (et pas seulement au tactile) dans les
/// listes déroulantes, utile sur PC/Mac/Linux.
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onSelected,
    required this.eventCountFor,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelected;
  final int Function(DateTime day) eventCountFor;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  // Largeur d'un item (56) + espacement (8) : sert à estimer la position de
  // défilement initiale avant même le premier layout, pour éviter tout
  // flash visuel montrant le début de la liste (ex : "mars" au lieu
  // d'aujourd'hui) le temps d'une frame.
  static const double _itemExtent = 64.0;

  late final ScrollController _controller;

  /// Clé attribuée à l'item actuellement sélectionné, pour pouvoir le faire
  /// défiler dans la zone visible via `Scrollable.ensureVisible`.
  final GlobalKey _selectedItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(initialScrollOffset: _estimatedOffset());
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelectedVisible(animate: false));
  }

  @override
  void didUpdateWidget(covariant DayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDay, widget.selectedDay) ||
        oldWidget.days.length != widget.days.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelectedVisible(animate: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _estimatedOffset() {
    final index = widget.days.indexWhere((d) => _isSameDay(d, widget.selectedDay));
    if (index <= 0) return 0;
    // Laisse un peu de contexte (quelques jours précédents) visible à gauche
    // plutôt que de coller le jour sélectionné au tout début.
    final leading = (index - 2).clamp(0, index).toDouble();
    return leading * _itemExtent;
  }

  void _ensureSelectedVisible({required bool animate}) {
    final itemContext = _selectedItemKey.currentContext;
    if (itemContext == null) return;
    Scrollable.ensureVisible(
      itemContext,
      alignment: 0.3,
      duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
      curve: Curves.easeOut,
    );
  }

  /// Traduit le défilement (molette verticale ou trackpad) en défilement
  /// horizontal, pour naviguer dans le bandeau de jours à la souris.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _controller.hasClients) {
      final delta = event.scrollDelta.dy != 0 ? event.scrollDelta.dy : event.scrollDelta.dx;
      final target =
          (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
      _controller.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: ScrollConfiguration(
        behavior: _MouseDragScrollBehavior(),
        child: SizedBox(
          height: 74,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: widget.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = widget.days[index];
              final isSelected = _isSameDay(day, widget.selectedDay);
              final isToday = _isSameDay(day, today);
              final count = widget.eventCountFor(day);

              return GestureDetector(
                key: isSelected ? _selectedItemKey : null,
                onTap: () => widget.onSelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E('fr_FR').format(day).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (count > 0)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? scheme.onPrimary : scheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
