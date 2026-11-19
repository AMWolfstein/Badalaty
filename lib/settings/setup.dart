import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/state.dart';
import '../forms.dart';
import '../l10n/labels.dart';
import '../widgets/glass_design.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({
    required this.language,
    required this.theme,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    super.key,
  });

  final String language;
  final String theme;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onThemeChanged;

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final name = TextEditingController();
  late final code = TextEditingController(
    text: ref.read(recordsProvider).value?.settings['code'] as String?,
  );
  late String language = widget.language;
  late String appearance = widget.theme;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final displayName = name.text.trim();
    if (displayName.isEmpty || busy) return;
    final settings = ref.read(recordsProvider).value?.settings ?? {};
    final employeeId = code.text.trim();
    setState(() => busy = true);
    try {
      await ref.saveRecord('settings', {
        ...settings,
        'name': displayName,
        'code': employeeId.isEmpty ? null : employeeId,
        'language': language,
        'theme': appearance,
      }, id: settings['id'] as int?);
    } catch (_) {
      if (mounted) {
        feedback(context, context.l.error);
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final theme = Theme.of(context);
    return GlassScaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  minHeight: (constraints.maxHeight - 40).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/branding/badalaty-icon.png',
                      height: 88,
                      cacheHeight: 264,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.setupWelcome,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.setupIntro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Choice(
                            l.language,
                            language,
                            {
                              'system': l.system,
                              'ar': 'العربية',
                              'en': 'English',
                            },
                            (value) {
                              setState(() => language = value);
                              widget.onLanguageChanged(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Choice(
                            l.theme,
                            appearance,
                            {
                              'system': l.system,
                              'light': l.light,
                              'dark': l.dark,
                            },
                            (value) {
                              setState(() => appearance = value);
                              widget.onThemeChanged(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    field(name, l.setupName),
                    const SizedBox(height: 12),
                    field(code, l.employeeIdOptional),
                    const SizedBox(height: 24),
                    ValueListenableBuilder(
                      valueListenable: name,
                      builder: (context, value, _) => GlassAction(
                        onPressed: busy || value.text.trim().isEmpty
                            ? null
                            : save,
                        child: Text(l.setupStart),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.setupEdit,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
