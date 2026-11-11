import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/brand_widgets.dart';
import '../../core/formatting/formatters.dart';
import '../../core/preferences/app_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../document/service_order_preview_page.dart';
import '../service_order/data/service_order.dart';
import '../service_order/service_order_form_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

/// Quick filters under the search field.
enum _Filter { all, last7Days, thisMonth, warranty }

/// Public so the bottom bar (in HomeShell) can start the create flow and
/// refresh the list through a GlobalKey.
class HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  _Filter _filter = _Filter.all;

  /// Every saved order, newest first. Null while the first load is running.
  /// Search and filters run in memory, so the summary always covers all
  /// orders.
  List<ServiceOrder>? _orders;
  String _companyName = '';

  /// Language of the loaded company name: the example company is
  /// translated, so it is reloaded when the language changes.
  Locale? _loadedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = PreferencesScope.of(context).locale;
    if (locale != _loadedLocale) {
      _loadedLocale = locale;
      reload();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Also called when the user comes back to this tab, since the company
  /// name may have changed in Settings.
  Future<void> reload() async {
    final deps = widget.dependencies;
    final orders = await deps.orders.list();
    final profile = await deps.settings.companyProfile(deps.companyDefaults);
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _companyName = profile.companyName;
    });
  }

  /// New order: form first, then its preview once saved. Called by the
  /// center button of the bottom bar.
  Future<void> createOrder() async {
    final savedId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ServiceOrderFormPage(dependencies: widget.dependencies),
      ),
    );
    if (savedId == null) return;

    await reload();
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
    await reload();
  }

  bool _matches(ServiceOrder order) {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isNotEmpty &&
        !order.customerName.toLowerCase().contains(term) &&
        !order.orderNumber.toLowerCase().contains(term) &&
        !order.servicesPerformed.toLowerCase().contains(term)) {
      return false;
    }

    final now = DateTime.now();
    final created = order.createdAt!;
    return switch (_filter) {
      _Filter.all => true,
      _Filter.last7Days =>
        !created.isBefore(DateTime(now.year, now.month, now.day - 6)),
      _Filter.thisMonth =>
        created.year == now.year && created.month == now.month,
      _Filter.warranty => order.underWarranty ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_companyName.isNotEmpty)
              Text(
                _companyName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(l10n.historyTitle),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  /// No fixed height: it comes from the text and its padding, so the field
  /// grows with the font size chosen on the phone.
  Widget _searchField(double gutter) {
    final theme = Theme.of(context);
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(100),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).historySearchHint,
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          contentPadding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
          fillColor: theme.colorScheme.surface,
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill.copyWith(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChips(double gutter) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final filters = {
      _Filter.all: l10n.filterAll,
      _Filter.last7Days: l10n.filterLast7Days,
      _Filter.thisMonth: l10n.filterThisMonth,
      _Filter.warranty: l10n.warranty,
    };

    // Scrolls sideways when the chips do not fit (narrow phone, large font).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 4),
      child: Row(
        spacing: 6,
        children: [
          for (final MapEntry(key: filter, value: label) in filters.entries)
            ChoiceChip(
              label: Text(label),
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: _filter == filter
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
              ),
              selected: _filter == filter,
              showCheckmark: false,
              selectedColor: colors.primary,
              backgroundColor: Colors.transparent,
              shape: const StadiumBorder(),
              side: BorderSide(color: colors.outlineVariant, width: 0.5),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => setState(() => _filter = filter),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final orders = _orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) return const _EmptyHistory();

    final visible = orders.where(_matches).toList();

    // Sizes follow the device instead of being fixed: on wide screens
    // (tablet, landscape) the content stays in a readable column, and the
    // day header grows with the font size chosen on the phone.
    final gutter = math.max(16.0, (MediaQuery.sizeOf(context).width - 720) / 2);
    final headerHeight = MediaQuery.textScalerOf(context).scale(20) + 24;

    // Summary, search and filters scroll away with the list, so the orders
    // get the whole screen. Then one group per day: the day header is pinned
    // inside its group, sticking to the top while that day's orders scroll,
    // and the next day's header pushes it out when the group ends.
    return RefreshIndicator(
      onRefresh: reload,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Summary(orders: orders, gutter: gutter),
          ),
          SliverToBoxAdapter(child: _searchField(gutter)),
          SliverToBoxAdapter(child: _filterChips(gutter)),
          if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(AppLocalizations.of(context).historyNoResults),
              ),
            ),
          for (final (label: label, orders: dayOrders) in _groupByDay(visible))
            SliverMainAxisGroup(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DayHeaderDelegate(
                    label: label,
                    summary: _countAndTotal(context, dayOrders),
                    height: headerHeight,
                    gutter: gutter,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: DecoratedSliver(
                    decoration: _cardDecoration(context),
                    sliver: SliverList.separated(
                      itemCount: dayOrders.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final order = dayOrders[index];
                        return _OrderTile(
                          order: order,
                          first: index == 0,
                          last: index == dayOrders.length - 1,
                          onTap: () => _openPreview(order.id!),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  /// Orders come newest first, so a new group starts whenever the day
  /// changes.
  List<({String label, List<ServiceOrder> orders})> _groupByDay(
    List<ServiceOrder> orders,
  ) {
    final l10n = AppLocalizations.of(context);
    final groups = <({String label, List<ServiceOrder> orders})>[];

    for (final order in orders) {
      final label = formatDayLabel(
        order.createdAt!,
        languageCode: l10n.localeName,
        today: l10n.today,
        yesterday: l10n.yesterday,
      );
      if (groups.isEmpty || groups.last.label != label) {
        groups.add((label: label, orders: [order]));
      } else {
        groups.last.orders.add(order);
      }
    }
    return groups;
  }
}

const _cardRadius = Radius.circular(12);

/// Same look as a [Card], for a group of rows inside a sliver.
BoxDecoration _cardDecoration(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surface,
    borderRadius: const BorderRadius.all(_cardRadius),
    border: Border.all(color: colors.outlineVariant, width: 0.5),
  );
}

int _totalCents(Iterable<ServiceOrder> orders) =>
    orders.fold(0, (sum, order) => sum + order.totalCents);

/// "3 · R$ 1.005,40".
String _countAndTotal(BuildContext context, List<ServiceOrder> orders) =>
    '${orders.length} · ${context.format.money(_totalCents(orders))}';

/// Totals of today and of the current month, above the list.
class _Summary extends StatelessWidget {
  const _Summary({required this.orders, required this.gutter});

  final List<ServiceOrder> orders;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final month = orders
        .where((order) =>
            order.createdAt!.year == now.year &&
            order.createdAt!.month == now.month)
        .toList();
    final today =
        month.where((order) => order.createdAt!.day == now.day).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
      child: Row(
        spacing: 8,
        children: [
          Expanded(child: _SummaryCard(label: l10n.today, orders: today)),
          Expanded(
            child: _SummaryCard(
              label: formatMonthName(now, languageCode: l10n.localeName),
              orders: month,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.orders});

  final String label;
  final List<ServiceOrder> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return DecoratedBox(
      decoration: _cardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                context.format.money(_totalCents(orders)),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              AppLocalizations.of(context).ordersCount(orders.length),
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Day title ("Hoje", "Ontem", "25 de outubro de 2026") with the day's
/// count and total, pinned at the top of its group. Opaque, so the orders
/// scroll underneath it.
class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DayHeaderDelegate({
    required this.label,
    required this.summary,
    required this.height,
    required this.gutter,
  });

  final String label;
  final String summary;

  final double height;
  final double gutter;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      height: height,
      alignment: Alignment.bottomLeft,
      padding: EdgeInsets.fromLTRB(gutter + 4, 0, gutter + 4, 8),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: muted),
            ),
          ),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate oldDelegate) =>
      oldDelegate.label != label ||
      oldDelegate.summary != summary ||
      oldDelegate.height != height ||
      oldDelegate.gutter != gutter;
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.first,
    required this.last,
    required this.onTap,
  });

  final ServiceOrder order;

  /// Position in the day's card, to round the tap highlight like the card.
  final bool first;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // The customer is what people remember; number and service come second.
    final customer =
        order.customerName.isEmpty ? l10n.customerNotInformed : order.customerName;
    final number = order.orderNumber.isEmpty
        ? l10n.orderNoNumber
        : l10n.orderNumberShort(order.orderNumber);
    final service = order.servicesPerformed.trim().split('\n').first;

    // The card is painted by the sliver around the list, so the tile needs
    // its own Material for the tap highlight to show on top of it.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: first ? _cardRadius : Radius.zero,
            bottom: last ? _cardRadius : Radius.zero,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        horizontalTitleGap: 12,
        leading: InitialsAvatar(order.customerName),
        title: Row(
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (order.underWarranty ?? false) StatusTag(l10n.warranty),
          ],
        ),
        subtitle: Text(
          service.isEmpty ? number : '$number · $service',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // The day is in the section header; the tile shows the time.
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.format.money(order.totalCents),
              style: theme.textTheme.titleSmall,
            ),
            Text(
              context.format.timeOf(order.createdAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
              l10n.historyEmptyTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.historyEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
