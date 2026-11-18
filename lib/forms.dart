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
  const DayField(this.label, this.day, this.onChange, {super.key});
  final String label;
  final String day;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.calendar_today_outlined),
    title: Text(label),
    subtitle: Text(dateLabel(context, day)),
    onTap: () async {
      final result = await showDatePicker(
        context: context,
        initialDate: DateTime.parse(day),
        firstDate: DateTime(1900),
        lastDate: DateTime(2200),
      );
      if (result != null) onChange(dayKey(result));
    },
  );
}

class Choice<T> extends StatelessWidget {
  const Choice(this.label, this.value, this.items, this.onChange, {super.key});
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        isExpanded: true,
        value: items.containsKey(value) ? value : items.keys.firstOrNull,
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (next) => onChange(next as T),
      ),
    ),
  );
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(
      items
          .where((r) => selected.contains(r['id']))
          .map((r) => r['name'])
          .join(' · '),
    ),
    trailing: const Icon(Icons.search),
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
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  bool number = false,
  ValueChanged<String>? onChanged,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    onChanged: onChanged,
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
