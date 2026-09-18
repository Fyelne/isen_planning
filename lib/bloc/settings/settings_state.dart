import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

const List<Color> kAccentPalette = [
  Color(0xFF3D5AFE),
  Color(0xFF7C4DFF),
  Color(0xFF00BFA5),
  Color(0xFFFF6D00),
  Color(0xFFE53935),
  Color(0xFF00ACC1),
];

/// Informations affichables sur une carte de cours. L'utilisateur choisit
/// lesquelles sont visibles et dans quel ordre elles apparaissent.
enum CourseField { time, location, courseName, subject, activityType, teachers, details }

extension CourseFieldX on CourseField {
  String get label => switch (this) {
        CourseField.time => 'Heure',
        CourseField.location => 'Salle',
        CourseField.courseName => 'Nom du cours',
        CourseField.subject => 'Matière',
        CourseField.activityType => "Type d'activité",
        CourseField.teachers => 'Intervenant(s)',
        CourseField.details => 'Description',
      };

  IconData get icon => switch (this) {
        CourseField.time => Icons.schedule_rounded,
        CourseField.location => Icons.place_outlined,
        CourseField.courseName => Icons.menu_book_outlined,
        CourseField.subject => Icons.category_outlined,
        CourseField.activityType => Icons.local_activity_outlined,
        CourseField.teachers => Icons.person_outline_rounded,
        CourseField.details => Icons.notes_rounded,
      };
}

/// Ordre et visibilité par défaut : seuls l'heure, la salle et le nom du
/// cours sont affichés tant que l'utilisateur ne personnalise rien.
const List<CourseField> kDefaultFieldOrder = CourseField.values;
const Set<CourseField> kDefaultEnabledFields = {
  CourseField.time,
  CourseField.location,
  CourseField.courseName,
  CourseField.subject,
  CourseField.activityType,
  CourseField.teachers,
  CourseField.details,
};

class SettingsState extends Equatable {
  final bool isInitialized;
  final String? studentNumber;
  final ThemeMode themeMode;
  final int accentColorIndex;
  final bool hideWeekends;
  final List<CourseField> displayFieldOrder;
  final Set<CourseField> enabledFields;
  final Set<String> hiddenCourses;

  const SettingsState({
    this.isInitialized = false,
    this.studentNumber,
    this.themeMode = ThemeMode.system,
    this.accentColorIndex = 0,
    this.hideWeekends = true,
    this.displayFieldOrder = kDefaultFieldOrder,
    this.enabledFields = kDefaultEnabledFields,
    this.hiddenCourses = const {},
  });

  Color get accentColor => kAccentPalette[accentColorIndex % kAccentPalette.length];

  SettingsState copyWith({
    bool? isInitialized,
    String? studentNumber,
    bool clearStudentNumber = false,
    ThemeMode? themeMode,
    int? accentColorIndex,
    bool? hideWeekends,
    List<CourseField>? displayFieldOrder,
    Set<CourseField>? enabledFields,
    Set<String>? hiddenCourses,
  }) {
    return SettingsState(
      isInitialized: isInitialized ?? this.isInitialized,
      studentNumber: clearStudentNumber ? null : (studentNumber ?? this.studentNumber),
      themeMode: themeMode ?? this.themeMode,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      hideWeekends: hideWeekends ?? this.hideWeekends,
      displayFieldOrder: displayFieldOrder ?? this.displayFieldOrder,
      enabledFields: enabledFields ?? this.enabledFields,
      hiddenCourses: hiddenCourses ?? this.hiddenCourses,
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        studentNumber,
        themeMode,
        accentColorIndex,
        hideWeekends,
        displayFieldOrder,
        enabledFields,
        hiddenCourses,
      ];
}
