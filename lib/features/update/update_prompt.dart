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
      title: Text('Nova versão ${update.version.label}'),
      content: SingleChildScrollView(
        child: Text(
          update.notes.isEmpty
              ? 'Uma nova versão do app está disponível.'
              : update.notes,
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
