import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/state.dart';
import '../widgets/glass_design.dart';
import '../data/store.dart';
import '../forms.dart';
import '../l10n/labels.dart';

Future<int?> editDirectory(
  BuildContext context,
  String kind, {
  Record? previous,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DirectoryEditor(kind, previous),
  );
}

class _DirectoryEditor extends ConsumerStatefulWidget {
  const _DirectoryEditor(this.kind, this.previous);
  final String kind;
  final Record? previous;
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
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final employeeId = code.text.trim();
    if (name.text.trim().isEmpty) {
      feedback(context, context.l.missingFields);
      return;
    }
    setState(() => busy = true);
    try {
      final id = await ref.read(storeProvider).save(widget.kind, {
        ...?widget.previous,
        'name': name.text.trim(),
        if (widget.kind == 'employee')
          'code': employeeId.isEmpty ? null : employeeId,
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
  Widget build(BuildContext context) => GlassPanelDialog(
    title: Text(
      widget.previous != null
          ? context.l.edit
          : widget.kind == 'client'
          ? context.l.addClient
          : context.l.addColleague,
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          field(name, context.l.name),
          if (widget.kind == 'employee')
            field(code, context.l.employeeIdOptional),
        ],
      ),
    ),
    actions: [
      GlassSecondaryAction(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      GlassAction(onPressed: busy ? null : save, child: Text(context.l.save)),
    ],
  );
}
