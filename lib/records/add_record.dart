import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../widgets/glass_design.dart';

class AddRecordPage extends StatelessWidget {
  const AddRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return GlassScaffold(
      appBar: AppBar(title: Text(l.addEntry)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassHeading(l.recordType),
            for (final status in recordedDayStatuses)
              Card(
                child: ListTile(
                  leading: _DayIcon(status),
                  title: Text(l.statusName(status)),
                  subtitle: Text(
                    '${status == 'leave' ? l.leaveRecordDescription : l.officeRecordDescription} · ${context.money(0)}',
                  ),
                  trailing: const Icon(Icons.navigate_next),
                  onTap: () => context.push('/record/$status'),
                ),
              ),
            Card(
              child: ListTile(
                leading: const GlassIcon(Icons.account_balance_wallet_outlined),
                title: Text(l.allowanceOption),
                subtitle: Text(l.allowanceOptionDescription),
                trailing: const Icon(Icons.navigate_next),
                onTap: () => context.push('/allowances/add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DayRecordPage extends ConsumerStatefulWidget {
  const DayRecordPage(this.status, {super.key});

  final String status;

  @override
  ConsumerState<DayRecordPage> createState() => _DayRecordPageState();
}

class _DayRecordPageState extends ConsumerState<DayRecordPage> {
  String day = dayKey(DateTime.now());
  bool saving = false;

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await ref.saveRecord('day', {'day': day, 'status': widget.status});
      if (mounted) context.go('/history?day=$day');
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        feedback(context, context.l.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return GlassScaffold(
      appBar: AppBar(
        title: Text(widget.status == 'leave' ? l.recordLeave : l.recordOffice),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: _DayIcon(widget.status),
                      title: Text(l.statusName(widget.status)),
                      subtitle: Text(
                        widget.status == 'leave'
                            ? l.leaveRecordDescription
                            : l.officeRecordDescription,
                      ),
                    ),
                  ),
                  DayField(l.date, day, (value) => setState(() => day = value)),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      title: Text(l.recordValue),
                      trailing: Text(context.money(0)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.check),
                  label: Text(l.saveRecordLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DayRecordTile extends StatelessWidget {
  const DayRecordTile(this.record, {super.key});

  final Record record;

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String;
    return Card(
      child: ListTile(
        leading: _DayIcon(status),
        title: Text(context.l.statusName(status)),
        subtitle: Text(dateLabel(context, record['day'] as String)),
        trailing: Text(context.money(0)),
      ),
    );
  }
}

class _DayIcon extends StatelessWidget {
  const _DayIcon(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => status == 'leave'
      ? const GlassIcon(Icons.beach_access_outlined, tone: 1)
      : const GlassIcon(Icons.business_outlined, tone: 2);
}
