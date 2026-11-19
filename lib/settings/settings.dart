import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../allowances/calculation.dart';
import '../backup/files.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../updates/update_dialog.dart';
import '../widgets/platform.dart';
import 'directory.dart';
import '../widgets/glass_navigation_bar.dart';
import '../widgets/glass_design.dart';

enum _SettingsSection { directory, reminders, backups }

class SettingsPage extends ConsumerWidget {
  const SettingsPage(this.records, {super.key})
    : _section = null,
      _directoryKind = 'client',
      _onDirectoryKind = null;
  const SettingsPage._group(
    this.records,
    this._section,
    this._directoryKind,
    this._onDirectoryKind,
  );

  final _SettingsSection? _section;
  final String _directoryKind;
  final ValueChanged<String>? _onDirectoryKind;
  final List<Record> records;

  Future<void> update(BuildContext context, WidgetRef ref, Record patch) async {
    try {
      await ref.saveRecord('settings', {
        ...records.settings,
        ...patch,
      }, id: records.settings['id'] as int?);
    } catch (_) {
      if (context.mounted) feedback(context, context.l.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final settings = records.settings;
    final workweek = Set<int>.from(
      settings['workweek'] as List? ?? [7, 1, 2, 3, 4],
    );
    final time = TimeOfDay(
      hour: settings['hour'] as int? ?? 18,
      minute: settings['minute'] as int? ?? 0,
    );
    final items = switch (_section) {
      _SettingsSection.directory => <Widget>[
        Wrap(
          spacing: 8,
          children: [
            for (final (kind, label) in [
              ('client', l.clients),
              ('employee', l.colleagues),
            ])
              GlassFilterChip(
                label: label,
                selected: _directoryKind == kind,
                onTap: () => _onDirectoryKind?.call(kind),
              ),
          ],
        ),
        GlassHeading(
          _directoryKind == 'client' ? l.clients : l.colleagues,
          action: GlassAction.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(l.add),
            onPressed: () => editDirectory(context, _directoryKind),
          ),
        ),
        for (final record in records.ofKind(_directoryKind))
          GlassRow(
            leading: GlassIcon(
              _directoryKind == 'client'
                  ? Icons.business_outlined
                  : Icons.person_outline,
            ),
            title: Text(record['name'] as String),
            subtitle:
                record['archived'] == true ||
                    (record['code'] as String? ?? '').isNotEmpty
                ? Text(
                    [
                      if ((record['code'] as String? ?? '').isNotEmpty)
                        record['code'],
                      if (record['archived'] == true) l.archived,
                    ].join(' · '),
                  )
                : null,
            onTap: () =>
                editDirectory(context, _directoryKind, previous: record),
            trailing: GlassIconAction(
              tooltip: record['archived'] == true ? l.unarchive : l.archive,
              icon: Icon(
                record['archived'] == true
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              onPressed: () async {
                try {
                  await ref.saveRecord(_directoryKind, {
                    ...record,
                    'archived': record['archived'] != true,
                  }, id: record['id'] as int);
                } catch (_) {
                  if (context.mounted) feedback(context, l.error);
                }
              },
            ),
          ),
      ],
      _SettingsSection.reminders => <Widget>[
        GlassToggleRow(
          secondary: const GlassIcon(Icons.notifications_outlined),
          label: l.reminders,
          value: settings['reminders'] == true,
          onChanged: (value) async {
            if (value) await requestReminderPermission();
            if (context.mounted) {
              await update(context, ref, {'reminders': value});
            }
          },
        ),
        GlassRow(
          leading: const GlassIcon(Icons.schedule_outlined),
          title: Text(l.reminderTime),
          subtitle: Text(time.format(context)),
          onTap: () async {
            final today = DateTime.now();
            final chosen = await glassDateTimePicker(
              context,
              initial: DateTime(
                today.year,
                today.month,
                today.day,
                time.hour,
                time.minute,
              ),
              timeOnly: true,
            );
            if (chosen != null && context.mounted) {
              await update(context, ref, {
                'hour': chosen.hour,
                'minute': chosen.minute,
              });
            }
          },
        ),
        GlassHeading(l.workweek),
        for (final day in [6, 7, 1, 2, 3, 4, 5])
          GlassToggleRow(
            secondary: const GlassIcon(Icons.calendar_today_outlined),
            label: DateFormat.EEEE(l.localeName)
                .format(DateTime(2026, 1, 5 + day - 1)),
            value: workweek.contains(day),
            onChanged: (value) {
              final next = {...workweek};
              value ? next.add(day) : next.remove(day);
              update(context, ref, {'workweek': next.toList()});
            },
          ),
      ],
      _SettingsSection.backups => <Widget>[
        GlassRow(
          title: Text(l.backup),
          leading: const Icon(Icons.download),
          onTap: () async {
            try {
              final contents = await ref.read(storeProvider).backup();
              if (context.mounted) {
                await deliverFile(
                  context,
                  Uint8List.fromList(utf8.encode(contents)),
                  'badalaty.json',
                );
              }
            } catch (_) {
              if (context.mounted) feedback(context, l.error);
            }
          },
        ),
        GlassRow(
          title: Text(l.restore),
          leading: const Icon(Icons.restore),
          onTap: () async {
            try {
              final picked = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              final bytes = await picked?.readAsBytes();
              if (bytes == null ||
                  !context.mounted ||
                  !await confirm(context, l.restoreWarning) ||
                  !context.mounted) {
                return;
              }
              await ref.read(storeProvider).restore(utf8.decode(bytes));
              ref.invalidate(recordsProvider);
              if (context.mounted) feedback(context, l.restored);
            } catch (_) {
              if (context.mounted) feedback(context, l.error);
            }
          },
        ),
      ],
      null => <Widget>[
        GlassRow(
          leading: const GlassIcon(Icons.person_outline),
          title: Text(l.profile),
          subtitle: Text(settings['name'] as String? ?? l.none),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => _SettingsEditor(settings, false)),
          ),
        ),
        GlassHeading(l.preferencesSection),
        Choice(l.language, settings['language'] as String? ?? 'system', {
          'system': l.system,
          'ar': l.arabic,
          'en': l.english,
        }, (value) => update(context, ref, {'language': value})),
        Choice(l.theme, settings['theme'] as String? ?? 'system', {
          'system': l.system,
          'light': l.light,
          'dark': l.dark,
        }, (value) => update(context, ref, {'theme': value})),
        _sectionTile(
          context,
          _SettingsSection.reminders,
          l.reminders,
          Icons.notifications_outlined,
          subtitle: time.format(context),
        ),
        GlassHeading(l.allowanceSettingsSection),
        GlassRow(
          leading: const GlassIcon(Icons.tune_outlined, tone: 1),
          title: Text(l.rates),
          subtitle: Text(l.rounding),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => _SettingsEditor(settings, true)),
          ),
        ),
        _sectionTile(
          context,
          _SettingsSection.directory,
          l.directoryTitle,
          Icons.groups_outlined,
        ),
        GlassHeading(l.dataSettingsSection),
        _sectionTile(
          context,
          _SettingsSection.backups,
          l.backup,
          Icons.cloud_download_outlined,
        ),
        if (Platform.isAndroid)
          GlassRow(
            leading: const Icon(Icons.system_update_outlined),
            title: Text(l.appUpdates),
            onTap: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const UpdateDialog(),
            ),
          ),
      ],
    };
    return ListView(
      padding: sectionListPadding(context),
      children: _settingsGroups(items).toList(),
    );
  }

  Iterable<Widget> _settingsGroups(List<Widget> items) sync* {
    var group = <Widget>[];
    for (final item in items) {
      if (item is GlassRow || item is GlassToggleRow) {
        group.add(item);
      } else {
        if (group.isNotEmpty) yield GlassContentGroup(children: group);
        group = [];
        yield item;
      }
    }
    if (group.isNotEmpty) yield GlassContentGroup(children: group);
  }

  Widget _sectionTile(
    BuildContext context,
    _SettingsSection section,
    String title,
    IconData icon, {
    String? subtitle,
  }) => GlassRow(
    leading: GlassIcon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      var kind = 'client';
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Consumer(
            builder: (context, ref, _) => StatefulBuilder(
              builder: (context, setState) => GlassScaffold(
                appBar: GlassHeader(title: Text(title)),
                body: SafeArea(
                  top: false,
                  child: SettingsPage._group(
                    ref.watch(recordsProvider).value ?? records,
                    section,
                    kind,
                    (value) => setState(() => kind = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SettingsEditor extends ConsumerStatefulWidget {
  const _SettingsEditor(this.settings, this.rates);
  final Record settings;
  final bool rates;
  @override
  ConsumerState<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends ConsumerState<_SettingsEditor> {
  late final a = TextEditingController(
    text: widget.rates
        ? '${widget.settings['mealRate'] ?? 100}'
        : widget.settings['name'] as String?,
  );
  late final b = TextEditingController(
    text: widget.rates
        ? '${widget.settings['lodgingRate'] ?? 70}'
        : widget.settings['code'] as String?,
  );
  late final c = TextEditingController(
    text: _percent(widget.settings['basisPoints'] as int? ?? 7000),
  );
  bool busy = false;

  String _percent(int value) =>
      '${value ~/ 100}.${(value % 100).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    a.dispose();
    b.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    Record changes;
    if (widget.rates) {
      final meals = whole(a.text), lodging = whole(b.text);
      final match = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$')
          .firstMatch(normalizedNumber(c.text));
      final percent = match == null
          ? null
          : int.parse(match[1]!) * 100 +
                int.parse((match[2] ?? '').padRight(2, '0'));
      if (meals == null ||
          lodging == null ||
          percent == null ||
          ratesInvalid(meals, lodging, percent)) {
        feedback(context, context.l.missingFields);
        return;
      }
      changes = {
        'mealRate': meals,
        'lodgingRate': lodging,
        'basisPoints': percent,
      };
    } else {
      if (a.text.trim().isEmpty) {
        feedback(context, context.l.missingFields);
        return;
      }
      final employeeId = b.text.trim();
      changes = {
        'name': a.text.trim(),
        'code': employeeId.isEmpty ? null : employeeId,
      };
    }
    setState(() => busy = true);
    try {
      await ref.saveRecord('settings', {
        ...widget.settings,
        ...changes,
      }, id: widget.settings['id'] as int?);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        feedback(context, context.l.error);
        setState(() => busy = false);
      }
    }
  }

  bool ratesInvalid(int meals, int lodging, int percent) =>
      meals > maxAmount || lodging > maxAmount || percent > 10000;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return GlassScaffold(
      appBar: GlassHeader(title: Text(widget.rates ? l.rates : l.profile)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.rates)
                    GlassHeading(l.travel)
                  else
                    GlassContentCard(
                      child: GlassRow(
                        leading: const GlassIcon(Icons.person_outline),
                        title: Text(
                          widget.settings['name'] as String? ?? l.profile,
                        ),
                        subtitle: Text(
                          widget.settings['code'] as String? ??
                              l.employeeIdOptional,
                        ),
                      ),
                    ),
                  field(
                    a,
                    widget.rates ? l.meals : l.name,
                    number: widget.rates,
                  ),
                  field(
                    b,
                    widget.rates ? l.lodging : l.employeeIdOptional,
                    number: widget.rates,
                  ),
                  if (widget.rates) field(c, l.percentage, number: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: GlassAction(
                  onPressed: busy ? null : save,
                  child: Text(l.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
