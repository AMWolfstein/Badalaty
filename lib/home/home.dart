import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../widgets/glass_navigation_bar.dart';
import '../widgets/glass_design.dart';

const categoryIcons = {
  'shared': Icons.directions_car_outlined,
  'travel': Icons.luggage_outlined,
  'ride': Icons.local_taxi_outlined,
};

const categoryTones = {'shared': 0, 'travel': 1, 'ride': 2};

class HomePage extends StatelessWidget {
  const HomePage(this.records, {super.key});
  final List<Record> records;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final day = dayKey(DateTime.now());
    final today = records.entries.where((r) => r['day'] == day);
    final month = records.entries.where((r) {
      final date = r['day'] as String;
      return date.startsWith(day.substring(0, 7)) && date.compareTo(day) <= 0;
    });
    final trip = records.activeOn(day);
    return ListView(
      padding: sectionListPadding(context),
      children: [
        GlassHighlight(
          label: '${l.owner} · ${l.today}',
          value: context.money(ownerTotal(today)),
          detail: Text('${l.month}  ·  ${context.money(ownerTotal(month))}'),
        ),
        GlassHeading(l.addEntry),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in Category.values)
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: category == Category.values.last ? 0 : 7,
                  ),
                  child: Card(
                    child: InkWell(
                      onTap: () => context.push('/entry/${category.name}'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 82),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlassIcon(
                                categoryIcons[category.name]!,
                                tone: categoryTones[category.name]!,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                l.categoryName(category.name),
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (trip != null) ...[
          GlassHeading(l.activeTrip),
          Card(
            child: ListTile(
              leading: const GlassIcon(Icons.place_outlined),
              title: Text(trip['name'] as String),
              subtitle: Text(
                records.byId(trip['client'])?['name'] as String? ??
                    l.activeTrip,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () => context.push('/assignment/${trip['id']}'),
            ),
          ),
        ],
        GlassHeading(
          l.recent,
          action: TextButton(
            onPressed: () => context.go('/history'),
            child: Text(l.history),
          ),
        ),
        if (records.entries.isEmpty) Text(l.empty),
        for (final entry in records.entries.take(5)) EntryTile(entry),
      ],
    );
  }
}

class EntryTile extends StatelessWidget {
  const EntryTile(this.entry, {this.trailing, super.key});
  final Record entry;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: GlassIcon(
        categoryIcons[entry['category']] ?? Icons.receipt_long_outlined,
        tone: categoryTones[entry['category']] ?? 0,
      ),
      title: Text(context.l.categoryName(entry['category'] as String)),
      subtitle: Text(
        '${entry['clientName'] as String? ?? context.l.none} · ${dateLabel(context, entry['day'] as String)}${trailing == null ? '' : '\n${context.money(entry['owner'] as int)}'}',
      ),
      trailing:
          trailing ??
          Text(
            context.money(entry['owner'] as int),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
      onTap: () =>
          context.push('/entry/${entry['category']}?id=${entry['id']}'),
    ),
  );
}

class AddEntryPage extends StatelessWidget {
  const AddEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return GlassScaffold(
      appBar: AppBar(title: Text(l.addEntry)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final category in Category.values)
            Card(
              child: ListTile(
                leading: GlassIcon(
                  categoryIcons[category.name]!,
                  tone: categoryTones[category.name]!,
                ),
                title: Text(l.categoryName(category.name)),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => context.pushReplacement('/entry/${category.name}'),
              ),
            ),
        ],
      ),
    );
  }
}
