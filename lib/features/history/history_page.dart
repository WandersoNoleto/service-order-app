import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/formatting/formatters.dart';
import '../service_order/data/service_order.dart';
import '../service_order/service_order_form_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// Null while the first load is running.
  List<ServiceOrder>? _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final orders = await widget.dependencies.orders.list(
      query: _searchController.text,
    );
    if (!mounted) return;
    setState(() => _orders = orders);
  }

  /// Waits for the user to stop typing before querying the database.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _load);
  }

  /// Opens the form to create ([order] null) or edit an order, and reloads
  /// the list if something was saved or deleted.
  Future<void> _openForm([ServiceOrder? order]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceOrderFormPage(
          dependencies: widget.dependencies,
          initialOrder: order,
        ),
      ),
    );
    if (changed ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Criar'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar por cliente ou nº da OS',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final orders = _orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return _searchController.text.trim().isEmpty
          ? const _EmptyHistory()
          : const Center(child: Text('Nenhuma OS encontrada'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: orders.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final order = orders[index];
          return _OrderTile(order: order, onTap: () => _openForm(order));
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = order.orderNumber.isEmpty ? 's/ nº' : order.orderNumber;
    final customer =
        order.customerName.isEmpty ? 'Cliente não informado' : order.customerName;

    return ListTile(
      onTap: onTap,
      title: Text('OS $number'),
      subtitle: Text('$customer\n${formatDate(order.createdAt)}'),
      isThreeLine: true,
      trailing: Text(
        'R\$ ${formatCents(order.totalCents)}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Nenhuma OS emitida ainda', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Toque em "Criar" para emitir a primeira ordem de serviço.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
