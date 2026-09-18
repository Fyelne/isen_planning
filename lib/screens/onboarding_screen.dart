import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings/settings_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<SettingsCubit>().setStudentNumber(_controller.text.trim());
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => const _HelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Aide',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelp,
          ),
          const SizedBox(width: 4),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      'Mon Planning ISEN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Entrez votre numéro étudiant pour récupérer automatiquement "
                      "votre emploi du temps depuis l'ENT ISEN Ouest.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Numéro étudiant',
                        hintText: 'ex : 13811188',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre numéro étudiant';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continuer'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _showHelp,
                      icon: const Icon(Icons.help_outline_rounded, size: 18),
                      label: const Text('Je ne connais pas mon numéro étudiant'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Feuille d'aide expliquant comment trouver son numéro étudiant et activer
/// l'agenda à distance sur l'ENT, pour que le flux ICS soit accessible.
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  static const _entUrl = 'https://web.isen-ouest.fr/webAurion/';

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _entUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papiers')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Besoin d'aide ?", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                "Deux choses à vérifier avant de pouvoir récupérer votre planning.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // --- Section 1 : trouver son numéro étudiant ---------------
              Row(
                children: [
                  Icon(Icons.badge_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connaître son numéro étudiant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _HelpStep(
                number: 1,
                text: 'Rechercher "ISEN : Passeport Informatique" dans votre boîte mail.',
              ),
              const _HelpStep(
                number: 2,
                text: "Ouvrir cet e-mail et copier le Code PIN indiqué : "
                    "c'est votre numéro étudiant.",
              ),

              const SizedBox(height: 28),

              // --- Section 2 : activer l'agenda à distance ----------------
              Row(
                children: [
                  Icon(Icons.sync_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Activer son agenda à distance",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _HelpStep(
                number: 1,
                text: "Se rendre sur l'ENT : ",
                trailing: InkWell(
                  onTap: () => _copyLink(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _entUrl,
                            style: TextStyle(
                              color: scheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 15, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const _HelpStep(
                number: 2,
                text: 'Dans la barre latérale : "Mon Compte" > "Mes informations".',
              ),
              const _HelpStep(
                number: 3,
                text: 'En bas de la page, cliquer sur "Modifier".',
              ),
              const _HelpStep(
                number: 4,
                text: 'Cocher la case "Autoriser les inscriptions distantes à mon planning".',
              ),
              const _HelpStep(
                number: 5,
                text: 'Cliquer sur "Valider la saisie".',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "L'activation de l'agenda peut prendre plusieurs heures : "
                        "il est conseillé d'attendre 24h le temps que les cours "
                        "soient disponibles.",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Compris'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.number, required this.text, this.trailing});

  final int number;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
