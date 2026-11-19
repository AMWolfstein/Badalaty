import 'dart:async';
import 'dart:io';

// The glass package still uses the SDK Cupertino widgets and delegates.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart'
    as sdk_cupertino
    show CupertinoTheme, CupertinoThemeData, CupertinoTextThemeData;
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;

import 'allowances/calculation.dart';
import 'allowances/entry.dart';
import 'assignments/assignments.dart';
import 'data/state.dart';
import 'data/store.dart';
import 'forms.dart';
import 'history/history.dart';
import 'home/home.dart';
import 'l10n/app_localizations.dart';
import 'l10n/labels.dart';
import 'reports/reports.dart';
import 'records/add_record.dart';
import 'settings/settings.dart';
import 'settings/setup.dart';
import 'widgets/glass_navigation_bar.dart';
import 'widgets/glass_design.dart';
import 'widgets/platform.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await liquid.LiquidGlassWidgets.initialize(
    warmUpMode: Platform.isAndroid
        ? liquid.GlassWarmUpMode.never
        : liquid.GlassWarmUpMode.auto,
  );
  runApp(const ProviderScope(child: BadalatyApp()));
}

class BadalatyApp extends ConsumerStatefulWidget {
  const BadalatyApp({super.key});
  @override
  ConsumerState<BadalatyApp> createState() => _AppState();
}

const _sections = ['/', '/history', '/assignments', '/reports', '/settings'];

class _AppState extends ConsumerState<BadalatyApp> with WidgetsBindingObserver {
  String? setupLanguage;
  String? setupTheme;
  String? pendingWidgetRoute;
  bool? setupRequired;
  bool widgetPublishScheduled = false;
  final themes = <bool, (ThemeData, ThemeData)>{};

  bool needsSetup(List<Record> records) =>
      ((records.settings['name'] as String?) ?? '').trim().isEmpty;

  late final router = GoRouter(
    redirect: (_, state) {
      final records = ref.read(recordsProvider).value;
      if (records == null) return null;
      final onSetup = state.uri.path == '/setup';
      if (needsSetup(records)) {
        return onSetup
            ? null
            : Uri(
                path: '/setup',
                queryParameters: {'next': state.uri.toString()},
              ).toString();
      }
      if (!onSetup) return null;
      final next = Uri.tryParse(state.uri.queryParameters['next'] ?? '');
      return next != null &&
              !next.hasScheme &&
              !next.hasAuthority &&
              next.path.startsWith('/') &&
              next.path != '/setup'
          ? next.toString()
          : '/';
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (_, _) {
          final settings = ref.read(recordsProvider).value?.settings ?? {};
          return SetupPage(
            language:
                setupLanguage ?? settings['language'] as String? ?? 'system',
            theme: setupTheme ?? settings['theme'] as String? ?? 'system',
            onLanguageChanged: (value) => setState(() => setupLanguage = value),
            onThemeChanged: (value) => setState(() => setupTheme = value),
          );
        },
      ),
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
    final initialRecords = ref.read(recordsProvider).value;
    setupRequired = initialRecords == null ? null : needsSetup(initialRecords);
    ref.listenManual(recordsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        final required = needsSetup(value);
        if (setupRequired != required) {
          setupRequired = required;
          router.refresh();
        }
        if (!required) {
          setupLanguage = null;
          setupTheme = null;
          final path = pendingWidgetRoute;
          pendingWidgetRoute = null;
          if (path != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _route(path);
            });
          }
        }
        _publishWidgetsAfterFrame();
      }
    });
    if (Platform.isAndroid) {
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
    if (path == null) return;
    final records = ref.read(recordsProvider).value;
    if (records == null || needsSetup(records)) {
      pendingWidgetRoute = path;
      return;
    }
    if (path == '/history' || path == '/') {
      router.go(path);
    } else if (path == '/entry/travel' || path == '/add') {
      router.go('/');
      router.push(path);
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

  @override
  void didChangePlatformBrightness() => _publishWidgetsAfterFrame();

  void _publishWidgetsAfterFrame() {
    if (!Platform.isAndroid || widgetPublishScheduled) return;
    widgetPublishScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widgetPublishScheduled = false;
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
    final (inSetup, storedLanguage, storedTheme) = ref.watch(
      recordsProvider.select((data) {
        final records = data.value;
        final settings = records?.settings;
        return (
          records != null && needsSetup(records),
          settings?['language'],
          settings?['theme'],
        );
      }),
    );
    final language = (inSetup ? setupLanguage : null) ?? storedLanguage;
    final theme = (inSetup ? setupTheme : null) ?? storedTheme;
    final arabic =
        language == 'ar' ||
        ((language == null || language == 'system') &&
            WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
                'ar');
    final (lightTheme, darkTheme) = themes.putIfAbsent(
      arabic,
      () => (
        badalatyTheme(Brightness.light, arabic: arabic),
        badalatyTheme(Brightness.dark, arabic: arabic),
      ),
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        final theme = Theme.of(context);
        return sdk_cupertino.CupertinoTheme(
          data: sdk_cupertino.CupertinoThemeData(
            brightness: theme.brightness,
            primaryColor: theme.colorScheme.primary,
            textTheme: sdk_cupertino.CupertinoTextThemeData(
              textStyle: theme.textTheme.bodyLarge,
            ),
          ),
          child: liquid.LiquidGlassWidgets.wrap(
            brightnessResolver: Theme.maybeBrightnessOf,
            theme: const liquid.GlassThemeData.ios26(),
            adaptiveQuality: true,
            adaptiveConfig: Platform.isAndroid
                ? const liquid.GlassAdaptiveScopeConfig(
                    maxQuality: liquid.GlassQuality.standard,
                  )
                : null,
            respectSystemAccessibility: true,
            child: child!,
          ),
        );
      },
      onGenerateTitle: (context) => context.l.title,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // ignore: deprecated_member_use
        sdk_localizations.GlobalCupertinoLocalizations.delegate,
        sdk_localizations.GlobalWidgetsLocalizations.delegate,
      ],
      locale: language == 'ar' || language == 'en'
          ? Locale(language as String)
          : null,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: switch (theme) {
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
      appBar: GlassHeader(
        title: current == 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel(context, dayKey(DateTime.now())),
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    l.title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 21, height: 1.15),
                  ),
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
      body: SafeArea(top: false, bottom: false, child: child),
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
          child: GlassSecondaryAction(
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
