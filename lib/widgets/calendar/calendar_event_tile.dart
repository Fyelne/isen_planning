import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/course_event.dart';

Color activityColor(String? activityType, ColorScheme scheme) {
  switch (activityType?.toUpperCase()) {
    case 'EVALUATION':
      return scheme.error;
    case 'REUNION':
      return scheme.tertiary;
    case 'TP':
      return scheme.secondary;
    default:
      return scheme.primary;
  }
}

/// Bloc compact affiché dans la grille horaire. Ne montre que l'essentiel
/// (nom du cours, éventuellement heure et salle selon les réglages et la
/// place disponible) ; le détail complet s'ouvre au tap.
class CalendarEventTile extends StatelessWidget {
  const CalendarEventTile({
    super.key,
    required this.event,
    required this.onTap,
    required this.heightPx,
    required this.showTime,
    required this.showLocation,
  });

  final CourseEvent event;
  final VoidCallback onTap;
  final double heightPx;
  final bool showTime;
  final bool showLocation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = activityColor(event.activityType, scheme);
    final timeFormat = DateFormat.Hm('fr_FR');

    final canShowTime = showTime && heightPx >= 30;
    final canShowLocation =
        showLocation && heightPx >= 46 && event.location != null && event.location!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1),
      child: Material(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 3))),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            alignment: Alignment.topLeft,
            // ClipRect + OverflowBox : le Column peut se dimensionner
            // librement (il ne "voit" jamais une contrainte de hauteur trop
            // stricte, donc ne peut plus déclencher l'assertion de
            // débordement de Flutter), et tout ce qui dépasse réellement la
            // hauteur du bloc est simplement découpé, sans avertissement.
            // C'est la technique recommandée par Flutter lui-même pour ce
            // cas précis (contenu légitimement plus grand que l'espace
            // disponible pour un événement très court).
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canShowTime)
                      Text(
                        timeFormat.format(event.start),
                        style:
                            TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
                      ),
                    Text(
                      event.displayCourseName,
                      maxLines: heightPx >= 46 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (canShowLocation)
                      Text(
                        event.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
