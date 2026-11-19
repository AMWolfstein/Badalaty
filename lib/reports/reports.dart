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
    final days = client == 0 && assignment == 0 && category.isEmpty
        ? records.recordedDays.where((record) {
            final date = record['day'] as String;
            return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
          }).toList()
        : <Record>[];
    return ListView(
      padding: sectionListPadding(context),
      children: [
        Row(
          children: [
            Expanded(
              child: DayField(
                l.fromDate,
                start,
                (v) => setState(() => start = v),
                shortDate: true,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: DayField(
                l.toDate,
                end,
                (v) => setState(() => end = v),
                shortDate: true,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          children: [
            Choice(
              l.client,
              client,
              {
                0: l.allClients,
                for (final r in records.ofKind('client'))
                  r['id'] as int: r['name'] as String,
              },
              (v) => setState(() => client = v),
              compact: true,
            ),
            Choice(
              l.assignment,
              assignment,
              {
                0: l.allAssignments,
                for (final r in records.ofKind('assignment'))
                  r['id'] as int: r['name'] as String,
              },
              (v) => setState(() => assignment = v),
              compact: true,
            ),
          ],
        ),
        Choice(l.category, category, {
          '': l.all,
          for (final c in Category.values) c.name: l.categoryName(c.name),
        }, (value) => setState(() => category = value)),
        GlassHighlight(
          label: l.periodAllowance,
          value: context.formattedNumber(ownerTotal(entries)),
          unit: l.egp,
          detail: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text('${dateLabel(context, start)} – ${dateLabel(context, end)}'),
              Text('${l.count} · ${entries.length + days.length}'),
            ],
          ),
        ),
        GlassHeading(l.allowanceBreakdown),
        for (final kind in Category.values)
          GlassContentCard(
            child: GlassRow(
              leading: GlassIcon(
                categoryIcons[kind.name]!,
                tone: categoryTones[kind.name]!,
              ),
              title: Text(l.categoryName(kind.name)),
              trailing: Text(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                context.money(
                  ownerTotal(
                    entries.where((item) => item['category'] == kind.name),
                  ),
                ),
              ),
            ),
          ),
        GlassHeading(l.exportReport),
        Choice(l.exportLanguage, chosenLanguage, {
          'ar': l.arabic,
          'en': l.english,
        }, (v) => setState(() => language = v)),
        GlassAction.icon(
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
                    final bytes = workbook(
                      entries,
                      locale,
                      metadata,
                      dayRecords: days,
                    );
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
