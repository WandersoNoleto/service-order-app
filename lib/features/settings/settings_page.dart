import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/brand_widgets.dart';
import '../../app/coming_soon.dart';
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
  DateTime? _lastBackup;

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
    final lastBackup = await _deps.backup.lastBackupAt();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _lastBackup = lastBackup;
    });
  }

  Future<void> _backup() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final target = await showDialog<_BackupTarget>(
      context: context,
      builder: (_) => const _BackupDialog(),
    );
    if (target == null) return;

    try {
      final done = switch (target) {
        _BackupTarget.share => await _deps.backup.share(),
        _BackupTarget.device => await _deps.backup.saveToDevice(),
      };
      if (!done) return;
      final lastBackup = await _deps.backup.lastBackupAt();
      if (mounted) setState(() => _lastBackup = lastBackup);
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupDone)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupError('$error'))),
      );
    }
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
    final l10n = AppLocalizations.of(context);
    final profile = _profile;
    // Same rule as the history: on wide screens the content stays in a
    // readable column instead of stretching.
    final gutter =
        math.max(12.0, (MediaQuery.sizeOf(context).width - 720) / 2);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 24),
              children: [
                if (!_deps.config.isConfigured) const _NotConfiguredWarning(),
                _CompanyCard(
                  profile: profile,
                  dependencies: _deps,
                  onEdit: _edit,
                ),
                _Group(
                  title: l10n.settingsPreferences,
                  children: _preferenceTiles(context),
                ),
                _Group(
                  title: l10n.settingsData,
                  children: [
                    _Row(
                      icon: Icons.cloud_upload_outlined,
                      title: l10n.backup,
                      subtitle: switch (_lastBackup) {
                        final at? => l10n.backupLast(context.format.date(at)),
                        null => l10n.backupNever,
                      },
                      // Only nags until the first backup.
                      trailing: _lastBackup == null
                          ? StatusTag(l10n.recommended)
                          : null,
                      onTap: _backup,
                    ),
                    _Row(
                      icon: Icons.folder_outlined,
                      title: l10n.pdfFolder,
                      onTap: () => showComingSoon(context),
                    ),
                  ],
                ),
                _Group(
                  title: l10n.settingsApp,
                  children: [_UpdateTile(dependencies: _deps)],
                ),
              ],
            ),
    );
  }

  /// Sample of a regional format: "R$ 1.234,56 · 25/10/2026".
  static String _sample(RegionFormat format) =>
      '${format.money(123456)} · ${format.date(DateTime(2026, 10, 25))}';

  /// Language, regional format and theme, chosen independently (e.g.
  /// English with Brazilian formats). All default to the phone settings.
  List<Widget> _preferenceTiles(BuildContext context) {
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
    final themes = {
      ThemePreference.system: l10n.themeSystem,
      ThemePreference.light: l10n.themeLight,
      ThemePreference.dark: l10n.themeDark,
    };

    return [
      _Row(
        icon: Icons.translate,
        title: l10n.language,
        value: preferences.language == LanguagePreference.system
            ? l10n.automatic
            : languages[preferences.language],
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
      _Row(
        icon: Icons.payments_outlined,
        title: l10n.region,
        // Always shows what the format looks like, even on "automatic".
        subtitle: _sample(preferences.format),
        value: switch (preferences.region) {
          RegionPreference.system => l10n.automatic,
          RegionPreference.brazil => l10n.regionBrazil,
          RegionPreference.unitedStates => l10n.regionUnitedStates,
        },
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
      _Row(
        icon: Icons.brightness_6_outlined,
        title: l10n.theme,
        value: preferences.theme == ThemePreference.system
            ? l10n.automatic
            : themes[preferences.theme],
        onTap: () async {
          final choice = await _choose(
            context,
            title: l10n.theme,
            options: themes,
            current: preferences.theme,
          );
          if (choice != null) await preferences.setTheme(choice);
        },
      ),
    ];
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

/// Company profile: logo, name and the main data in two short lines. Tap
/// to edit. The strip below tells where the data is used.
class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.profile,
    required this.dependencies,
    required this.onEdit,
  });

  final CompanyProfile profile;
  final AppDependencies dependencies;
  final VoidCallback onEdit;

  static String _join(List<String> parts) =>
      parts.where((part) => part.isNotEmpty).join(' · ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final cityState = [profile.companyCity, profile.companyState]
        .where((part) => part.isNotEmpty)
        .join(' - ');
    final lines = [
      _join([profile.companyDocument, profile.companyPhone]),
      _join([cityState, profile.responsibleName]),
    ].where((line) => line.isNotEmpty);

    final hasLogo =
        profile.hasCustomLogo || profile.defaultLogoAsset.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
              child: Row(
                children: [
                  if (hasLogo)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: CompanyLogo(
                        logos: dependencies.logos,
                        customLogoFile: profile.customLogoFile,
                        fallbackAsset: profile.defaultLogoAsset,
                        height: 46,
                        alignment: Alignment.center,
                      ),
                    )
                  else
                    const TintedIcon(Icons.storefront_outlined, size: 46),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        for (final line in lines)
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: l10n.edit,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ColoredBox(
            color: brandTint(context, 0.12),
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: colors.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.companyCardFooter, style: muted)),
                  TextButton(
                    onPressed: () => showComingSoon(context),
                    child: Text(
                      l10n.viewTemplate,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BackupTarget { share, device }

/// Where to send the backup. Sharing comes first: it is the only option
/// that also survives losing the phone.
class _BackupDialog extends StatelessWidget {
  const _BackupDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    Widget option(
      _BackupTarget target,
      IconData icon,
      String title,
      String hint,
    ) =>
        ListTile(
          leading: TintedIcon(icon),
          title: Text(title),
          subtitle: Text(hint),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onTap: () => Navigator.of(context).pop(target),
        );

    return SimpleDialog(
      title: Text(l10n.backup),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            l10n.backupIntro,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        option(
          _BackupTarget.share,
          Icons.share_outlined,
          l10n.backupShare,
          l10n.backupShareHint,
        ),
        option(
          _BackupTarget.device,
          Icons.save_alt,
          l10n.backupSave,
          l10n.backupSaveHint,
        ),
      ],
    );
  }
}

/// Titled group of rows inside one card.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0) const Divider(height: 1),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: tinted icon, title (and a short second line), then
/// the current value and a chevron, or a custom [trailing].
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          spacing: 10,
          children: [
            TintedIcon(icon),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  if (subtitle case final subtitle?) Text(subtitle, style: muted),
                ],
              ),
            ),
            if (value case final value?) Text(value, style: muted),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

/// Installed version and the manual "check for updates".
class _UpdateTile extends StatefulWidget {
  const _UpdateTile({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<InstalledVersion>(
      future: _installed,
      builder: (_, snapshot) => _Row(
        icon: Icons.refresh,
        title: l10n.updates,
        subtitle: snapshot.hasData
            ? l10n.versionLabel(snapshot.data!.name)
            : l10n.version,
        trailing: _checking
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : TextButton(
                onPressed: _check,
                child: Text(
                  l10n.checkNow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          AppLocalizations.of(context).notConfigured,
          style: TextStyle(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
