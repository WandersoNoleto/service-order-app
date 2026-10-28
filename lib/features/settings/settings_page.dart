import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import 'company_form_page.dart';
import 'data/company_profile.dart';
import 'widgets/company_logo.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  CompanyProfile? _profile;

  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _deps.settings.companyProfile(_deps.config);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyFormPage(dependencies: _deps, profile: _profile!),
      ),
    );
    if (saved ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_deps.config.isConfigured) const _NotConfiguredWarning(),
                _CompanyCard(
                  profile: profile,
                  dependencies: _deps,
                  onEdit: _edit,
                ),
              ],
            ),
    );
  }
}

/// Summary of the company data used on every OS.
class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.profile,
    required this.dependencies,
    required this.onEdit,
  });

  final CompanyProfile profile;
  final AppDependencies dependencies;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityState = [profile.companyCity, profile.companyState]
        .where((part) => part.isNotEmpty)
        .join(' - ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Empresa', style: theme.textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CompanyLogo(
              logos: dependencies.logos,
              customLogoFile: profile.customLogoFile,
              fallbackAsset: profile.defaultLogoAsset,
            ),
            const SizedBox(height: 12),
            Text(profile.companyName, style: theme.textTheme.bodyLarge),
            if (profile.companyDocument.isNotEmpty)
              Text('CNPJ: ${profile.companyDocument}'),
            if (profile.companyPhone.isNotEmpty) Text(profile.companyPhone),
            if (profile.companyAddress.isNotEmpty) Text(profile.companyAddress),
            if (cityState.isNotEmpty) Text(cityState),
            if (profile.responsibleName.isNotEmpty)
              Text('Responsável: ${profile.responsibleName}'),
            const SizedBox(height: 8),
            Text(
              'Estes dados aparecem no cabeçalho de todas as OSs.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotConfiguredWarning extends StatelessWidget {
  const _NotConfiguredWarning();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'App iniciado sem configuração de cliente. '
          'Rode com --dart-define-from-file=clients/<pasta>/config.json.',
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
