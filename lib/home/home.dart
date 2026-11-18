import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';

const categoryIcons = {
  'shared': Icons.groups_outlined,
  'travel': Icons.luggage_outlined,
  'ride': Icons.local_taxi_outlined,
};

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
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF071C49), Color(0xFF075BA9)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel(context, day),
                style: const TextStyle(color: Color(0xFFBDEBFF)),
              ),
              const SizedBox(height: 14),
              Text(l.owner, style: const TextStyle(color: Colors.white)),
              Text(
                context.money(ownerTotal(today)),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white38),
              Text(
                '${l.month}  ·  ${context.money(ownerTotal(month))}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${l.count}  ·  ${today.length}',
                style: const TextStyle(color: Color(0xFFBDEBFF)),
              ),
            ],
          ),
        ),
        if (trip != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.route_outlined),
              title: Text(trip['name'] as String),
              subtitle: Text(l.activeTrip),
              onTap: () => context.push('/assignment/${trip['id']}'),
            ),
          ),
        const SizedBox(height: 16),
        for (final category in Category.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/entry/${category.name}'),
              icon: Icon(categoryIcons[category.name]),
              label: Text(l.categoryName(category.name)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(l.recent, style: Theme.of(context).textTheme.titleMedium),
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
      leading: Icon(categoryIcons[entry['category']]),
      title: Text(entry['clientName'] as String? ?? context.l.none),
      subtitle: Text(
        '${context.l.categoryName(entry['category'] as String)} · ${dateLabel(context, entry['day'] as String)}\n${context.money(entry['owner'] as int)}',
      ),
      trailing: trailing,
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
    return Scaffold(
      appBar: AppBar(title: Text(l.addEntry)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final category in Category.values)
            ListTile(
              leading: Icon(categoryIcons[category.name]),
              title: Text(l.categoryName(category.name)),
              onTap: () => context.pushReplacement('/entry/${category.name}'),
            ),
        ],
      ),
    );
  }
}
