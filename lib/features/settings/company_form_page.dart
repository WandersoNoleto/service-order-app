import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import 'data/company_profile.dart';
import 'widgets/company_logo.dart';

/// Edits the company data (and logo) shown on every OS.
///
/// Each field shows its build default when changed, with a button to go
/// back to it. Pops with `true` when something was saved.
class CompanyFormPage extends StatefulWidget {
  const CompanyFormPage({
    super.key,
    required this.dependencies,
    required this.profile,
  });

  final AppDependencies dependencies;
  final CompanyProfile profile;

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

enum _MenuAction { resetAll }

class _CompanyFormPageState extends State<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final Map<CompanyField, TextEditingController> _controllers = {
    for (final field in CompanyField.values)
      field: TextEditingController(text: widget.profile.value(field))
        ..addListener(() => setState(() {})),
  };

  /// Logo the form will save: a file name, or null for the bundled logo.
  late String? _logoFile = widget.profile.customLogoFile;
  bool _saving = false;

  AppDependencies get _deps => widget.dependencies;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final fileName = await _deps.logos.pickAndImport();
      if (fileName != null) setState(() => _logoFile = fileName);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar a imagem: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await _deps.settings.saveCompanyFields(_deps.config, {
      for (final MapEntry(key: field, value: controller) in _controllers.entries)
        field: controller.text,
    });
    if (_logoFile != widget.profile.customLogoFile) {
      await _deps.settings.setCustomLogoFile(_logoFile);
    }
    // Removes logos imported but not kept (replaced or cancelled earlier).
    await _deps.logos.deleteAllExcept(_logoFile);

    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar tudo?'),
        content: const Text(
          'Todos os dados e a logo voltam ao que veio configurado no app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    await _deps.settings.resetCompany();
    await _deps.logos.deleteAllExcept(null);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da empresa'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => switch (action) {
              _MenuAction.resetAll => _resetAll(),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAction.resetAll,
                child: Text('Restaurar tudo para o padrão'),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LogoSection(
              dependencies: _deps,
              logoFile: _logoFile,
              fallbackAsset: widget.profile.defaultLogoAsset,
              onPick: _pickLogo,
              onRestore: _logoFile == null
                  ? null
                  : () => setState(() => _logoFile = null),
            ),
            const SizedBox(height: 16),
            _field(
              CompanyField.name,
              'Nome da empresa',
              validator: (text) => (text ?? '').trim().isEmpty
                  ? 'Informe o nome da empresa'
                  : null,
            ),
            _field(CompanyField.document, 'CNPJ'),
            _field(
              CompanyField.phone,
              'Telefone / WhatsApp',
              keyboard: TextInputType.phone,
            ),
            _field(CompanyField.address, 'Endereço'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(flex: 3, child: _field(CompanyField.city, 'Cidade')),
                Expanded(child: _field(CompanyField.state, 'UF')),
              ],
            ),
            _field(CompanyField.responsible, 'Responsável'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Salvando…' : 'Salvar'),
          ),
        ),
      ),
    );
  }

  /// Text field that shows the build default (and a restore button) when
  /// the current text differs from it.
  Widget _field(
    CompanyField field,
    String label, {
    TextInputType? keyboard,
    FormFieldValidator<String>? validator,
  }) {
    final controller = _controllers[field]!;
    final defaultValue = widget.profile.defaultValue(field);
    final changed = controller.text.trim() != defaultValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: TextCapitalization.words,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          helperText: changed
              ? 'Padrão: ${defaultValue.isEmpty ? '(vazio)' : defaultValue}'
              : null,
          suffixIcon: changed
              ? IconButton(
                  tooltip: 'Restaurar padrão',
                  icon: const Icon(Icons.restore),
                  onPressed: () => controller.text = defaultValue,
                )
              : null,
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({
    required this.dependencies,
    required this.logoFile,
    required this.fallbackAsset,
    required this.onPick,
    required this.onRestore,
  });

  final AppDependencies dependencies;
  final String? logoFile;
  final String fallbackAsset;
  final VoidCallback onPick;

  /// Null when the bundled logo is already in use.
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text('Logo', style: Theme.of(context).textTheme.titleMedium),
            CompanyLogo(
              logos: dependencies.logos,
              customLogoFile: logoFile,
              fallbackAsset: fallbackAsset,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onPick,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Trocar logo'),
                ),
                if (onRestore != null)
                  TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Usar logo padrão'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
