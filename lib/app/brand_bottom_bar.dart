import 'package:flutter/material.dart';

/// One tab of [BrandBottomBar].
class BrandBottomBarItem {
  const BrandBottomBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Main action shown as a raised round button in the middle of the bar.
class BrandBottomBarAction {
  const BrandBottomBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Longer description for screen readers ("Criar ordem de serviço").
  final String? semanticLabel;
}

/// Bottom navigation that marks the selected tab with the brand color
/// (instead of Material 3's pill indicator) and an optional raised action
/// button between the tabs. Colors come from the theme, so each client gets
/// its own brand color.
class BrandBottomBar extends StatelessWidget {
  const BrandBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.centerAction,
  });

  final List<BrandBottomBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final BrandBottomBarAction? centerAction;

  static const _height = 64.0;

  /// How far the action button rises above the bar.
  static const _raise = 24.0;
  static const _centerSlotWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final action = centerAction;
    final half = (items.length / 2).ceil();

    Widget tab(int index) => Expanded(
          child: _BarItem(
            item: items[index],
            selected: index == currentIndex,
            onTap: () => onSelected(index),
          ),
        );

    final bar = Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _height,
            child: Row(
              children: [
                for (var i = 0; i < (action == null ? items.length : half); i++)
                  tab(i),
                if (action != null) ...[
                  const SizedBox(width: _centerSlotWidth),
                  for (var i = half; i < items.length; i++) tab(i),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (action == null) return bar;

    // The bar reserves a transparent strip above itself for the raised
    // button, so the whole circle is tappable and never covers the list.
    return Stack(
      children: [
        Padding(padding: const EdgeInsets.only(top: _raise), child: bar),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _CenterButton(action: action)),
        ),
      ],
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.action});

  final BrandBottomBarAction action;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: action.onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            // Ring in the surface color separates the circle from the bar.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 4),
              ),
              child: Material(
                color: colors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: action.onPressed,
                  child: SizedBox.square(
                    dimension: _size,
                    child: Icon(action.icon, color: colors.onPrimary, size: 28),
                  ),
                ),
              ),
            ),
            Text(
              action.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BrandBottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, color: color),
            Text(
              item.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
