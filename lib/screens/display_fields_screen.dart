import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/settings_cubit.dart';
import '../bloc/settings/settings_state.dart';

/// Deux groupes de réglages bien distincts :
/// - l'aperçu affiché directement sur les blocs de la grille horaire
///   (heure, salle) ;
/// - le contenu de la fiche détaillée ouverte en tapant sur un cours
///   (matière, type d'activité, intervenant(s), description). Le nom du
///   cours, la date, l'heure et la salle y sont toujours visibles.
class DisplayFieldsScreen extends StatelessWidget {
  const DisplayFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations affichées')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final cubit = context.read<SettingsCubit>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Aperçu sur la grille',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Le nom du cours est toujours affiché. Choisissez les '
                "informations supplémentaires visibles directement sur les "
                "blocs du planning.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(CourseField.time.icon),
                      title: Text(CourseField.time.label),
                      subtitle: const Text("Affiche l'heure de début sur chaque cours"),
                      value: settings.enabledFields.contains(CourseField.time),
                      onChanged: (value) => cubit.setFieldEnabled(CourseField.time, value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(CourseField.location.icon),
                      title: Text(CourseField.location.label),
                      subtitle: const Text('Affiche la salle si le bloc est assez grand'),
                      value: settings.enabledFields.contains(CourseField.location),
                      onChanged: (value) => cubit.setFieldEnabled(CourseField.location, value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Fiche détaillée (au tap sur un cours)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'La date, l\'heure et la salle sont toujours affichées dans '
                'cette fiche. Choisissez les informations complémentaires à '
                'y faire apparaître.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(CourseField.subject.icon),
                      title: Text(CourseField.subject.label),
                      value: settings.enabledFields.contains(CourseField.subject),
                      onChanged: (value) => cubit.setFieldEnabled(CourseField.subject, value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(CourseField.activityType.icon),
                      title: Text(CourseField.activityType.label),
                      value: settings.enabledFields.contains(CourseField.activityType),
                      onChanged: (value) =>
                          cubit.setFieldEnabled(CourseField.activityType, value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(CourseField.teachers.icon),
                      title: Text(CourseField.teachers.label),
                      value: settings.enabledFields.contains(CourseField.teachers),
                      onChanged: (value) => cubit.setFieldEnabled(CourseField.teachers, value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(CourseField.details.icon),
                      title: Text(CourseField.details.label),
                      subtitle: const Text('Le texte libre saisi par le service scolarité'),
                      value: settings.enabledFields.contains(CourseField.details),
                      onChanged: (value) => cubit.setFieldEnabled(CourseField.details, value),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
