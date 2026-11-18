import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../settings/directory.dart';
import 'calculation.dart';
import '../widgets/glass_design.dart';

class EntryPage extends ConsumerStatefulWidget {
  const EntryPage(
    this.category, {
    this.id,
    this.copy,
    this.initialDay,
    this.trip,
    super.key,
  });
  final Category category;
  final int? id, copy, trip;
  final String? initialDay;
  @override
  ConsumerState<EntryPage> createState() => _EntryState();
}

class _EntryState extends ConsumerState<EntryPage> {
  final base = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();
  late String day;
  int? client, assignment;
  bool initialized = false, dirty = false, busy = false;
  bool meals = true, lodging = true;
  String provider = 'Uber';
  Set<int> participants = {};
  Record? source;
  Record? existing;
  int mealRate = 100, lodgingRate = 70, basisPoints = 7000;

  void init(List<Record> records) {
    existing = records.byId(widget.id);
    source = existing ?? records.byId(widget.copy);
    day =
        existing?['day'] as String? ??
        widget.initialDay ??
        dayKey(DateTime.now());
    final active = records.byId(widget.trip) ?? records.activeOn(day);
    final copiedTrip = records.byId(source?['assignment']);
    if (existing != null) {
      assignment = existing!['assignment'] as int?;
    } else if (source != null) {
      final valid =
          copiedTrip != null &&
          day.compareTo(copiedTrip['start'] as String) >= 0 &&
          day.compareTo(copiedTrip['end'] as String) <= 0;
      assignment = valid ? copiedTrip['id'] as int : null;
    } else {
      assignment = active?['id'] as int?;
    }
    final recent = records.entries
        .where((entry) => records.byId(entry['client'])?['archived'] != true)
        .firstOrNull;
    client =
        (source?['client'] ?? active?['client'] ?? recent?['client']) as int?;
    final settings = records.settings;
    mealRate = (existing?['mealRate'] ?? settings['mealRate'] ?? 100) as int;
    lodgingRate =
        (existing?['lodgingRate'] ?? settings['lodgingRate'] ?? 70) as int;
    basisPoints =
        (existing?['basisPoints'] ?? settings['basisPoints'] ?? 7000) as int;
    base.text = source?['base']?.toString() ?? '';
    location.text = (source?['location'] ?? active?['name'] ?? '') as String;
    notes.text = source?['notes'] as String? ?? '';
    meals = source?['hasMeals'] as bool? ?? true;
    lodging = source?['hasLodging'] as bool? ?? true;
    provider = source?['provider'] as String? ?? 'Uber';
    participants = (source?['people'] as List? ?? [])
        .skip(1)
        .map((p) => p['id'] as int)
        .toSet();
    initialized = true;
  }

  @override
  void dispose() {
    base.dispose();
    location.dispose();
    notes.dispose();
    super.dispose();
  }

  void change(VoidCallback action) => setState(() {
    dirty = true;
    action();
  });

  Future<void> save(List<Record> records, bool addMore) async {
    final directory = records.byId(client);
    final trip = records.byId(assignment);
    final value = whole(base.text);
    final settings = records.settings;
    final isTravel = widget.category == Category.travel;
    final isShared = widget.category == Category.shared;
    if (directory == null ||
        (isTravel ? !meals && !lodging : value == null || value > maxAmount) ||
        (isShared &&
            existing == null &&
            ('${settings['name'] ?? ''}'.isEmpty ||
                '${settings['code'] ?? ''}'.isEmpty)) ||
        (trip != null &&
            (trip['client'] != client ||
                day.compareTo(trip['start'] as String) < 0 ||
                day.compareTo(trip['end'] as String) > 0))) {
      feedback(context, context.l.missingFields);
      return;
    }
    setState(() => busy = true);
    try {
      final duplicate = records.entries.any(
        (entry) =>
            entry['id'] != widget.id &&
            entry['day'] == day &&
            entry['client'] == client &&
            entry['category'] == widget.category.name &&
            entry['assignment'] == assignment &&
            (isTravel || entry['base'] == value) &&
            (widget.category != Category.ride || entry['provider'] == provider),
      );
      if (duplicate && !await confirm(context, context.l.duplicate)) return;
      final saved = (existing?['people'] as List? ?? []).cast<Record>();
      final people = [
        saved.firstOrNull ??
            {'id': 0, 'name': settings['name'], 'code': settings['code']},
        for (final employee in participants)
          saved.where((person) => person['id'] == employee).firstOrNull ??
              {
                'id': employee,
                'name': records.byId(employee)!['name'],
                'code': records.byId(employee)!['code'],
              },
      ];
      await ref.saveRecord('entry', {
        'day': day,
        'category': widget.category.name,
        'client': client,
        'clientName': existing?['client'] == client
            ? (existing?['clientName'])
            : directory['name'],
        'assignment': assignment,
        'assignmentName': existing?['assignment'] == assignment
            ? (existing?['assignmentName'])
            : trip?['name'],
        'location': location.text.trim(),
        'notes': notes.text.trim(),
        if (!isTravel) 'base': value,
        if (isShared) 'people': people,
        if (isTravel) ...{
          'hasMeals': meals,
          'hasLodging': lodging,
          'mealRate': mealRate,
          'lodgingRate': lodgingRate,
          'basisPoints': basisPoints,
        },
        if (widget.category == Category.ride) 'provider': provider,
      }, id: widget.id);
      if (!mounted) return;
      dirty = false;
      if (addMore) {
        base.clear();
        notes.clear();
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) feedback(context, context.l.error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final data = ref.watch(recordsProvider);
    return GlassScaffold(
      appBar: AppBar(title: Text(l.categoryName(widget.category.name))),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l.error)),
        data: (records) {
          if (!initialized) init(records);
          final isShared = widget.category == Category.shared;
          final isTravel = widget.category == Category.travel;
          final amount = whole(base.text);
          final count = participants.length + 1;
          final lastRotation = records.entries.fold<int>(-1, (max, entry) {
            final index = entry['rotation'] as int;
            return index > max ? index : max;
          });
          final split = isShared && amount != null && amount <= maxAmount
              ? sharedAllowance(
                  amount,
                  count,
                  existing?['rotation'] as int? ?? lastRotation + 1,
                )
              : null;
          final dailyAmount =
              (meals ? mealRate : 0) +
              (lodging ? accommodationAllowance(lodgingRate, basisPoints) : 0);
          final employees = records
              .ofKind('employee')
              .where(
                (r) => r['archived'] != true || participants.contains(r['id']),
              );
          final teams = records
              .ofKind('team')
              .where((r) => r['archived'] != true);
          return PopScope(
            canPop: !dirty && !busy,
            onPopInvokedWithResult: (didPop, _) async {
              if (!didPop &&
                  !busy &&
                  await confirm(context, l.discard) &&
                  context.mounted) {
                setState(() => dirty = false);
                Navigator.pop(context);
              }
            },
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DayField(
                                l.date,
                                day,
                                (value) => change(() => day = value),
                                shortDate: true,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SearchRecords(
                                      l.client,
                                      records
                                          .ofKind('client')
                                          .where(
                                            (r) =>
                                                r['archived'] != true ||
                                                r['id'] == client,
                                          ),
                                      {?client},
                                      onPick: (ids) => change(() {
                                        client = ids.first;
                                        assignment = null;
                                      }),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l.addClient,
                                    icon: const Icon(Icons.person_add_alt),
                                    onPressed: () async {
                                      final id = await editDirectory(
                                        context,
                                        ref,
                                        'client',
                                      );
                                      if (id != null && mounted) {
                                        change(() {
                                          client = id;
                                          assignment = null;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Choice<int>(
                          l.assignment,
                          assignment ?? 0,
                          {
                            0: l.none,
                            for (final trip
                                in records
                                    .ofKind('assignment')
                                    .where((r) => r['client'] == client))
                              trip['id'] as int: trip['name'] as String,
                          },
                          (value) => change(
                            () => assignment = value == 0 ? null : value,
                          ),
                        ),
                        const SizedBox(height: 16),
                        field(
                          location,
                          l.location,
                          onChanged: (_) => change(() {}),
                        ),
                        if (isTravel) ...[
                          Card(
                            child: SwitchListTile(
                              secondary: const GlassIcon(
                                Icons.restaurant_outlined,
                              ),
                              title: Text(l.meals),
                              subtitle: Text(context.money(mealRate)),
                              value: meals,
                              onChanged: (value) => change(() => meals = value),
                            ),
                          ),
                          Card(
                            child: SwitchListTile(
                              secondary: const GlassIcon(
                                Icons.hotel_outlined,
                                tone: 1,
                              ),
                              title: Text(l.lodging),
                              subtitle: Text(
                                context.money(
                                  accommodationAllowance(
                                    lodgingRate,
                                    basisPoints,
                                  ),
                                ),
                              ),
                              value: lodging,
                              onChanged: (value) =>
                                  change(() => lodging = value),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(l.rounding),
                          ),
                        ] else
                          field(
                            base,
                            isShared ? l.base : l.amount,
                            number: true,
                            onChanged: (_) => change(() {}),
                          ),
                        if (isShared) ...[
                          Row(
                            children: [
                              Expanded(
                                child: SearchRecords(
                                  l.colleagues,
                                  employees,
                                  participants,
                                  multiple: true,
                                  onPick: (value) =>
                                      change(() => participants = value),
                                ),
                              ),
                              IconButton(
                                tooltip: l.addColleague,
                                icon: const Icon(Icons.person_add_alt),
                                onPressed: () async {
                                  final id = await editDirectory(
                                    context,
                                    ref,
                                    'employee',
                                  );
                                  if (id != null && mounted) {
                                    change(() => participants.add(id));
                                  }
                                },
                              ),
                            ],
                          ),
                          if (teams.isNotEmpty)
                            Choice<int>(
                              l.teams,
                              0,
                              {
                                0: l.none,
                                for (final team in teams)
                                  team['id'] as int: team['name'] as String,
                              },
                              (value) => change(() {
                                final activeIds = employees
                                    .map((r) => r['id'])
                                    .toSet();
                                participants = Set<int>.from(
                                  records.byId(value)?['members'] as List? ??
                                      [],
                                ).where(activeIds.contains).toSet();
                              }),
                            ),
                          if (split != null)
                            ListTile(
                              title: Text(l.total),
                              trailing: Text(context.money(split.total)),
                              subtitle: Text(
                                '${l.people} $count · ${l.multiplier} ×${split.multiplier}',
                              ),
                            ),
                        ],
                        if (widget.category == Category.ride)
                          Choice(l.provider, provider, {
                            'Uber': 'Uber',
                            'DiDi': 'DiDi',
                            'inDrive': 'inDrive',
                            'other': l.other,
                          }, (value) => change(() => provider = value)),
                        const SizedBox(height: 12),
                        field(notes, l.notes, onChanged: (_) => change(() {})),
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: ListTile(
                            leading: const GlassIcon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            title: Text(l.owner),
                            trailing: Text(
                              context.money(
                                isTravel
                                    ? dailyAmount
                                    : isShared
                                    ? split?.shares.first ?? 0
                                    : amount ?? 0,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: busy ? null : () => save(records, false),
                          child: Text(l.save),
                        ),
                        if (widget.id == null)
                          OutlinedButton(
                            onPressed: busy ? null : () => save(records, true),
                            child: Text(l.saveMore),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
