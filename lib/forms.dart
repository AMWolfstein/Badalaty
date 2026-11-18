import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import 'allowances/calculation.dart';
import 'data/store.dart';
import 'l10n/labels.dart';

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l.confirm),
          ),
        ],
      ),
    ) ??
    false;

void feedback(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

String dateLabel(BuildContext context, String day) =>
    DateFormat.yMMMd(context.l.localeName).format(DateTime.parse(day));

class DayField extends StatelessWidget {
  const DayField(
    this.label,
    this.day,
    this.onChange, {
    this.shortDate = false,
    super.key,
  });
  final String label;
  final String day;
  final bool shortDate;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(day),
          firstDate: DateTime(1900),
          lastDate: DateTime(2200),
        );
        if (result != null) onChange(dayKey(result));
      },
      child: _FieldContent(
        label: label,
        value: shortDate
            ? DateFormat.MMMd(context.l.localeName).format(DateTime.parse(day))
            : dateLabel(context, day),
        icon: Icons.calendar_today_outlined,
      ),
    ),
  );
}

class Choice<T> extends StatelessWidget {
  const Choice(
    this.label,
    this.value,
    this.items,
    this.onChange, {
    this.compact = false,
    super.key,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = items.containsKey(value) ? value : items.keys.firstOrNull;
    final text = items[selected] ?? label;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: compact ? scheme.primaryContainer : null,
      elevation: compact ? 0 : null,
      shape: compact
          ? StadiumBorder(side: BorderSide(color: scheme.outlineVariant))
          : null,
      child: PopupMenuButton<T>(
        tooltip: label,
        enabled: items.isNotEmpty,
        initialValue: selected,
        itemBuilder: (_) => [
          for (final item in items.entries)
            PopupMenuItem<T>(value: item.key, child: Text(item.value)),
        ],
        onSelected: onChange,
        child: compact
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 14),
                  ],
                ),
              )
            : _FieldContent(
                label: label,
                value: text,
                icon: Icons.keyboard_arrow_down,
              ),
      ),
    );
  }
}

class _FieldContent extends StatelessWidget {
  const _FieldContent({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: theme.colorScheme.primary, size: 16),
        ],
      ),
    );
  }
}

class SearchRecords extends StatelessWidget {
  const SearchRecords(
    this.label,
    this.items,
    this.selected, {
    required this.onPick,
    this.multiple = false,
    super.key,
  });
  final String label;
  final Iterable<Record> items;
  final Set<int> selected;
  final ValueChanged<Set<int>> onPick;
  final bool multiple;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      child: _FieldContent(
        label: label,
        value: items
            .where((record) => selected.contains(record['id']))
            .map((record) => record['name'])
            .join(' · '),
        icon: Icons.search,
      ),
      onTap: () async {
        final selection = {...selected};
        var search = '';
        final result = await showDialog<Set<int>>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, change) => AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 440,
                height: 330,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: context.l.search),
                      onChanged: (value) =>
                          change(() => search = value.toLowerCase()),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final record in items.where(
                            (r) => '${r['name']} ${r['code'] ?? ''}'
                                .toLowerCase()
                                .contains(search),
                          ))
                            CheckboxListTile(
                              title: Text(record['name'] as String),
                              subtitle: record['code'] == null
                                  ? null
                                  : Text(record['code'] as String),
                              value: selection.contains(record['id']),
                              onChanged: (checked) {
                                final id = record['id'] as int;
                                if (!multiple) {
                                  Navigator.pop(context, {id});
                                } else {
                                  change(
                                    () => checked == true
                                        ? selection.add(id)
                                        : selection.remove(id),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l.cancel),
                ),
                if (multiple)
                  FilledButton(
                    onPressed: () => Navigator.pop(context, selection),
                    child: Text(context.l.confirm),
                  ),
              ],
            ),
          ),
        );
        if (result != null) onPick(result);
      },
    ),
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  bool number = false,
  ValueChanged<String>? onChanged,
}) => Card(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        filled: false,
        isDense: true,
      ),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
    ),
  ),
);

int? whole(String input) {
  final text = normalizedNumber(input);
  return RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
}

String normalizedNumber(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var value = input.trim().replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value;
}
