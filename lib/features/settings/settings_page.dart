import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/formatting/region_format.dart';
import '../../core/preferences/app_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../update/update_checker.dart';
import '../update/update_prompt.dart';
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

  /// Language of the loaded profile: the example company is translated, so
  /// it is reloaded when the language changes.
  Locale? _loadedLocale;

  AppDependencies get _deps => widget.dependencies;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = PreferencesScope.of(context).locale;
    if (locale != _loadedLocale) {
      _loadedLocale = locale;
      _load();
    }
  }

  Future<void> _load() async {
    final profile = await _deps.settings.companyProfile(_deps.companyDefaults);
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
      appBar: AppBar(title: Text(AppLocalizations.of(context).navSettings)),
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
                const _LanguageAndFormatCard(),
                _AboutCard(dependencies: _deps),
              ],
            ),
    );
  }
}

/// Summary of the company data used on every service order.
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
    final l10n = AppLocalizations.of(context);
    final cityState = [profile.companyCity, profile.companyState]
        .where((part) => part.isNotEmpty)
        .join(' - ');

    final rows = [
      (l10n.rowName, profile.companyName),
      (l10n.rowDocument, profile.companyDocument),
      (l10n.rowPhone, profile.companyPhone),
      (l10n.rowAddress, profile.companyAddress),
      (l10n.rowCity, cityState),
      (l10n.rowResponsible, profile.responsibleName),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.companyCardTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.edit),
                ),
              ],
            ),
            // Takes no space when there is no logo.
            CompanyLogo(
              logos: dependencies.logos,
              customLogoFile: profile.customLogoFile,
              fallbackAsset: profile.defaultLogoAsset,
              height: 110,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 20),
            ),
            const SizedBox(height: 12),
            for (final (index, (label, value)) in rows.indexed) ...[
              if (index > 0) const Divider(height: 1),
              _InfoRow(label: label, value: value),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.companyCardFooter,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Label ........ value" line of the company card. Long values (address)
/// wrap on the right side; empty values show a dash.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Language and regional format, chosen independently (e.g. English with
/// Brazilian formats). Both default to the phone settings.
class _LanguageAndFormatCard extends StatelessWidget {
  const _LanguageAndFormatCard();

  /// Sample of a regional format: "R$ 1.234,56 · 25/10/2026".
  static String _sample(RegionFormat format) =>
      '${format.money(123456)} · ${format.date(DateTime(2026, 10, 25))}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preferences = PreferencesScope.of(context);

    final languages = {
      LanguagePreference.system: l10n.languageSystem,
      LanguagePreference.portuguese: l10n.languagePortuguese,
      LanguagePreference.english: l10n.languageEnglish,
    };
    final regions = {
      RegionPreference.system: l10n.regionSystem,
      RegionPreference.brazil:
          '${l10n.regionBrazil} (${_sample(RegionFormat.brazil)})',
      RegionPreference.unitedStates:
          '${l10n.regionUnitedStates} (${_sample(RegionFormat.unitedStates)})',
    };

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              l10n.languageAndFormat,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.language),
            subtitle: Text(languages[preferences.language]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await _choose(
                context,
                title: l10n.language,
                options: languages,
                current: preferences.language,
              );
              if (choice != null) await preferences.setLanguage(choice);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l10n.region),
            subtitle: Text(
              '${regions[preferences.region]!}\n${l10n.regionHint}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final choice = await _choose(
                context,
                title: l10n.region,
                options: regions,
                current: preferences.region,
              );
              if (choice != null) await preferences.setRegion(choice);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Single-choice dialog; null when dismissed.
  static Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required Map<T, String> options,
    required T current,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final MapEntry(key: value, value: label) in options.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(value),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  if (value == current)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Installed version and the manual "check for updates".
class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  late final Future<InstalledVersion> _installed =
      widget.dependencies.updates.installedVersion();
  bool _checking = false;

  Future<void> _check() async {
    final deps = widget.dependencies;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _checking = true);

    try {
      final update = await deps.updates.check();
      if (!mounted) return;
      if (update == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.upToDate)));
      } else {
        await showUpdateDialog(context, update: update, installer: deps.installer);
      }
    } on UpdateCheckException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(updateCheckErrorMessage(l10n, error))),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.system_update_outlined),
        title: FutureBuilder<InstalledVersion>(
          future: _installed,
          builder: (_, snapshot) => Text(
            snapshot.hasData
                ? l10n.versionLabel(snapshot.data!.name)
                : l10n.version,
          ),
        ),
        subtitle: Text(l10n.checkForUpdates),
        trailing: _checking
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _checking ? null : _check,
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
          AppLocalizations.of(context).notConfigured,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
