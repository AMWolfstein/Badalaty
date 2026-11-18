import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/state.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';

Future<int?> editDirectory(
  BuildContext context,
  WidgetRef ref,
  String kind, {
  Record? previous,
  List<Record> employees = const [],
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DirectoryEditor(kind, previous, employees),
  );
}

class _DirectoryEditor extends ConsumerStatefulWidget {
  const _DirectoryEditor(this.kind, this.previous, this.employees);
  final String kind;
  final Record? previous;
  final List<Record> employees;
  @override
  ConsumerState<_DirectoryEditor> createState() => _DirectoryEditorState();
}

class _DirectoryEditorState extends ConsumerState<_DirectoryEditor> {
  late final name = TextEditingController(
    text: widget.previous?['name'] as String?,
  );
  late final code = TextEditingController(
    text: widget.previous?['code'] as String?,
  );
  late Set<int> members = Set<int>.from(
    widget.previous?['members'] as List? ?? [],
  );
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty ||
        (widget.kind == 'employee' && code.text.trim().isEmpty)) {
      feedback(context, context.l.missingFields);
      return;
    }
    setState(() => busy = true);
    try {
      final id = await ref.read(storeProvider).save(widget.kind, {
        ...?widget.previous,
        'name': name.text.trim(),
        if (widget.kind == 'employee') 'code': code.text.trim(),
        if (widget.kind == 'team') 'members': members.toList(),
      }, id: widget.previous?['id'] as int?);
      ref.invalidate(recordsProvider);
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) {
        feedback(context, context.l.error);
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.previous != null
          ? context.l.edit
          : switch (widget.kind) {
              'client' => context.l.addClient,
              'employee' => context.l.addColleague,
              _ => context.l.teams,
            },
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          field(name, context.l.name),
          if (widget.kind == 'employee') field(code, context.l.employeeId),
          if (widget.kind == 'team')
            SearchRecords(
              context.l.colleagues,
              widget.employees,
              members,
              onPick: (value) => setState(() => members = value),
              multiple: true,
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      FilledButton(onPressed: busy ? null : save, child: Text(context.l.save)),
    ],
  );
}
