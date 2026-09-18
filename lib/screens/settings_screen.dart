import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';
import '../bloc/update/update_cubit.dart';
import '../bloc/update/update_state.dart';
import '../services/update_checker_service.dart';
import '../update_config.dart';
import 'display_fields_screen.dart';
import 'filter_courses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmChangeAccount(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer de compte ?'),
        content: const Text(
          "Le numéro étudiant actuel et le planning déjà téléchargé pour ce "
          "compte seront supprimés de l'appareil. Vous devrez ressaisir un "
          'numéro étudiant pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Changer de compte'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.changeAccount();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UpdateCubit(
        UpdateCheckerService(owner: kGithubOwner, repo: kGithubRepo),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Réglages')),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            final cubit = context.read<SettingsCubit>();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
              const _SectionTitle('Compte'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Numéro étudiant'),
                      subtitle: Text(settings.studentNumber ?? '-'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Changer de compte'),
                      subtitle: const Text('Efface le numéro étudiant et le planning téléchargé'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _confirmChangeAccount(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Apparence'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thème', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.smartphone_rounded),
                            label: Text('Système'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Clair'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Sombre'),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) => cubit.setThemeMode(selection.first),
                      ),
                      const SizedBox(height: 20),
                      Text("Couleur d'accent", style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: List.generate(kAccentPalette.length, (index) {
                          final color = kAccentPalette[index];
                          final selected = index == settings.accentColorIndex;
                          return GestureDetector(
                            onTap: () => cubit.setAccentColorIndex(index),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Affichage'),
              Card(
                child: SwitchListTile(
                  title: const Text('Masquer les week-ends'),
                  subtitle: const Text('Ne pas afficher samedi et dimanche'),
                  value: settings.hideWeekends,
                  onChanged: cubit.setHideWeekends,
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Contenu du planning'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('Informations affichées'),
                      subtitle: const Text('Aperçu de la grille et contenu de la fiche détaillée'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DisplayFieldsScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.filter_alt_outlined),
                      title: const Text('Filtrer les cours'),
                      subtitle: const Text('Masquer certains cours ou matières'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FilterCoursesScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('À propos'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Source des données'),
                      subtitle: Text('web.isen-ouest.fr'),
                    ),
                    const Divider(height: 1),
                    const _UpdateTile(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// Ligne "Vérifier les mises à jour" : compare la version installée à la
/// dernière release publiée sur GitHub (voir `lib/update_config.dart`).
/// Si une mise à jour est disponible, ouvre sa page GitHub dans le
/// navigateur plutôt que de tenter un téléchargement/une installation
/// automatique (plus sûr, et fonctionne de la même façon sur toutes les
/// plateformes desktop).
class _UpdateTile extends StatelessWidget {
  const _UpdateTile();

  Future<void> _openRelease(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir le lien de téléchargement.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final cubit = context.read<UpdateCubit>();

        IconData icon = Icons.system_update_alt_rounded;
        String title = 'Vérifier les mises à jour';
        String? subtitle = state.currentVersion != null
            ? 'Version installée : ${state.currentVersion}'
            : 'Comparer avec la dernière version publiée sur GitHub';
        Widget? trailing = const Icon(Icons.chevron_right_rounded);
        VoidCallback? onTap = cubit.checkForUpdate;

        switch (state.status) {
          case UpdateCheckStatus.idle:
            break;
          case UpdateCheckStatus.checking:
            icon = Icons.system_update_alt_rounded;
            title = 'Vérification en cours...';
            subtitle = null;
            trailing = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
            onTap = null;
            break;
          case UpdateCheckStatus.upToDate:
            icon = Icons.check_circle_outline_rounded;
            title = 'Vous utilisez la dernière version';
            subtitle = 'Version installée : ${state.currentVersion}';
            trailing = const Icon(Icons.refresh_rounded);
            break;
          case UpdateCheckStatus.updateAvailable:
            {
              final release = state.latestRelease!;
              icon = Icons.fiber_new_rounded;
              title = 'Mise à jour disponible : ${release.tagName}';
              subtitle = 'Version installée : ${state.currentVersion} · '
                  'toucher pour ouvrir la page de téléchargement';
              trailing = const Icon(Icons.open_in_new_rounded);
              onTap = () => _openRelease(context, release.htmlUrl);
            }
            break;
          case UpdateCheckStatus.error:
            icon = Icons.error_outline_rounded;
            title = 'Vérification impossible';
            subtitle = state.errorMessage ?? 'Réessayez plus tard.';
            trailing = const Icon(Icons.refresh_rounded);
            break;
        }

        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing,
          onTap: onTap,
        );
      },
    );
  }
}
