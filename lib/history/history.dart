import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../home/home.dart';
import '../l10n/labels.dart';
import '../widgets/glass_navigation_bar.dart';

String statusOf(List<Record> records, String day, String today) {
  final override = records
      .ofKind('day')
      .where((r) => r['day'] == day)
      .firstOrNull;
  if (override != null && override['status'] != 'automatic') {
    return override['status'] as String;
  }
  if (records.entries.any((r) => r['day'] == day)) return 'recorded';
  if (day.compareTo(today) > 0) return 'future';
  final workweek = records.settings['workweek'] as List? ?? [7, 1, 2, 3, 4];
  return workweek.contains(DateTime.parse(day).weekday) ? 'missing' : 'weekend';
}

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage(this.records, {super.key});
  final List<Record> records;
  @override
  ConsumerState<HistoryPage> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<HistoryPage> {
  DateTime month = DateTime.now();
  String? pickedDay;
  String search = '', category = '';
  int client = 0, assignment = 0;
  bool showFilters = false;

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    final l = context.l;
    final monthStart = DateTime(month.year, month.month);
    final monthKey = dayKey(monthStart).substring(0, 7);
    final today = dayKey(DateTime.now());
    final days = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final offset = (monthStart.weekday % 7 - firstWeekday + 7) % 7;
    final entries = records.entries.where(
      (r) =>
          (pickedDay == null
              ? (r['day'] as String).startsWith(monthKey)
              : r['day'] == pickedDay) &&
          (client == 0 || client == r['client']) &&
          (assignment == 0 || assignment == r['assignment']) &&
          (category.isEmpty || category == r['category']) &&
          '${r['clientName']} ${r['notes']} ${r['assignmentName'] ?? ''}'
              .toLowerCase()
              .contains(search),
    );
    return ListView(
      padding: sectionListPadding(context),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: l.start,
              onPressed: () => setState(() {
                month = DateTime(month.year, month.month - 1);
                pickedDay = null;
              }),
              icon: const Icon(Icons.arrow_back),
            ),
            Flexible(
              child: Text(
                DateFormat.yMMMM(l.localeName).format(month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l.end,
              onPressed: () => setState(() {
                month = DateTime(month.year, month.month + 1);
                pickedDay = null;
              }),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: [
            for (var i = 0; i < 7; i++)
              Center(
                child: Text(
                  MaterialLocalizations.of(context)
                      .narrowWeekdays[(i + firstWeekday) % 7],
                ),
              ),
            for (var i = 0; i < offset; i++) const SizedBox(),
            for (var i = 1; i <= days; i++)
              Builder(
                builder: (context) {
                  final date = dayKey(DateTime(month.year, month.month, i));
                  final status = statusOf(records, date, today);
                  return Semantics(
                    label:
                        '${dateLabel(context, date)}, ${l.statusName(status)}',
                    child: InkWell(
                      onTap: () => setState(
                        () => pickedDay = pickedDay == date ? null : date,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pickedDay == date
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              NumberFormat.decimalPattern(l.localeName)
                                  .format(i),
                            ),
                            if (status == 'recorded' || status == 'missing')
                              Icon(
                                Icons.circle,
                                size: 5,
                                color: status == 'recorded'
                                    ? Colors.teal
                                    : Colors.orange,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        if (pickedDay != null)
          ListTile(
            title: Text(dateLabel(context, pickedDay!)),
            subtitle: Text(l.statusName(statusOf(records, pickedDay!, today))),
            trailing: PopupMenuButton<String>(
              tooltip: l.status,
              onSelected: (value) async {
                try {
                  final day = pickedDay!;
                  final existing = records
                      .ofKind('day')
                      .where((r) => r['day'] == day)
                      .firstOrNull;
                  await ref.saveRecord('day', {
                    'day': day,
                    'status': value,
                  }, id: existing?['id'] as int?);
                } catch (_) {
                  if (context.mounted) feedback(context, l.error);
                }
              },
              itemBuilder: (_) => [
                for (final status in [
                  'automatic',
                  'leave',
                  'holiday',
                  'weekend',
                  'noAllowance',
                ])
                  PopupMenuItem(
                    value: status,
                    child: Text(
                      status == 'automatic' ? l.clear : l.statusName(status),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: l.search),
                onChanged: (v) => setState(() => search = v.toLowerCase()),
              ),
            ),
            IconButton(
              tooltip: l.category,
              onPressed: () => setState(() => showFilters = !showFilters),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        if (showFilters) ...[
          Choice(l.client, client, {
            0: l.all,
            for (final r in records.ofKind('client'))
              r['id'] as int: r['name'] as String,
          }, (value) => setState(() => client = value)),
          Choice(l.assignment, assignment, {
            0: l.all,
            for (final r in records.ofKind('assignment'))
              r['id'] as int: r['name'] as String,
          }, (value) => setState(() => assignment = value)),
          Choice(l.category, category, {
            '': l.all,
            for (final c in Category.values) c.name: l.categoryName(c.name),
          }, (value) => setState(() => category = value)),
        ],
        if (entries.isEmpty)
          Padding(padding: const EdgeInsets.all(18), child: Text(l.empty)),
        for (final record in entries)
          EntryTile(
            record,
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => [
                PopupMenuItem(value: 'copy', child: Text(l.copy)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
              onSelected: (value) async {
                final id = record['id'] as int;
                if (value == 'copy') {
                  context.push('/entry/${record['category']}?copy=$id');
                } else if (await confirm(context, l.deleteEntry) && mounted) {
                  try {
                    await ref.read(storeProvider).removeEntry(id);
                    ref.invalidate(recordsProvider);
                  } catch (_) {
                    if (context.mounted) feedback(context, l.error);
                  }
                }
              },
            ),
          ),
      ],
    );
  }
}
