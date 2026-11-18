import 'package:material_ui/material_ui.dart';

import '../allowances/calculation.dart';
import '../backup/files.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import 'workbook.dart';
import '../widgets/glass_navigation_bar.dart';
import '../widgets/glass_design.dart';
import '../home/home.dart' show categoryIcons, categoryTones;

class ReportsPage extends StatefulWidget {
  const ReportsPage(this.records, {super.key});
  final List<Record> records;
  @override
  State<ReportsPage> createState() => _ReportsState();
}

class _ReportsState extends State<ReportsPage> {
  final now = DateTime.now();
  late String start = dayKey(DateTime(now.year, now.month)),
      end = dayKey(DateTime(now.year, now.month + 1, 0));
  String language = '', category = '';
  int client = 0, assignment = 0;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final records = widget.records;
    final chosenLanguage = language.isEmpty ? l.localeName : language;
    final entries = records.entries
        .where(
          (r) =>
              (r['day'] as String).compareTo(start) >= 0 &&
              (r['day'] as String).compareTo(end) <= 0 &&
              (client == 0 || client == r['client']) &&
              (assignment == 0 || assignment == r['assignment']) &&
              (category.isEmpty || category == r['category']),
        )
        .toList();
    return ListView(
      padding: sectionListPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: DayField(l.start, start, (v) => setState(() => start = v)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: DayField(l.end, end, (v) => setState(() => end = v)),
            ),
          ],
        ),
        Choice(l.client, client, {
          0: l.all,
          for (final r in records.ofKind('client'))
            r['id'] as int: r['name'] as String,
        }, (v) => setState(() => client = v)),
        Choice(l.assignment, assignment, {
          0: l.all,
          for (final r in records.ofKind('assignment'))
            r['id'] as int: r['name'] as String,
        }, (v) => setState(() => assignment = v)),
        Choice(l.category, category, {
          '': l.all,
          for (final c in Category.values) c.name: l.categoryName(c.name),
        }, (v) => setState(() => category = v)),
        GlassHighlight(
          label: l.owner,
          value: context.money(ownerTotal(entries)),
          detail: Text('${l.count} · ${entries.length}'),
        ),
        GlassHeading(l.category),
        for (final kind in Category.values)
          Card(
            child: ListTile(
              leading: GlassIcon(
                categoryIcons[kind.name]!,
                tone: categoryTones[kind.name]!,
              ),
              title: Text(l.categoryName(kind.name)),
              trailing: Text(
                context.money(
                  ownerTotal(
                    entries.where((item) => item['category'] == kind.name),
                  ),
                ),
              ),
            ),
          ),
        GlassHeading(l.export),
        Choice(l.exportLanguage, chosenLanguage, {
          'ar': l.arabic,
          'en': l.english,
        }, (v) => setState(() => language = v)),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: Text(l.export),
          onPressed: busy || start.compareTo(end) > 0
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    final locale = await AppLocalizations.delegate.load(
                      Locale(chosenLanguage),
                    );
                    final metadata =
                        '$start – $end | ${locale.client}: ${records.byId(client)?['name'] ?? locale.all} | '
                        '${locale.assignment}: ${records.byId(assignment)?['name'] ?? locale.all} | '
                        '${locale.category}: ${category.isEmpty ? locale.all : locale.categoryName(category)} | ${locale.egp}';
                    final bytes = workbook(entries, locale, metadata);
                    if (context.mounted) {
                      await deliverFile(
                        context,
                        bytes,
                        'badalaty-$start-$end.xlsx',
                      );
                    }
                  } catch (_) {
                    if (context.mounted) feedback(context, l.error);
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
      ],
    );
  }
}
