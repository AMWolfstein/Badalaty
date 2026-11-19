import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../widgets/glass_navigation_bar.dart';
import '../widgets/glass_design.dart';

const tripStatuses = ['planned', 'active', 'completed', 'cancelled'];

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage(this.records, {super.key});
  final List<Record> records;

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  String? filter;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final trips = widget.records
        .ofKind('assignment')
        .where((trip) => filter == null || trip['status'] == filter)
        .toList();
    return ListView(
      padding: sectionListPadding(context),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in [null, ...tripStatuses])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: GlassFilterChip(
                    label: status == null ? l.all : l.statusName(status),
                    selected: status == filter,
                    onTap: () => setState(() => filter = status),
                  ),
                ),
            ],
          ),
        ),
        if (trips.isEmpty) GlassHeading(l.empty),
        for (final status in ['active', 'planned', 'completed', 'cancelled'])
          if (trips.any((trip) => trip['status'] == status)) ...[
            GlassHeading(l.statusName(status)),
            for (final trip in trips.where((trip) => trip['status'] == status))
              if (status == 'active')
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => context.push('/assignment/${trip['id']}'),
                    child: GlassHighlight(
                      label:
                          widget.records.byId(trip['client'])?['name']
                              as String? ??
                          l.client,
                      value: trip['name'] as String,
                      isBalance: false,
                      detail: Text(
                        '${dateLabel(context, trip['start'] as String)} – ${dateLabel(context, trip['end'] as String)}',
                      ),
                    ),
                  ),
                )
              else
                GlassContentCard(
                  child: GlassRow(
                    leading: GlassIcon(
                      status == 'active'
                          ? Icons.place_outlined
                          : Icons.route_outlined,
                    ),
                    title: Text(trip['name'] as String),
                    subtitle: Text(
                      '${dateLabel(context, trip['start'] as String)} – ${dateLabel(context, trip['end'] as String)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/assignment/${trip['id']}'),
                  ),
                ),
          ],
        GlassAction.icon(
          onPressed: () => context.push('/assignment/new'),
          icon: const Icon(Icons.add),
          label: Text(l.newAssignmentTitle),
        ),
      ],
    );
  }
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
  late bool editing = widget.id == null;

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
    return GlassScaffold(
      appBar: GlassHeader(
        title: Text(
          widget.id == null ? l.newAssignmentTitle : l.tripDetailsTitle,
        ),
        actions: [
          if (!editing)
            GlassIconAction(
              tooltip: l.edit,
              floating: true,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => editing = true),
            ),
        ],
      ),
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
                      return GlassContentCard(
                        child: GlassRow(
                          leading: GlassIcon(
                            recorded
                                ? Icons.check_circle_outline
                                : Icons.event_outlined,
                            tone: recorded ? 2 : 0,
                          ),
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
                              : GlassIconAction(
                                  tooltip: l.travel,
                                  icon: const Icon(Icons.add),
                                  onPressed: dirty || status == 'cancelled'
                                      ? null
                                      : () => context.push(
                                          '/entry/travel?day=$day&trip=${widget.id}',
                                        ),
                                ),
                        ),
                      );
                    }
                    if (trip != null && !editing) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassHighlight(
                            label:
                                records.byId(client)?['name'] as String? ??
                                l.client,
                            value: destination.text,
                            isBalance: false,
                            detail: Text(
                              '${dateLabel(context, start)} – ${dateLabel(context, end)} · ${l.statusName(status)}',
                            ),
                          ),
                          if (notes.text.trim().isNotEmpty) ...[
                            GlassHeading(l.notes),
                            GlassContentCard(
                              child: GlassRow(
                                leading: const GlassIcon(Icons.notes_outlined),
                                title: Text(notes.text),
                              ),
                            ),
                          ],
                          if (status == 'active')
                            GlassSecondaryAction(
                              onPressed: busy
                                  ? null
                                  : () => save(records, newStatus: 'completed'),
                              child: Text(l.completed),
                            ),
                          GlassHeading(l.travel),
                        ],
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Expanded(
                              child: DayField(
                                l.start,
                                start,
                                (value) => edit(() => start = value),
                                shortDate: true,
                              ),
                            ),
                            Expanded(
                              child: DayField(
                                l.end,
                                end,
                                (value) => edit(() => end = value),
                                shortDate: true,
                              ),
                            ),
                          ],
                        ),
                        Choice(l.status, status, {
                          for (final item in tripStatuses)
                            item: l.statusName(item),
                        }, (value) => edit(() => status = value)),
                        const SizedBox(height: 12),
                        field(notes, l.notes, onChanged: (_) => edit(() {})),
                        GlassAction(
                          onPressed: busy ? null : () => save(records),
                          child: Text(l.save),
                        ),
                        if (trip != null && status == 'active')
                          GlassSecondaryAction(
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
