import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/labels.dart';
import '../widgets/glass_design.dart';

Future<void> deliverFile(
  BuildContext context,
  Uint8List bytes,
  String name,
) async {
  final l = context.l;
  final share = await showDialog<bool>(
    context: context,
    builder: (context) => GlassPanelDialog(
      title: Text(name),
      actions: [
        GlassSecondaryAction(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        GlassSecondaryAction(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.share),
        ),
        GlassAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.save),
        ),
      ],
    ),
  );
  if (share == true && context.mounted) {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name)],
        fileNameOverrides: [name],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } else if (share == false) {
    await FilePicker.saveFile(fileName: name, bytes: bytes);
  }
}
