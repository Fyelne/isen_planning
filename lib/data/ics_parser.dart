import '../models/course_event.dart';

/// Champs extraits de la zone DESCRIPTION structurée des exports ADE, du
/// type :
/// ```
/// - Matière : DP GL
/// - Cours : Génie logiciel S9
/// - Activité : COURS
/// - Intervenant(s) : Sébastien LE COCQUEN
/// - Description : IDE, gestion de version, qualité...
/// ```
class _ParsedDescription {
  final String? subject;
  final String? courseName;
  final String? activityType;
  final List<String> teachers;
  final String? details;

  const _ParsedDescription({
    this.subject,
    this.courseName,
    this.activityType,
    this.teachers = const [],
    this.details,
  });
}

/// Un parseur léger, sans dépendance externe, pour le sous-ensemble du
/// format iCalendar (RFC 5545) utilisé par les exports ADE / ISEN Ouest.
class IcsParser {
  const IcsParser();

  List<CourseEvent> parse(String icsContent) {
    final lines = _unfoldLines(icsContent);

    final events = <CourseEvent>[];
    Map<String, String>? current;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line == 'BEGIN:VEVENT') {
        current = <String, String>{};
        continue;
      }
      if (line == 'END:VEVENT') {
        if (current != null) {
          final event = _buildEvent(current);
          if (event != null) events.add(event);
        }
        current = null;
        continue;
      }
      if (current == null || line.isEmpty) continue;

      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) continue;

      final rawKey = line.substring(0, separatorIndex);
      final value = line.substring(separatorIndex + 1);
      final key = rawKey.split(';').first.toUpperCase();

      current[key] = _unescape(value);
    }

    events.sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  /// RFC5545 autorise les lignes longues à être "repliées" sur plusieurs
  /// lignes physiques commençant par une espace ou une tabulation. On les
  /// rassemble ici.
  List<String> _unfoldLines(String content) {
    final rawLines = content.replaceAll('\r\n', '\n').split('\n');
    final result = <String>[];
    for (final line in rawLines) {
      if (line.isEmpty) continue;
      if ((line.startsWith(' ') || line.startsWith('\t')) && result.isNotEmpty) {
        result[result.length - 1] += line.substring(1);
      } else {
        result.add(line);
      }
    }
    return result;
  }

  String _unescape(String value) {
    return value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\N', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', r'\');
  }

  CourseEvent? _buildEvent(Map<String, String> fields) {
    final dtStart = fields['DTSTART'];
    final dtEnd = fields['DTEND'];
    if (dtStart == null || dtEnd == null) return null;

    final start = _parseDate(dtStart);
    final end = _parseDate(dtEnd);
    if (start == null || end == null) return null;

    final uid = fields['UID'] ?? '$dtStart-${fields['SUMMARY'] ?? ''}';
    final parsedDescription = _parseDescription(fields['DESCRIPTION']);

    return CourseEvent(
      uid: uid,
      summary: (fields['SUMMARY'] ?? 'Cours').trim(),
      location: fields['LOCATION']?.trim(),
      start: start,
      end: end,
      subject: parsedDescription.subject,
      courseName: parsedDescription.courseName,
      activityType: parsedDescription.activityType,
      teachers: parsedDescription.teachers,
      details: parsedDescription.details,
    );
  }

  /// Découpe le contenu structuré du champ DESCRIPTION en champs nommés
  /// (Matière, Cours, Activité, Intervenant(s), Description).
  _ParsedDescription _parseDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const _ParsedDescription();

    String? subject;
    String? courseName;
    String? activityType;
    List<String> teachers = const [];
    String? details;

    for (final rawSegment in raw.split('\n')) {
      var segment = rawSegment.trim();
      if (segment.isEmpty) continue;
      if (segment.startsWith('-')) segment = segment.substring(1).trim();

      final sepIndex = segment.indexOf(':');
      if (sepIndex == -1) continue;

      final key = segment.substring(0, sepIndex).trim().toLowerCase();
      final value = segment.substring(sepIndex + 1).trim();
      if (value.isEmpty) continue;

      if (key.startsWith('matière') || key.startsWith('matiere')) {
        subject = value;
      } else if (key.startsWith('cours')) {
        courseName = value;
      } else if (key.startsWith('activité') || key.startsWith('activite')) {
        activityType = value;
      } else if (key.startsWith('intervenant')) {
        teachers = value
            .split('/')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (key.startsWith('description')) {
        details = value;
      }
    }

    return _ParsedDescription(
      subject: subject,
      courseName: courseName,
      activityType: activityType,
      teachers: teachers,
      details: details,
    );
  }

  /// Analyse les dates dans les deux formats produits par les exports ADE :
  ///  - `20240115T080000Z` (UTC)
  ///  - `20240115T080000` (heure locale/flottante)
  DateTime? _parseDate(String value) {
    final cleaned = value.trim();
    if (cleaned.length < 15) return null;

    try {
      final year = int.parse(cleaned.substring(0, 4));
      final month = int.parse(cleaned.substring(4, 6));
      final day = int.parse(cleaned.substring(6, 8));
      final hour = int.parse(cleaned.substring(9, 11));
      final minute = int.parse(cleaned.substring(11, 13));
      final second = int.parse(cleaned.substring(13, 15));

      if (cleaned.endsWith('Z')) {
        return DateTime.utc(year, month, day, hour, minute, second).toLocal();
      }
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
}
