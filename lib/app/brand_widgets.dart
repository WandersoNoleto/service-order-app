import 'package:flutter/material.dart';

/// Soft tone of the brand color behind avatars and row icons.
Color brandTint(BuildContext context, [double opacity = 0.2]) =>
    Theme.of(context).colorScheme.primary.withValues(alpha: opacity);

/// Circle with the customer's initials ("Padaria Sol" -> "PS").
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();

    return CircleAvatar(
      radius: 17,
      backgroundColor: brandTint(context),
      child: initials.isEmpty
          ? Icon(Icons.person_outline, size: 18, color: color)
          : Text(
              initials,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}

/// Icon on a rounded square in the brand's soft tone, leading a row.
class TintedIcon extends StatelessWidget {
  const TintedIcon(this.icon, {super.key, this.size = 30});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brandTint(context),
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Icon(
        icon,
        size: size * 0.57,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// Small amber label ("Garantia", "Recomendado").
class StatusTag extends StatelessWidget {
  const StatusTag(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF412402) : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? const Color(0xFFFAC775) : const Color(0xFF854F0B),
          ),
        ),
      ),
    );
  }
}
