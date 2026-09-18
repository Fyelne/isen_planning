import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course_event.dart';
import '../services/preferences_service.dart';
import 'ics_parser.dart';

class ScheduleFetchResult {
  final List<CourseEvent> events;
  final DateTime lastUpdated;
  final bool fromCache;

  const ScheduleFetchResult({
    required this.events,
    required this.lastUpdated,
    required this.fromCache,
  });
}

class ScheduleRepositoryException implements Exception {
  final String message;
  const ScheduleRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Récupère et parse le calendrier ICS exposé par ISEN Ouest pour un numéro
/// étudiant donné, avec un cache local utilisé en secours hors ligne.
class ScheduleRepository {
  ScheduleRepository({
    required PreferencesService preferencesService,
    http.Client? httpClient,
    IcsParser? parser,
  })  : _prefs = preferencesService,
        _client = httpClient ?? http.Client(),
        _parser = parser ?? const IcsParser();

  final PreferencesService _prefs;
  final http.Client _client;
  final IcsParser _parser;

  static const _baseUrl = 'https://web.isen-ouest.fr/ICS';

  Uri _urlFor(String studentNumber) => Uri.parse('$_baseUrl/$studentNumber.ics');

  Future<ScheduleFetchResult> fetchSchedule(String studentNumber) async {
    try {
      final response = await _client
          .get(_urlFor(studentNumber))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw ScheduleRepositoryException(
          "Impossible de récupérer l'emploi du temps (code ${response.statusCode}).",
        );
      }

      // Le serveur ISEN ne déclare pas toujours correctement son charset ;
      // `response.body` peut alors être mal décodé (ex : "é" -> "Ã©"). On
      // force donc un décodage UTF-8 explicite des octets bruts.
      final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      if (decodedBody.trim().isEmpty) {
        throw const ScheduleRepositoryException(
          "Le fichier de planning reçu est vide.",
        );
      }

      final events = _parser.parse(decodedBody);
      final now = DateTime.now();

      await _prefs.setCachedIcs(decodedBody);
      await _prefs.setLastSync(now);

      return ScheduleFetchResult(events: events, lastUpdated: now, fromCache: false);
    } on ScheduleRepositoryException {
      return _fallbackToCache();
    } catch (_) {
      return _fallbackToCache();
    }
  }

  Future<ScheduleFetchResult> _fallbackToCache() async {
    final cached = _prefs.cachedIcs;
    final lastSync = _prefs.lastSync;
    if (cached == null || lastSync == null) {
      throw ScheduleRepositoryException(_unavailableMessage());
    }
    return ScheduleFetchResult(
      events: _parser.parse(cached),
      lastUpdated: lastSync,
      fromCache: true,
    );
  }

  /// `identical(0, 0.0)` n'est vrai que sur le web (où `int` et `double`
  /// partagent la même représentation) : c'est la même astuce que
  /// `kIsWeb` de Flutter, reprise ici pour ne pas faire dépendre ce
  /// fichier du framework Flutter.
  static const bool _isWeb = identical(0, 0.0);

  String _unavailableMessage() {
    const base = "Connexion impossible et aucune donnée locale disponible. "
        "Vérifiez que l'agenda à distance est activé sur l'ENT : "
        "l'activation prend généralement environ 24h avant que les cours "
        "soient disponibles.";
    if (_isWeb) {
      return '$base Sur navigateur web, le serveur ISEN ne fournit pas les '
          "en-têtes d'autorisation nécessaires (CORS), ce qui bloque "
          "l'accès direct : utilisez plutôt l'application mobile ou de "
          'bureau.';
    }
    return base;
  }
}
