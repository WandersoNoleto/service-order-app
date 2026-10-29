import 'package:flutter/material.dart';

import '../features/history/history_page.dart';
import '../features/settings/settings_page.dart';
import '../features/update/update_checker.dart';
import '../features/update/update_prompt.dart';
import 'app_dependencies.dart';

/// Root screen with the bottom navigation bar.
///
/// Tabs live in an [IndexedStack] so each one keeps its state (scroll,
/// search) when the user switches between them.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  /// Silent check on startup: offline or GitHub errors are ignored here
  /// (Settings has a manual check that reports them).
  Future<void> _checkForUpdate() async {
    final deps = widget.dependencies;
    try {
      final update = await deps.updates.check();
      if (update == null || !mounted) return;
      await showUpdateDialog(context, update: update, installer: deps.installer);
    } on UpdateCheckException {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HistoryPage(dependencies: widget.dependencies),
          SettingsPage(dependencies: widget.dependencies),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}
