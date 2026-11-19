import 'package:material_ui/material_ui.dart';

import '../l10n/labels.dart';
import '../widgets/glass_design.dart';
import 'github_updates.dart';

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updates = GithubUpdates();
  late Future<UpdateCheck> _check = _updates.check();
  bool _busy = false;
  bool _downloaded = false;
  bool _needsPermission = false;
  bool _failed = false;
  double? _progress;

  Future<void> _install(GithubRelease release) async {
    setState(() {
      _busy = true;
      _failed = false;
      _needsPermission = false;
    });
    try {
      if (!_downloaded) {
        await _updates.download(release, (value) {
          if (mounted) setState(() => _progress = value);
        });
        if (!mounted) return;
        _downloaded = true;
      }
      final opened = await _updates.install(release);
      if (mounted) setState(() => _needsPermission = !opened);
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _downloaded = false;
          _progress = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return FutureBuilder<UpdateCheck>(
      future: _check,
      builder: (context, snapshot) {
        final checked = snapshot.data;
        final release = checked?.release;
        final notes = release?.notes[l.localeName] ?? release?.notes['en'];
        return PopScope(
          canPop: !_busy,
          child: GlassPanelDialog(
            title: Text(l.appUpdates),
            scrollable: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.connectionState != ConnectionState.done) ...[
                  Text(l.checkingForUpdates),
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ] else if (snapshot.hasError) ...[
                  Text(l.updateCheckFailed),
                ] else if (checked != null) ...[
                  Text(l.installedVersion(checked.installed)),
                  const SizedBox(height: 8),
                  if (!checked.supported)
                    Text(l.updateUnsupported)
                  else if (release == null)
                    Text(l.noUpdateAvailable)
                  else ...[
                    Text(l.updateAvailable(release.version)),
                    if (notes != null) ...[
                      const SizedBox(height: 8),
                      Text(notes),
                    ],
                    if (_busy && !_downloaded) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _progress),
                    ],
                    if (_needsPermission) ...[
                      const SizedBox(height: 8),
                      Text(l.updateInstallPermission),
                    ],
                    if (_failed) ...[
                      const SizedBox(height: 8),
                      Text(l.updateInstallFailed),
                    ],
                  ],
                ],
              ],
            ),
            actions: [
              GlassSecondaryAction(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
              if (snapshot.hasError)
                GlassAction(
                  onPressed: () => setState(() => _check = _updates.check()),
                  child: Text(l.retryUpdate),
                )
              else if (release != null)
                GlassAction(
                  onPressed: _busy ? null : () => _install(release),
                  child: Text(_downloaded ? l.installUpdate : l.downloadUpdate),
                ),
            ],
          ),
        );
      },
    );
  }
}
