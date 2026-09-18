import 'dart:convert';

import 'package:http/http.dart' as http;

/// Une release GitHub, telle que renvoyée par l'API REST publique
/// (`GET /repos/{owner}/{repo}/releases/latest`).
class GithubRelease {
  final String tagName;
  final String htmlUrl;
  final String? notes;
  final List<GithubReleaseAsset> assets;

  const GithubRelease({
    required this.tagName,
    required this.htmlUrl,
    this.notes,
    this.assets = const [],
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    return GithubRelease(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      notes: json['body'] as String?,
      assets: (json['assets'] as List<dynamic>? ?? [])
          .map((a) => GithubReleaseAsset.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Un fichier attaché à une release (APK, installeur .exe, .dmg, etc.).
class GithubReleaseAsset {
  final String name;
  final String downloadUrl;

  const GithubReleaseAsset({required this.name, required this.downloadUrl});

  factory GithubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GithubReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
    );
  }
}

class UpdateCheckException implements Exception {
  final String message;
  const UpdateCheckException(this.message);

  @override
  String toString() => message;
}

/// Interroge l'API publique GitHub pour connaître la dernière release d'un
/// dépôt. Ne nécessite aucune authentification (limite de taux plus basse
/// pour les appels anonymes, largement suffisante pour une vérification
/// occasionnelle déclenchée par l'utilisateur).
class UpdateCheckerService {
  UpdateCheckerService({
    required this.owner,
    required this.repo,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// Propriétaire du dépôt GitHub (utilisateur ou organisation).
  final String owner;

  /// Nom du dépôt GitHub.
  final String repo;

  final http.Client _client;

  Uri get _latestReleaseUrl =>
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');

  Future<GithubRelease> fetchLatestRelease() async {
    final http.Response response;
    try {
      response = await _client
          .get(_latestReleaseUrl, headers: const {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw const UpdateCheckException('Impossible de contacter GitHub.');
    }

    if (response.statusCode == 404) {
      throw const UpdateCheckException('Aucune release publiée sur ce dépôt.');
    }
    if (response.statusCode != 200) {
      throw UpdateCheckException(
        'Réponse inattendue de GitHub (code ${response.statusCode}).',
      );
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return GithubRelease.fromJson(json);
    } catch (_) {
      throw const UpdateCheckException('Réponse GitHub illisible.');
    }
  }
}

/// Compare deux versions au format "x.y.z" (un préfixe "v" éventuel est
/// ignoré, tout comme un suffixe non numérique comme "-beta"). Renvoie vrai
/// si [remote] est strictement plus récente que [local].
bool isNewerVersion(String remote, String local) {
  final r = _parseVersion(remote);
  final l = _parseVersion(local);
  for (var i = 0; i < r.length && i < l.length; i++) {
    if (r[i] != l[i]) return r[i] > l[i];
  }
  return false;
}

List<int> _parseVersion(String version) {
  final cleaned = version.startsWith('v') || version.startsWith('V')
      ? version.substring(1)
      : version;
  final numericPart = cleaned.split('-').first.split('+').first;
  final segments = numericPart.split('.');
  final parsed = segments.map((s) => int.tryParse(s) ?? 0).toList();
  while (parsed.length < 3) {
    parsed.add(0);
  }
  return parsed;
}
