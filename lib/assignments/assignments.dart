import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';

const tripStatuses = ['planned', 'active', 'completed', 'cancelled'];

class AssignmentsPage extends StatelessWidget {
  const AssignmentsPage(this.records, {super.key});
  final List<Record> records;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      FilledButton.icon(
        onPressed: () => context.push('/assignment/new'),
        icon: const Icon(Icons.add),
        label: Text(context.l.add),
      ),
      for (final trip in records.ofKind('assignment'))
        Card(
          child: ListTile(
            title: Text(trip['name'] as String),
            subtitle: Text(
              '${dateLabel(context, trip['start'] as String)} – ${dateLabel(context, trip['end'] as String)}\n${context.l.statusName(trip['status'] as String)}',
            ),
            onTap: () => context.push('/assignment/${trip['id']}'),
          ),
        ),
    ],
  );
}

class AssignmentEditor extends ConsumerStatefulWidget {
  const AssignmentEditor(this.id, {super.key});
  final int? id;

  @override
  ConsumerState<AssignmentEditor> createState() => _AssignmentEditorState();
}

class _AssignmentEditorState extends ConsumerState<AssignmentEditor> {
  final destination = TextEditingController();
  final notes = TextEditingController();
  String start = dayKey(DateTime.now()),
      end = dayKey(DateTime.now()),
      status = 'planned';
  int client = 0;
  bool initialized = false, busy = false, dirty = false;

  @override
  void dispose() {
    destination.dispose();
    notes.dispose();
    super.dispose();
  }

  void edit(VoidCallback action) => setState(() {
    dirty = true;
    action();
  });

  Future<void> save(List<Record> records, {String? newStatus}) async {
    final nextStatus = newStatus ?? status;
    if (client == 0 ||
        destination.text.trim().isEmpty ||
        end.compareTo(start) < 0 ||
        DateTime.parse(end).difference(DateTime.parse(start)).inDays > 3660) {
      feedback(context, context.l.missingFields);
      return;
    }
    final previous = records.byId(widget.id);
    final changedDates =
        previous == null ||
        previous['start'] != start ||
        previous['end'] != end;
    final overlap =
        nextStatus != 'cancelled' &&
        changedDates &&
        records
            .ofKind('assignment')
            .any(
              (r) =>
                  r['id'] != widget.id &&
                  r['status'] != 'cancelled' &&
                  start.compareTo(r['end'] as String) <= 0 &&
                  end.compareTo(r['start'] as String) >= 0,
            );
    setState(() => busy = true);
    try {
      if (overlap && !await confirm(context, context.l.overlap)) return;
      await ref.saveRecord('assignment', {
        'client': client,
        'name': destination.text.trim(),
        'notes': notes.text.trim(),
        'start': start,
        'end': end,
        'status': nextStatus,
      }, id: widget.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) feedback(context, context.l.error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.assignment)),
      body: ref
          .watch(recordsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l.error)),
            data: (records) {
              final trip = records.byId(widget.id);
              if (!initialized) {
                if (trip != null) {
                  destination.text = trip['name'] as String;
                  notes.text = trip['notes'] as String;
                  start = trip['start'] as String;
                  end = trip['end'] as String;
                  client = trip['client'] as int;
                  status = trip['status'] as String;
                }
                initialized = true;
              }
              final tripEntries = records.entries
                  .where(
                    (e) =>
                        e['assignment'] == widget.id &&
                        e['category'] == 'travel',
                  )
                  .map((e) => e['day'])
                  .toSet();
              final today = dayKey(DateTime.now());
              final days = <String>[];
              if (trip != null) {
                var current = DateTime.parse(trip['start'] as String);
                final last = trip['end'] as String;
                while (dayKey(current).compareTo(last) <= 0) {
                  days.add(dayKey(current));
                  current = DateTime(
                    current.year,
                    current.month,
                    current.day + 1,
                  );
                }
              }
              return PopScope(
                canPop: !dirty && !busy,
                onPopInvokedWithResult: (didPop, _) async {
                  if (!didPop &&
                      !busy &&
                      await confirm(context, l.discard) &&
                      context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: days.length + 1,
                  itemBuilder: (context, index) {
                    if (index > 0) {
                      final day = days[index - 1];
                      final recorded = tripEntries.contains(day);
                      return ListTile(
                        title: Text(dateLabel(context, day)),
                        subtitle: Text(
                          recorded
                              ? l.recorded
                              : day.compareTo(today) > 0
                              ? l.future
                              : l.missing,
                        ),
                        trailing: recorded
                            ? null
                            : IconButton(
                                tooltip: l.travel,
                                icon: const Icon(Icons.add),
                                onPressed: dirty || status == 'cancelled'
                                    ? null
                                    : () => context.push(
                                        '/entry/travel?day=$day&trip=${widget.id}',
                                      ),
                              ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Choice(l.client, client, {
                          0: l.none,
                          for (final r
                              in records
                                  .ofKind('client')
                                  .where(
                                    (r) =>
                                        r['archived'] != true ||
                                        r['id'] == client,
                                  ))
                            r['id'] as int: r['name'] as String,
                        }, (value) => edit(() => client = value)),
                        const SizedBox(height: 12),
                        field(
                          destination,
                          l.destination,
                          onChanged: (_) => edit(() {}),
                        ),
                        DayField(
                          l.start,
                          start,
                          (value) => edit(() => start = value),
                        ),
                        DayField(
                          l.end,
                          end,
                          (value) => edit(() => end = value),
                        ),
                        Choice(l.status, status, {
                          for (final item in tripStatuses)
                            item: l.statusName(item),
                        }, (value) => edit(() => status = value)),
                        const SizedBox(height: 12),
                        field(notes, l.notes, onChanged: (_) => edit(() {})),
                        FilledButton(
                          onPressed: busy ? null : () => save(records),
                          child: Text(l.save),
                        ),
                        if (trip != null && status == 'active')
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => save(records, newStatus: 'completed'),
                            child: Text(l.completed),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}
