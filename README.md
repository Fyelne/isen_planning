# Planning ISEN

Application Flutter multiplateforme (Android, iOS, macOS, Windows, Linux) qui
récupère automatiquement l'emploi du temps d'un·e étudiant·e ISEN Ouest depuis
son flux ICS et l'affiche dans un calendrier moderne, personnalisable et
utilisable hors-ligne.

> ⚠️ **Projet non officiel**, développé indépendamment. Aucun lien avec
> l'ISEN Ouest ou son service informatique. Utilise uniquement le flux ICS
> public déjà exposé par l'ENT (`web.isen-ouest.fr/ICS/<numéro>.ics`).

## 📱 Aperçu

TODO: Screenshots

## 🚀 Démarrage rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable)
- Un IDE (VS Code, Android Studio...) avec les plugins Flutter/Dart
- Selon la plateforme ciblée : Xcode (iOS/macOS), Visual Studio avec le
  workload "Desktop development with C++" (Windows), ou les dépendances GTK
  (Linux — voir le workflow CI pour la liste exacte)

### Installation

```bash
git clone https://github.com/<votre-utilisateur>/isen_planning.git
cd isen_planning
flutter pub get
flutter run
```

### Build de production

```bash
flutter build apk --release       # Android
flutter build ios --release       # iOS (nécessite un compte Apple Developer)
flutter build macos --release     # macOS
flutter build windows --release   # Windows
flutter build linux --release     # Linux
```

## 🏗️ Architecture

Le projet suit le pattern **BLoC** (`flutter_bloc`), avec une séparation
claire entre données, logique métier et présentation :

| Bloc / Cubit | Rôle |
|---|---|
| `ScheduleBloc` | Chargement, rafraîchissement et cache du planning |
| `SettingsCubit` | Compte, thème, couleur d'accent, affichage, filtres |
| `CalendarNavigationCubit` | Jour actuellement affiché (partagé entre onglets) |
| `UpdateCubit` | Vérification de version via l'API GitHub Releases |

## ⚙️ Configuration

### Mise à jour automatique

Le workflow `.github/workflows/release.yml` compile automatiquement
Android/Windows/Linux et publie une GitHub Release à chaque tag `vX.Y.Z`
poussé :

```bash
git tag v1.1.0 && git push origin v1.1.0
```

## 🤝 Contribuer

Les contributions sont bienvenues !

Pour contribuer : forkez le dépôt, créez une branche, ouvrez une pull request.
