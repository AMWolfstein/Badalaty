import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../home/home.dart';
import '../l10n/labels.dart';
import '../records/add_record.dart';
import '../widgets/glass_navigation_bar.dart';
import '../widgets/glass_design.dart';

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
  const HistoryPage(this.records, {this.initialDay, super.key});
  final List<Record> records;
  final String? initialDay;
  @override
  ConsumerState<HistoryPage> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<HistoryPage> {
  late final DateTime? _openingDay = DateTime.tryParse(widget.initialDay ?? '');
  late DateTime month = _openingDay ?? DateTime.now();
  late String? pickedDay = _openingDay == null ? null : dayKey(_openingDay);
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
    final entries = records.activity.where(
      (r) =>
          (pickedDay == null
              ? (r['day'] as String).startsWith(monthKey)
              : r['day'] == pickedDay) &&
          (client == 0 || client == r['client']) &&
          (assignment == 0 || assignment == r['assignment']) &&
          (category.isEmpty || category == (r['category'] ?? r['status'])) &&
          (r['kind'] == 'day'
                  ? l.statusName(r['status'] as String)
                  : '${r['clientName']} ${r['notes']} ${r['assignmentName'] ?? ''}')
              .toLowerCase()
              .contains(search),
    );
    return ListView(
      padding: sectionListPadding(context),
      children: [
        GlassContentCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GlassIconAction(
                      tooltip: MaterialLocalizations.of(context)
                          .previousMonthTooltip,
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
                    GlassIconAction(
                      tooltip: MaterialLocalizations.of(context)
                          .nextMonthTooltip,
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
                          final date = dayKey(
                            DateTime(month.year, month.month, i),
                          );
                          final status = statusOf(records, date, today);
                          return Semantics(
                            label:
                                '${dateLabel(context, date)}, ${l.statusName(status)}',
                            child: InkWell(
                              onTap: () => setState(
                                () =>
                                    pickedDay = pickedDay == date ? null : date,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: pickedDay == date
                                      ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
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
                                    if (status == 'recorded' ||
                                        status == 'missing')
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
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final kind in [
                '',
                ...Category.values.map((item) => item.name),
                ...recordedDayStatuses,
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: GlassFilterChip(
                    label: kind.isEmpty
                        ? l.all
                        : recordedDayStatuses.contains(kind)
                        ? l.statusName(kind)
                        : l.categoryName(kind),
                    selected: category == kind,
                    onTap: () => setState(() => category = kind),
                  ),
                ),
            ],
          ),
        ),
        if (pickedDay != null)
          GlassRow(
            title: Text(dateLabel(context, pickedDay!)),
            subtitle: Text(l.statusName(statusOf(records, pickedDay!, today))),
            trailing: GlassOverflow<String>(
              label: l.status,
              onSelected: (value) async {
                try {
                  final day = pickedDay!;
                  await ref.saveRecord('day', {'day': day, 'status': value});
                } catch (_) {
                  if (context.mounted) feedback(context, l.error);
                }
              },
              items: {
                for (final status in [
                  'automatic',
                  ...recordedDayStatuses,
                  'holiday',
                  'weekend',
                  'noAllowance',
                ])
                  status: status == 'automatic'
                      ? l.clear
                      : l.statusName(status),
              },
            ),
          ),
        Row(
          children: [
            Expanded(
              child: liquid.GlassSearchBar(
                placeholder: l.search,
                surfaceStyle: liquid.GlassSurfaceStyle.solid,
                onChanged: (v) => setState(() => search = v.toLowerCase()),
              ),
            ),
            GlassIconAction(
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
            for (final status in recordedDayStatuses)
              status: l.statusName(status),
          }, (value) => setState(() => category = value)),
        ],
        GlassHeading(l.history),
        if (entries.isEmpty)
          Padding(padding: const EdgeInsets.all(18), child: Text(l.empty)),
        for (final record in entries)
          if (record['kind'] == 'day')
            DayRecordTile(record)
          else
            EntryTile(
              record,
              trailing: GlassOverflow<String>(
                label: MaterialLocalizations.of(context).moreButtonTooltip,
                items: {'copy': l.copy, 'delete': l.delete},
                destructiveValue: 'delete',
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
