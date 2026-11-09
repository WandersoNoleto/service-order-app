import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
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

  /// True when a field or the logo differs from what was loaded. Typing a
  /// value back to the original counts as unchanged.
  bool get _hasChanges =>
      _logoFile != widget.profile.customLogoFile ||
      _controllers.entries.any(
        (entry) => entry.value.text != widget.profile.value(entry.key),
      );

  /// Back with unsaved changes asks before discarding them.
  Future<void> _onPopBlocked() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).discardChangesTitle),
        content: Text(AppLocalizations.of(context).discardCompanyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).discard),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

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
        SnackBar(content: Text(AppLocalizations.of(context).couldNotLoadImage('$error'))),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await _deps.settings.saveCompanyFields(_deps.companyDefaults, {
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
        title: Text(AppLocalizations.of(context).restoreAllTitle),
        content: Text(AppLocalizations.of(context).restoreAllMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).restore),
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
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).companyFormTitle),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => switch (action) {
              _MenuAction.resetAll => _resetAll(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.resetAll,
                child: Text(AppLocalizations.of(context).restoreAllDefaults),
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
              AppLocalizations.of(context).companyNameField,
              validator: (text) => (text ?? '').trim().isEmpty
                  ? AppLocalizations.of(context).companyNameRequired
                  : null,
            ),
            _field(CompanyField.document, AppLocalizations.of(context).companyDocumentField),
            _field(
              CompanyField.phone,
              AppLocalizations.of(context).phoneWhatsapp,
              keyboard: TextInputType.phone,
            ),
            _field(CompanyField.address, AppLocalizations.of(context).address),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(flex: 3, child: _field(CompanyField.city, AppLocalizations.of(context).city)),
                Expanded(child: _field(CompanyField.state, AppLocalizations.of(context).stateShort)),
              ],
            ),
            _field(CompanyField.responsible, AppLocalizations.of(context).responsible),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? AppLocalizations.of(context).saving : AppLocalizations.of(context).save),
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
              ? AppLocalizations.of(context).defaultValue(
                  defaultValue.isEmpty ? AppLocalizations.of(context).emptyValue : defaultValue,
                )
              : null,
          suffixIcon: changed
              ? IconButton(
                  tooltip: AppLocalizations.of(context).restoreDefault,
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
            Text(AppLocalizations.of(context).logo, style: Theme.of(context).textTheme.titleMedium),
            CompanyLogo(
              logos: dependencies.logos,
              customLogoFile: logoFile,
              fallbackAsset: fallbackAsset,
              emptyLabel: AppLocalizations.of(context).noLogo,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onPick,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(AppLocalizations.of(context).changeLogo),
                ),
                if (onRestore != null)
                  TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                    label: Text(
                      fallbackAsset.isEmpty ? AppLocalizations.of(context).removeLogo : AppLocalizations.of(context).useDefaultLogo,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
