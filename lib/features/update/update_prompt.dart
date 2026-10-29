import 'dart:async';

import 'package:flutter/material.dart';

import 'update_checker.dart';
import 'update_installer.dart';

/// "Nova versão disponível" dialog. If the user accepts, shows the
/// download progress until the Android installer opens.
Future<void> showUpdateDialog(
  BuildContext context, {
  required AvailableUpdate update,
  required UpdateInstaller installer,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nova versão disponível'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A versão v${update.version.label} do aplicativo está '
              'disponível.\n\nToque em "Atualizar" para instalar as '
              'melhorias mais recentes.',
            ),
            // GitHub release notes are written in English, so they stay
            // collapsed; the text above is what the client reads.
            if (update.notes.isNotEmpty) _ReleaseNotes(notes: update.notes),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Depois'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Atualizar'),
        ),
      ],
    ),
  );
  if (!(accepted ?? false) || !context.mounted) return;

  final failure = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DownloadDialog(progress: installer.install(update)),
  );
  if (failure != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure), duration: const Duration(seconds: 8)),
    );
  }
}

/// "Release notes >" link that expands the notes from the GitHub release.
class _ReleaseNotes extends StatefulWidget {
  const _ReleaseNotes({required this.notes});

  final String notes;

  @override
  State<_ReleaseNotes> createState() => _ReleaseNotesState();
}

class _ReleaseNotesState extends State<_ReleaseNotes> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _expanded = !_expanded),
          iconAlignment: IconAlignment.end,
          icon: Icon(_expanded ? Icons.expand_less : Icons.chevron_right),
          label: const Text('Release notes'),
        ),
        if (_expanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(widget.notes, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

/// Pops with null once the installer opens, or with an error message.
class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.progress});

  final Stream<InstallProgress> progress;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  StreamSubscription<InstallProgress>? _subscription;
  int? _percent;

  @override
  void initState() {
    super.initState();
    _subscription = widget.progress.listen(
      (event) {
        switch (event) {
          case Downloading(:final percent):
            setState(() => _percent = percent);
          case InstallerOpened():
            _close(null);
          case InstallFailed(:final message):
            _close(message);
        }
      },
      onError: (Object error) => _close('Erro ao baixar a atualização: $error'),
    );
  }

  void _close(String? failure) {
    _subscription?.cancel();
    _subscription = null;
    if (mounted) Navigator.of(context).pop(failure);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = _percent;

    return AlertDialog(
      title: const Text('Baixando atualização'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          LinearProgressIndicator(value: percent == null ? null : percent / 100),
          Text(percent == null ? 'Iniciando…' : '$percent%'),
        ],
      ),
    );
  }
}
