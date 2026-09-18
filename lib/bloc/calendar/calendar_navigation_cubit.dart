import 'package:flutter_bloc/flutter_bloc.dart';

/// Gère le jour actuellement affiché dans le planning. Partagé entre
/// l'onglet Planning (affichage, swipe, "aujourd'hui") et l'onglet
/// Recherche ("aller à ce jour" sur un résultat), pour que les deux restent
/// synchronisés sans passer par une navigation poussée.
class CalendarNavigationCubit extends Cubit<DateTime> {
  CalendarNavigationCubit() : super(_todayNormalized());

  static DateTime _todayNormalized() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void goToDay(DateTime day) => emit(DateTime(day.year, day.month, day.day));

  void goToToday() => emit(_todayNormalized());

  void shiftDays(int deltaDays) => emit(state.add(Duration(days: deltaDays)));
}
