import 'package:shared_preferences/shared_preferences.dart';

/// Fine encapsulation de [SharedPreferences] centralisant toutes les clés
/// persistées par l'application (numéro étudiant, apparence, cache ICS...).
class PreferencesService {
  PreferencesService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  static const _keyStudentNumber = 'student_number';
  static const _keyThemeMode = 'theme_mode';
  static const _keyAccentColor = 'accent_color';
  static const _keyHideWeekends = 'hide_weekends';
  static const _keyCachedIcs = 'cached_ics';
  static const _keyLastSync = 'last_sync';
  static const _keyHiddenCourses = 'hidden_courses';
  static const _keyFieldOrder = 'field_order';
  static const _keyEnabledFields = 'enabled_fields';

  String? get studentNumber => _prefs.getString(_keyStudentNumber);
  Future<void> setStudentNumber(String value) => _prefs.setString(_keyStudentNumber, value);
  Future<void> clearStudentNumber() => _prefs.remove(_keyStudentNumber);

  /// 0 = système, 1 = clair, 2 = sombre.
  int get themeMode => _prefs.getInt(_keyThemeMode) ?? 0;
  Future<void> setThemeMode(int value) => _prefs.setInt(_keyThemeMode, value);

  int get accentColor => _prefs.getInt(_keyAccentColor) ?? 0;
  Future<void> setAccentColor(int value) => _prefs.setInt(_keyAccentColor, value);

  bool get hideWeekends => _prefs.getBool(_keyHideWeekends) ?? true;
  Future<void> setHideWeekends(bool value) => _prefs.setBool(_keyHideWeekends, value);

  String? get cachedIcs => _prefs.getString(_keyCachedIcs);
  Future<void> setCachedIcs(String value) => _prefs.setString(_keyCachedIcs, value);
  Future<void> clearCachedIcs() => _prefs.remove(_keyCachedIcs);

  DateTime? get lastSync {
    final millis = _prefs.getInt(_keyLastSync);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastSync(DateTime value) =>
      _prefs.setInt(_keyLastSync, value.millisecondsSinceEpoch);

  /// Noms de cours (filterKey) que l'utilisateur a choisi de masquer.
  List<String> get hiddenCourses => _prefs.getStringList(_keyHiddenCourses) ?? const [];
  Future<void> setHiddenCourses(List<String> value) =>
      _prefs.setStringList(_keyHiddenCourses, value);

  /// Ordre complet des champs (CourseField.name), ou null si jamais défini.
  List<String>? get fieldOrder => _prefs.getStringList(_keyFieldOrder);
  Future<void> setFieldOrder(List<String> value) => _prefs.setStringList(_keyFieldOrder, value);

  /// Champs actuellement activés (CourseField.name), ou null si jamais défini.
  List<String>? get enabledFields => _prefs.getStringList(_keyEnabledFields);
  Future<void> setEnabledFields(List<String> value) =>
      _prefs.setStringList(_keyEnabledFields, value);

  /// Réinitialise tout ce qui est propre à un compte étudiant : le numéro
  /// lui-même, le flux ICS mis en cache et l'horodatage de dernière
  /// synchronisation. Les préférences d'apparence/affichage sont
  /// volontairement conservées (elles ne dépendent pas du compte).
  Future<void> clearAccountData() async {
    await clearStudentNumber();
    await clearCachedIcs();
    await _prefs.remove(_keyLastSync);
  }
}
