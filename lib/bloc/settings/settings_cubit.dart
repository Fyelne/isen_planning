import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/preferences_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState());

  final PreferencesService _prefs;

  void load() {
    emit(state.copyWith(
      isInitialized: true,
      studentNumber: _prefs.studentNumber,
      themeMode: ThemeMode.values[_prefs.themeMode],
      accentColorIndex: _prefs.accentColor,
      hideWeekends: _prefs.hideWeekends,
      displayFieldOrder: _decodeFieldOrder(_prefs.fieldOrder),
      enabledFields: _decodeEnabledFields(_prefs.enabledFields),
      hiddenCourses: _prefs.hiddenCourses.toSet(),
    ));
  }

  List<CourseField> _decodeFieldOrder(List<String>? stored) {
    if (stored == null || stored.isEmpty) return kDefaultFieldOrder;
    final decoded = <CourseField>[];
    for (final name in stored) {
      final match = CourseField.values.where((f) => f.name == name);
      if (match.isNotEmpty) decoded.add(match.first);
    }
    // On ajoute à la fin les champs manquants (ex : nouvelle version de l'app).
    for (final field in CourseField.values) {
      if (!decoded.contains(field)) decoded.add(field);
    }
    return decoded;
  }

  Set<CourseField> _decodeEnabledFields(List<String>? stored) {
    if (stored == null) return kDefaultEnabledFields;
    final decoded = stored
        .map((name) => CourseField.values.where((f) => f.name == name))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toSet();
    return decoded.isEmpty ? kDefaultEnabledFields : decoded;
  }

  Future<void> setStudentNumber(String value) async {
    final trimmed = value.trim();
    await _prefs.setStudentNumber(trimmed);
    emit(state.copyWith(studentNumber: trimmed));
  }

  /// Change de compte : efface le numéro étudiant, le flux ICS mis en cache
  /// et la date de dernière synchronisation, pour repartir sur un planning
  /// vierge (pas de résidu du compte précédent). C'est la seule façon de
  /// changer de numéro étudiant : il n'y a volontairement pas d'édition
  /// directe, pour éviter qu'un changement accidentel mélange les données
  /// de deux comptes.
  Future<void> changeAccount() async {
    await _prefs.clearAccountData();
    emit(state.copyWith(clearStudentNumber: true));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setAccentColorIndex(int index) async {
    await _prefs.setAccentColor(index);
    emit(state.copyWith(accentColorIndex: index));
  }

  Future<void> setHideWeekends(bool value) async {
    await _prefs.setHideWeekends(value);
    emit(state.copyWith(hideWeekends: value));
  }

  /// Réordonne les champs affichés sur les cartes de cours.
  Future<void> setFieldOrder(List<CourseField> order) async {
    await _prefs.setFieldOrder(order.map((f) => f.name).toList());
    emit(state.copyWith(displayFieldOrder: order));
  }

  /// Active/désactive un champ. On garde toujours au moins un champ visible.
  Future<void> setFieldEnabled(CourseField field, bool enabled) async {
    final current = Set<CourseField>.from(state.enabledFields);
    if (!enabled && current.length <= 1) return;
    if (enabled) {
      current.add(field);
    } else {
      current.remove(field);
    }
    await _prefs.setEnabledFields(current.map((f) => f.name).toList());
    emit(state.copyWith(enabledFields: current));
  }

  /// Remplace entièrement la liste des cours masqués.
  Future<void> setHiddenCourses(Set<String> hidden) async {
    await _prefs.setHiddenCourses(hidden.toList());
    emit(state.copyWith(hiddenCourses: hidden));
  }

  /// Masque/affiche un cours précis (identifié par son nom - filterKey).
  Future<void> toggleCourseHidden(String courseKey, bool hidden) async {
    final current = Set<String>.from(state.hiddenCourses);
    if (hidden) {
      current.add(courseKey);
    } else {
      current.remove(courseKey);
    }
    await setHiddenCourses(current);
  }
}
