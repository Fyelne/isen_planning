/// Coordonnées du dépôt GitHub utilisé pour la vérification de mise à jour
/// (Réglages → Vérifier les mises à jour). À adapter à votre dépôt.
///
/// L'application interroge :
///   https://api.github.com/repos/<kGithubOwner>/<kGithubRepo>/releases/latest
///
/// Pour que cela fonctionne, publiez vos versions sous forme de "Release"
/// GitHub (pas seulement un tag), avec un tag au format "v1.2.3" ou "1.2.3" —
/// voir `.github/workflows/release.yml` pour un pipeline qui l'automatise.
const String kGithubOwner = 'fyelne';
const String kGithubRepo = 'isen_planning';
