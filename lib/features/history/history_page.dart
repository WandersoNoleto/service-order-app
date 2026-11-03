import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/formatting/formatters.dart';
import '../document/service_order_preview_page.dart';
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

  /// New order: form first, then its preview once saved.
  Future<void> _createOrder() async {
    final savedId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ServiceOrderFormPage(dependencies: widget.dependencies),
      ),
    );
    if (savedId == null) return;

    await _load();
    if (mounted) await _openPreview(savedId);
  }

  /// The preview can edit or delete the order, so always reload after it.
  Future<void> _openPreview(int orderId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ServiceOrderPreviewPage(
          dependencies: widget.dependencies,
          orderId: orderId,
        ),
      ),
    );
    await _load();
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
              onPressed: _createOrder,
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
          : const Center(child: Text('Nenhuma ordem de serviço encontrada'));
    }

    // One group per day. The day header is pinned inside its group: it
    // sticks to the top while that day's orders scroll, and the next day's
    // header pushes it out when the group ends.
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final (label: label, orders: dayOrders) in _groupByDay(orders))
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DayHeaderDelegate(label),
                ),
                SliverList.separated(
                  itemCount: dayOrders.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16),
                  itemBuilder: (_, index) {
                    final order = dayOrders[index];
                    return _OrderTile(
                      order: order,
                      onTap: () => _openPreview(order.id!),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Orders come newest first, so a new group starts whenever the day
  /// changes.
  List<({String label, List<ServiceOrder> orders})> _groupByDay(
    List<ServiceOrder> orders,
  ) {
    final groups = <({String label, List<ServiceOrder> orders})>[];

    for (final order in orders) {
      final label = formatDayLabel(order.createdAt!);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add((label: label, orders: [order]));
      } else {
        groups.last.orders.add(order);
      }
    }
    return groups;
  }
}

/// Day title ("Hoje", "Ontem", "25 de outubro de 2026") pinned at the top
/// of its group. Opaque, so the orders scroll underneath it.
class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DayHeaderDelegate(this.label);

  final String label;

  static const _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return Container(
      height: _height,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        // Hairline only while orders are scrolling underneath.
        border: overlapsContent
            ? Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label;
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Everything here is a service order: the number alone is the title.
    final number = order.orderNumber.isEmpty ? 'Sem número' : order.orderNumber;
    final customer =
        order.customerName.isEmpty ? 'Cliente não informado' : order.customerName;

    // The day is in the section header; the tile shows the time.
    return ListTile(
      onTap: onTap,
      title: Text(number),
      subtitle: Text('$customer · ${formatTime(order.createdAt!)}'),
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
            Text(
              'Nenhuma ordem de serviço emitida ainda',
              style: theme.textTheme.titleMedium,
            ),
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
