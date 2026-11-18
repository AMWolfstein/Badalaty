import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
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
  const SettingsPage(this.records, {super.key}) : _section = null;
  const SettingsPage._group(this.records, this._section);

  final _SettingsSection? _section;
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
        for (final kind in ['client', 'employee', 'team'])
          ExpansionTile(
            title: Text(switch (kind) {
              'client' => l.clients,
              'employee' => l.colleagues,
              _ => l.teams,
            }),
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l.add),
                onTap: () => editDirectory(
                  context,
                  ref,
                  kind,
                  employees: records
                      .ofKind('employee')
                      .where((r) => r['archived'] != true)
                      .toList(),
                ),
              ),
              for (final record in records.ofKind(kind))
                ListTile(
                  title: Text(record['name'] as String),
                  subtitle: Text(
                    [
                      if (record['code'] != null) record['code'],
                      if (record['archived'] == true) l.archived,
                    ].join(' · '),
                  ),
                  onTap: () => editDirectory(
                    context,
                    ref,
                    kind,
                    previous: record,
                    employees: records.ofKind('employee').toList(),
                  ),
                  trailing: IconButton(
                    tooltip: record['archived'] == true
                        ? l.unarchive
                        : l.archive,
                    icon: Icon(
                      record['archived'] == true
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    onPressed: () async {
                      try {
                        await ref.saveRecord(kind, {
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
          ),
      ],
      _SettingsSection.reminders => <Widget>[
        SwitchListTile(
          title: Text(l.reminders),
          value: settings['reminders'] == true,
          onChanged: (value) async {
            if (value) await requestReminderPermission();
            if (context.mounted) {
              await update(context, ref, {'reminders': value});
            }
          },
        ),
        ListTile(
          title: Text(l.reminderTime),
          subtitle: Text(time.format(context)),
          onTap: () async {
            final chosen = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (chosen != null && context.mounted) {
              await update(context, ref, {
                'hour': chosen.hour,
                'minute': chosen.minute,
              });
            }
          },
        ),
        ExpansionTile(
          title: Text(l.workweek),
          children: [
            for (var day = 1; day <= 7; day++)
              CheckboxListTile(
                title: Text(
                  MaterialLocalizations.of(context).narrowWeekdays[day % 7],
                ),
                value: workweek.contains(day),
                onChanged: (value) {
                  final next = {...workweek};
                  value == true ? next.add(day) : next.remove(day);
                  update(context, ref, {'workweek': next.toList()});
                },
              ),
          ],
        ),
      ],
      _SettingsSection.backups => <Widget>[
        ListTile(
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
        ListTile(
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
        ListTile(
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
        ListTile(
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
          ListTile(
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
      children: [
        for (final item in items)
          if (item is ListTile ||
              item is ExpansionTile ||
              item is SwitchListTile)
            Card(child: item)
          else
            item,
      ],
    );
  }

  Widget _sectionTile(
    BuildContext context,
    _SettingsSection section,
    String title,
    IconData icon, {
    String? subtitle,
  }) => ListTile(
    leading: GlassIcon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    trailing: Icon(
      Directionality.of(context) == TextDirection.rtl
          ? Icons.chevron_left
          : Icons.chevron_right,
    ),
    onTap: () => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Consumer(
          builder: (context, ref, _) => GlassScaffold(
            appBar: AppBar(title: Text(title)),
            body: SafeArea(
              top: false,
              child: SettingsPage._group(
                ref.watch(recordsProvider).value ?? records,
                section,
              ),
            ),
          ),
        ),
      ),
    ),
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
      if (a.text.trim().isEmpty || b.text.trim().isEmpty) {
        feedback(context, context.l.missingFields);
        return;
      }
      changes = {'name': a.text.trim(), 'code': b.text.trim()};
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
      appBar: AppBar(title: Text(widget.rates ? l.rates : l.profile)),
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
                    Card(
                      child: ListTile(
                        leading: const GlassIcon(Icons.person_outline),
                        title: Text(
                          widget.settings['name'] as String? ?? l.profile,
                        ),
                        subtitle: Text(
                          widget.settings['code'] as String? ?? l.employeeId,
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
                    widget.rates ? l.lodging : l.employeeId,
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
                child: FilledButton(
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
