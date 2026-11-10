import 'package:flutter/material.dart';

import '../../../core/formatting/region_format.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../l10n/app_localizations.dart';

/// Titled card that groups related fields ("Cliente", "Atendimento"…).
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// "☐ Sim ☐ Não" from the paper form. Tapping the selected option again
/// clears it, so "nothing checked" (null) is possible.
class YesNoField extends StatelessWidget {
  const YesNoField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              label: Text(AppLocalizations.of(context).yes),
            ),
            ButtonSegment(
              value: false,
              label: Text(AppLocalizations.of(context).no),
            ),
          ],
          selected: selected == null ? const {} : {selected},
          emptySelectionAllowed: true,
          onSelectionChanged: (selection) =>
              onChanged(selection.isEmpty ? null : selection.first),
        ),
      ],
    );
  }
}

/// Read-only field that opens a date picker. Has a clear button.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      // Only where the calendar opens; nothing is filled until the user picks.
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      text: context.format.date(value),
      icon: Icons.calendar_today_outlined,
      onTap: () => _pick(context),
      onClear: value == null ? null : () => onChanged(null),
    );
  }
}

/// Read-only field that opens a time picker. Value is "HH:mm".
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final current = value?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: int.parse(current[0]), minute: int.parse(current[1])),
    );
    if (picked == null) return;

    final hour = picked.hour.toString().padLeft(2, '0');
    final minute = picked.minute.toString().padLeft(2, '0');
    onChanged('$hour:$minute');
  }

  @override
  Widget build(BuildContext context) {
    return _PickerField(
      label: label,
      // Stored as "HH:mm"; shown in the regional format ("2:30 PM").
      text: value == null ? '' : context.format.time(value!),
      icon: Icons.schedule_outlined,
      onTap: () => _pick(context),
      onClear: value == null ? null : () => onChanged(null),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.text,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: AppLocalizations.of(context).clear,
                  icon: const Icon(Icons.close),
                  onPressed: onClear,
                ),
        ),
        isEmpty: text.isEmpty,
        child: Text(text),
      ),
    );
  }
}

/// Validator for money fields (accepts empty as zero).
String? validateMoney(
  String? text,
  RegionFormat format,
  AppLocalizations l10n,
) =>
    format.parseMoney(text ?? '') == null ? l10n.invalidAmount : null;
