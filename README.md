# Mon Planning ISEN

Application Flutter (macOS, iOS, Android, Linux, Windows) qui récupère et affiche
l'emploi du temps d'un étudiant ISEN Ouest à partir de son flux ICS :

```
https://web.isen-ouest.fr/ICS/<numero_etudiant>.ics
```

## Architecture

Le projet suit le pattern **BLoC** (`flutter_bloc`) :

- `ScheduleBloc` : chargement, rafraîchissement et cache du planning.
- `SettingsCubit` : numéro étudiant, thème, couleur d'accent, week-ends, informations affichées.
- `CalendarNavigationCubit` : jour actuellement affiché, partagé entre l'onglet
  Planning et l'onglet Recherche.
- `ScheduleRepository` : appel réseau + cache local (fonctionne hors-ligne avec les
  dernières données synchronisées).
- `IcsParser` : parseur ICS "maison", sans dépendance externe.

```
lib/
  main.dart              # point d'entrée
  app.dart                # providers BLoC + routage onboarding/shell
  app_theme.dart           # thèmes clair/sombre Material 3
  models/course_event.dart
  data/
    ics_parser.dart
    schedule_repository.dart
  services/preferences_service.dart   # persistance (SharedPreferences)
  bloc/
    schedule/  (bloc, event, state)
    settings/  (cubit, state)
    calendar/calendar_navigation_cubit.dart
  screens/
    onboarding_screen.dart      # saisie du numéro étudiant (mémorisé) + aide
    main_shell.dart              # barre de navigation basse (3 onglets)
    home_screen.dart             # onglet Planning : bascule jour/semaine, swipe, F5
    search_course_screen.dart    # onglet Recherche : prochain cours d'une matière
    settings_screen.dart         # onglet Réglages
    display_fields_screen.dart   # infos affichées (grille + fiche détaillée)
    filter_courses_screen.dart   # masquer certains cours
  widgets/
    day_strip.dart               # bandeau de dates (vue jour)
    empty_state.dart
    calendar/
      time_grid_metrics.dart     # plage horaire, hauteur d'heure
      event_layout.dart          # répartition des cours qui se chevauchent
      hour_gutter.dart           # graduations horaires
      calendar_event_tile.dart   # bloc de cours compact dans la grille
      day_grid_column.dart       # une colonne de jour (quadrillage + cours)
      day_calendar_view.dart     # vue jour (téléphone portrait)
      week_calendar_view.dart    # vue semaine (grand écran / paysage)
      course_detail_sheet.dart   # fiche détaillée au tap sur un cours
```

## Fonctionnalités

- Saisie et **mémorisation du numéro étudiant** (`shared_preferences`), avec
  une aide intégrée (bouton "?") expliquant comment retrouver son numéro
  étudiant et activer l'agenda à distance sur l'ENT.
- Récupération et **parsing du flux ICS**, y compris la zone `DESCRIPTION`
  structurée des exports ADE (`Matière`, `Cours`, `Activité`,
  `Intervenant(s)`, `Description`).
- **Barre de navigation basse à 3 onglets** : Planning, Recherche, Réglages,
  gardés en mémoire (`IndexedStack`) pour ne pas perdre leur état en changeant
  d'onglet. Ré-appuyer sur l'onglet Planning alors qu'il est déjà sélectionné
  ramène le calendrier à la date du jour.
- **Calendrier avec quadrillage horaire**, dans le format "classique" (grille
  heure par heure, cours positionnés par horaire, chevauchements répartis en
  colonnes) plutôt qu'une liste d'événements :
  - **Vue semaine** sur grand écran (PC, Mac, tablette, téléphone en paysage
    ≥ 600dp de large) : une colonne par jour, navigation semaine précédente
    / suivante.
  - **Vue jour** sur téléphone en portrait (< 600dp) : une seule colonne,
    sélection du jour via le bandeau de dates.
  - **Swipe gauche/droite** sur le calendrier pour changer de jour (vue jour)
    ou de semaine (vue semaine).
  - Un tap sur un cours ouvre une fiche détaillée (date, heure, salle toujours
    visibles ; matière, type d'activité, intervenant(s) et description
    affichés selon les réglages).
  - Ligne "maintenant" affichée sur le jour courant.
- **Rafraîchissement manuel** : glisser vers le bas (pull-to-refresh, tactile) ou
  appuyer sur **F5** (desktop/web), comme dans un navigateur.
- **Mode hors-ligne** : dernières données conservées en cache si le réseau échoue ;
  le message rappelle que l'activation de l'agenda distant peut prendre ~24h.
- **Informations affichées personnalisables** (Réglages → Informations
  affichées), en deux groupes indépendants :
  - *Aperçu sur la grille* : heure, salle (le nom du cours est toujours visible).
  - *Fiche détaillée (au tap)* : matière, type d'activité, intervenant(s),
    description (date/heure/salle toujours visibles).
- **Filtrage des cours** (Réglages → Filtrer les cours) : masquer certains
  cours précis, regroupés par matière, sans les supprimer des données.
- **Recherche du prochain cours** (onglet Recherche) : rechercher une matière et
  afficher sa prochaine occurrence (date, heure, salle), avec un raccourci
  qui bascule sur l'onglet Planning à ce jour.
- Bouton **"Aujourd'hui"** dans l'AppBar du planning pour revenir instantanément
  à la date du jour.
- **Support souris (desktop)** : glisser-cliquer et molette pour faire défiler
  le bandeau de jours, bouton "retour" latéral de la souris pour revenir à
  l'écran précédent.
- Personnalisation : thème clair/sombre/système, couleur d'accent, masquage des
  week-ends (activé par défaut).

## Mise en place

1. Créer le squelette de projet multi-plateformes avec le SDK Flutter installé
   sur votre machine :

   ```bash
   flutter create -t app --platforms=macos,ios,android,linux,windows isen_planning
   cd isen_planning
   ```

2. Remplacer le `pubspec.yaml` généré et le dossier `lib/` par ceux de cette
   archive (conservez les dossiers `android/`, `ios/`, `macos/`, `linux/`,
   `windows/` générés à l'étape 1).

3. Installer les dépendances :

   ```bash
   flutter pub get
   ```

4. Autoriser l'accès réseau sortant sur desktop :

   - **macOS** : dans `macos/Runner/DebugProfile.entitlements` et
     `macos/Runner/Release.entitlements`, ajoutez :
     ```xml
     <key>com.apple.security.network.client</key>
     <true/>
     ```
   - **iOS / Android** : rien à faire, HTTPS sortant autorisé par défaut.
   - **Linux / Windows** : aucune configuration supplémentaire nécessaire.

5. Lancer l'application :

   ```bash
   flutter run
   ```

## Notes

- Le numéro étudiant est demandé une seule fois (écran d'onboarding) puis mémorisé.
  Il ne peut être changé qu'en passant par **Réglages → Changer de compte**
  (avec confirmation) : cela efface aussi le planning mis en cache pour
  repartir sur des données propres avec le nouveau compte.
- Le raccourci **F5** ne fonctionne que sur les plateformes disposant d'un
  clavier physique (Windows, macOS, Linux) ; le geste de glissement vers le bas
  fonctionne partout.

## Changer le nom et l'icône de l'application

### Nom affiché

**Méthode automatisée (recommandée)** : ce projet inclut le package
[`rename`](https://pub.dev/packages/rename) en dev_dependency. Une fois le
squelette généré (`flutter create`) :

```bash
flutter pub get
dart run rename setAppName --targets ios,android,macos,windows,linux --value "Mon Planning ISEN"
```

**Méthode manuelle**, fichier par fichier :

| Plateforme | Fichier | Ce qu'il faut changer |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `android:label="..."` sur `<application>` |
| iOS | `ios/Runner/Info.plist` | `CFBundleName` et `CFBundleDisplayName` |
| macOS | `macos/Runner/Configs/AppInfo.xcconfig` | `PRODUCT_NAME = ...` |
| Windows | `windows/runner/Runner.rc` | `FileDescription` et `ProductName` |
| Linux | `linux/CMakeLists.txt` (variable `BINARY_NAME`) et `linux/runner/my_application.cc` (titre de fenêtre) |

Le champ `name:` du `pubspec.yaml` n'affecte que l'identifiant du projet Dart,
jamais le nom vu par l'utilisateur.

### Bundle ID / Application ID

**Méthode automatisée (recommandée)**, avec le même package `rename` — évite
d'oublier une des 3 occurrences dans le fichier de projet Xcode :

```bash
dart run rename setBundleId --targets ios,android,macos --value "com.fyelne.isen_planning"
```

**Méthode manuelle** :

| Plateforme | Fichier(s) |
|---|---|
| Android | `android/app/build.gradle` : `applicationId` et `namespace`. Il faut aussi **déplacer** `MainActivity.kt` de `android/app/src/main/kotlin/com/example/.../` vers le nouveau chemin de package, et mettre à jour la ligne `package ...` en tête de ce fichier. |
| iOS | `ios/Runner.xcodeproj/project.pbxproj` (3 occurrences de `PRODUCT_BUNDLE_IDENTIFIER`), ou plus sûr via Xcode : cible *Runner* → *Signing & Capabilities* → *Bundle Identifier*. |
| macOS | Même chose dans `macos/Runner.xcodeproj/project.pbxproj` et `macos/Runner/Configs/AppInfo.xcconfig`. |
| Windows / Linux | Pas d'équivalent direct (concept propre à Android/Apple) ; ne s'applique qu'au packaging MSIX/Flatpak/Snap si utilisé. |

### Icône

Ce projet est préconfiguré avec [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
pour générer automatiquement l'icône sur Android, iOS, macOS et Windows :

1. Placez un PNG carré (1024×1024 recommandé) dans `assets/icon/icon.png`.
2. `flutter pub get`
3. `dart run flutter_launcher_icons`

**Linux** n'est pas pris en charge par cet outil : il faut fournir l'icône
manuellement (ex. `linux/my_app.png`) et la référencer dans le fichier
`.desktop` de l'application (clé `Icon=`) généré lors du packaging.
