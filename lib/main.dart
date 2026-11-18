import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:go_router/go_router.dart';

import 'allowances/calculation.dart';
import 'allowances/entry.dart';
import 'assignments/assignments.dart';
import 'data/state.dart';
import 'forms.dart';
import 'history/history.dart';
import 'home/home.dart';
import 'l10n/app_localizations.dart';
import 'l10n/labels.dart';
import 'reports/reports.dart';
import 'records/add_record.dart';
import 'settings/settings.dart';
import 'widgets/glass_navigation_bar.dart';
import 'widgets/glass_design.dart';
import 'widgets/platform.dart';

void main() => runApp(const ProviderScope(child: BadalatyApp()));

class BadalatyApp extends ConsumerStatefulWidget {
  const BadalatyApp({super.key});
  @override
  ConsumerState<BadalatyApp> createState() => _AppState();
}

const _sections = ['/', '/history', '/assignments', '/reports', '/settings'];

class _AppState extends ConsumerState<BadalatyApp> with WidgetsBindingObserver {
  late final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => _Frame(state.uri.path, child),
        routes: [
          for (var i = 0; i < _sections.length; i++)
            GoRoute(
              path: _sections[i],
              pageBuilder: (_, state) => NoTransitionPage(
                key: state.pageKey,
                child: _Section(i, day: state.uri.queryParameters['day']),
              ),
            ),
        ],
      ),
      GoRoute(path: '/add', builder: (_, _) => const AddRecordPage()),
      GoRoute(path: '/allowances/add', builder: (_, _) => const AddEntryPage()),
      for (final status in recordedDayStatuses)
        GoRoute(
          path: '/record/$status',
          builder: (_, _) => DayRecordPage(status),
        ),
      GoRoute(
        path: '/entry/:category',
        builder: (_, state) {
          final category =
              Category.values
                  .where((c) => c.name == state.pathParameters['category'])
                  .firstOrNull ??
              Category.shared;
          final query = state.uri.queryParameters;
          return EntryPage(
            category,
            key: ValueKey(state.pageKey),
            id: int.tryParse(query['id'] ?? ''),
            copy: int.tryParse(query['copy'] ?? ''),
            trip: int.tryParse(query['trip'] ?? ''),
            initialDay: query['day'],
          );
        },
      ),
      GoRoute(
        path: '/assignment/:id',
        builder: (_, state) =>
            AssignmentEditor(int.tryParse(state.pathParameters['id']!)),
      ),
    ],
  );
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
    if (Platform.isAndroid) {
      ref.listenManual(recordsProvider, (_, next) {
        if (next is AsyncData) _publishWidgetsAfterFrame();
      }, fireImmediately: true);
      platformChannel.setMethodCallHandler((call) async {
        if (call.method == 'route' && mounted) {
          _route(call.arguments as String?);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final path = await platformChannel.invokeMethod<String>('initialRoute');
        if (mounted) _route(path);
      });
    }
  }

  void _route(String? path) {
    if (path == '/history' || path == '/') {
      router.go(path!);
    } else if (path == '/entry/travel' || path == '/add') {
      router.go('/');
      router.push(path!);
    }
  }

  void _scheduleMidnight() {
    timer?.cancel();
    final now = DateTime.now();
    timer = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) {
          setState(() {});
          _publishWidgetsAfterFrame();
          _scheduleMidnight();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleMidnight();
      setState(() {});
      _publishWidgetsAfterFrame();
    }
  }

  void _publishWidgetsAfterFrame() {
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final records = ref.read(recordsProvider).value;
      if (records != null) {
        unawaited(
          publishPlatformData(records).catchError((Object _, StackTrace _) {}),
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isAndroid) platformChannel.setMethodCallHandler(null);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordsProvider).value;
    final settings = records?.settings ?? {};
    final language = settings['language'];
    final arabic =
        language == 'ar' ||
        ((language == null || language == 'system') &&
            WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
                'ar');
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      onGenerateTitle: (context) => context.l.title,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      locale: language == 'ar' || language == 'en'
          ? Locale(language as String)
          : null,
      theme: badalatyTheme(Brightness.light, arabic: arabic),
      darkTheme: badalatyTheme(Brightness.dark, arabic: arabic),
      themeMode: switch (settings['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame(this.path, this.child);
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final labels = [l.home, l.history, l.assignments, l.reports, l.settings];
    const icons = [
      Icons.home_outlined,
      Icons.calendar_month_outlined,
      Icons.route_outlined,
      Icons.bar_chart_outlined,
      Icons.settings_outlined,
    ];
    final current = _sections.indexOf(path);
    return GlassScaffold(
      appBar: AppBar(
        title: current == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel(context, dayKey(DateTime.now())),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(l.title),
                ],
              )
            : Text(labels[current]),
        actions: [
          if (current == 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Image.asset(
                'assets/branding/badalaty-icon.png',
                width: 41,
                height: 41,
                cacheWidth: 123,
                excludeFromSemantics: true,
              ),
            ),
        ],
      ),
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: current,
        onSelected: (index) {
          if (index != current) context.go(_sections[index]);
        },
        destinations: [
          for (var i = 0; i < labels.length; i++)
            (icon: icons[i], label: labels[i]),
        ],
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section(this.index, {this.day});
  final int index;
  final String? day;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(recordsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(recordsProvider),
            child: Text(context.l.error),
          ),
        ),
        data: (records) => switch (index) {
          0 => HomePage(records),
          1 => HistoryPage(records, key: ValueKey(day), initialDay: day),
          2 => AssignmentsPage(records),
          3 => ReportsPage(records),
          _ => SettingsPage(records),
        },
      );
}
