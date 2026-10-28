import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/config/client_config.dart';
import 'data/company_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _responsibleName;

  ClientConfig get _config => widget.dependencies.config;

  @override
  void initState() {
    super.initState();
    _loadResponsible();
  }

  Future<void> _loadResponsible() async {
    final profile = await widget.dependencies.settings.companyProfile(_config);
    if (!mounted) return;
    setState(() => _responsibleName = profile.responsibleName);
  }

  Future<void> _editResponsible() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _ResponsibleDialog(initialName: _responsibleName ?? ''),
    );

    if (name == null || name.trim().isEmpty) return;
    await widget.dependencies.settings.saveCompanyFields(
      _config,
      {CompanyField.responsible: name},
    );
    await _loadResponsible();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_config.isConfigured) const _NotConfiguredWarning(),
          _CompanyCard(config: _config),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Responsável'),
              subtitle: Text(_responsibleName ?? '…'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _responsibleName == null ? null : _editResponsible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns its text controller so it is disposed only after the dialog's
/// closing animation. Pops with the typed name, or null on cancel.
class _ResponsibleDialog extends StatefulWidget {
  const _ResponsibleDialog({required this.initialName});

  final String initialName;

  @override
  State<_ResponsibleDialog> createState() => _ResponsibleDialogState();
}

class _ResponsibleDialogState extends State<_ResponsibleDialog> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Responsável'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nome'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.config});

  final ClientConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empresa', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: config.logoAsset.isEmpty
                  ? const _LogoMissing()
                  : Image.asset(
                      config.logoAsset,
                      errorBuilder: (_, _, _) => const _LogoMissing(),
                    ),
            ),
            const SizedBox(height: 16),
            Text(config.companyName, style: theme.textTheme.bodyLarge),
            if (config.companyDocument.isNotEmpty)
              Text('CNPJ: ${config.companyDocument}'),
            if (config.companyPhone.isNotEmpty) Text(config.companyPhone),
            if (config.companyAddress.isNotEmpty) Text(config.companyAddress),
            if (config.companyCity.isNotEmpty)
              Text('${config.companyCity} - ${config.companyState}'),
          ],
        ),
      ),
    );
  }
}

class _LogoMissing extends StatelessWidget {
  const _LogoMissing();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Row(
      children: [
        Icon(Icons.image_not_supported_outlined, color: color),
        const SizedBox(width: 8),
        Text('Logo não encontrada', style: TextStyle(color: color)),
      ],
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
