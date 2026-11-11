import 'package:flutter/material.dart';

import '../features/history/history_page.dart';
import '../features/settings/settings_page.dart';
import '../features/update/update_checker.dart';
import '../features/update/update_prompt.dart';
import '../l10n/app_localizations.dart';
import 'app_dependencies.dart';
import 'brand_bottom_bar.dart';

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
  final _historyKey = GlobalKey<HistoryPageState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  /// Silent check on startup: offline or GitHub errors are ignored here
  /// (Settings has a manual check that reports them).
  Future<void> _checkForUpdate() async {
    final deps = widget.dependencies;
    if (!deps.checkUpdatesOnStartup) return;
    try {
      final update = await deps.updates.check();
      if (update == null || !mounted) return;
      await showUpdateDialog(context, update: update, installer: deps.installer);
    } on UpdateCheckException {
      return;
    }
  }

  /// The history shows the company name, which may have been edited in
  /// Settings, so it reloads when the user comes back to it.
  void _select(int index) {
    if (index == 0 && _currentIndex != 0) _historyKey.currentState?.reload();
    setState(() => _currentIndex = index);
  }

  /// "Nova ordem" works from any tab: it jumps to the history (which reloads
  /// and opens the new order's preview once it is saved).
  void _createOrder() {
    setState(() => _currentIndex = 0);
    _historyKey.currentState?.createOrder();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HistoryPage(key: _historyKey, dependencies: widget.dependencies),
          SettingsPage(dependencies: widget.dependencies),
        ],
      ),
      bottomNavigationBar: BrandBottomBar(
        currentIndex: _currentIndex,
        onSelected: _select,
        centerAction: BrandBottomBarAction(
          icon: Icons.add,
          label: l10n.navCreate,
          semanticLabel: l10n.navCreateSemantic,
          onPressed: _createOrder,
        ),
        items: [
          BrandBottomBarItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: l10n.navHistory,
          ),
          BrandBottomBarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
