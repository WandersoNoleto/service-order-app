import 'package:flutter/material.dart';

import '../../core/config/client_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.config});

  final ClientConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!config.isConfigured) const _NotConfiguredWarning(),
          _CompanyCard(config: config),
        ],
      ),
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
