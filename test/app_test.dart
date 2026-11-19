import 'package:badalaty/data/state.dart';
import 'package:badalaty/data/store.dart';
import 'package:badalaty/main.dart';
import 'package:badalaty/records/add_record.dart';
import 'package:badalaty/history/history.dart';
import 'package:badalaty/widgets/glass_navigation_bar.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'completes setup with a name and saves a shared allowance without an ID',
    (tester) async {
      final db = Store(NativeDatabase.memory());
      addTearDown(db.close);
      await db.save('client', {'name': 'شركة أ'});
      final state = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(db)],
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: state, child: const BadalatyApp()),
      );
      await tester.runAsync(() => state.read(recordsProvider.future));
      await tester.pumpAndSettle();

      final begin = find.widgetWithText(FilledButton, 'Get started');
      expect(tester.widget<FilledButton>(begin).onPressed, isNull);
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('أهلًا بيك في بدلاتي'), findsOneWidget);
      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();

      final name = find.byType(TextField).first;
      await tester.enterText(name, '  أحمد  ');
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'ابدأ استخدام بدلاتي'),
      );
      await tester.pumpAndSettle();
      expect(find.text('بدلاتي'), findsOneWidget);
      final settings = (await db.readAll()).settings;
      expect(settings['name'], 'أحمد');
      expect(settings['code'], isNull);
      expect(settings['language'], 'ar');
      expect(settings['theme'], 'dark');

      await tester.tap(find.widgetWithText(FilledButton, 'إضافة سجل'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'بدل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بدل الانتقال'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العميل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شركة أ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'حفظ');
      await tester.scrollUntilVisible(
        save,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save.hitTestable());
      await tester.pumpAndSettle();
      final entry = (await db.readAll()).entries.single;
      final owner = (entry['people'] as List).first as Record;
      expect(owner['name'], 'أحمد');
      expect(owner['code'], isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('saves clients and colleagues by name in settings', (
    tester,
  ) async {
    final db = Store(NativeDatabase.memory());
    addTearDown(db.close);
    await db.save('settings', {'language': 'ar', 'name': 'Owner'});
    await db.save('team', {'name': 'فريق قديم', 'members': []});
    final container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BadalatyApp(),
      ),
    );
    await tester.runAsync(() => container.read(recordsProvider.future));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(GlassNavigationBar),
        matching: find.text('الإعدادات'),
      ),
    );
    await tester.pumpAndSettle();
    final directory = find.widgetWithText(ListTile, 'العملاء والزملاء');
    await tester.scrollUntilVisible(directory, 120);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(directory.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    for (final (kind, label, name) in [
      ('client', 'العملاء', 'عميل جديد'),
      ('employee', 'الزملاء', 'زميل جديد'),
    ]) {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'إضافة'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(kind == 'employee' ? 2 : 1));
      await tester.enterText(find.byType(TextField).first, name);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
        final record = (await db.readAll()).ofKind(kind).single;
        expect(record['name'], name);
        expect(record['code'], isNull);
      });
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switches direction and saves travel through the Arabic form', (
    tester,
  ) async {
    final db = Store(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.save('settings', {
      'language': 'system',
      'name': 'Owner',
    });
    tester.binding.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await db.save('client', {'name': 'شركة أ'});
    final container = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BadalatyApp(),
      ),
    );
    await tester.runAsync(() => container.read(recordsProvider.future));
    await tester.pumpAndSettle();
    expect(find.text('Badalaty'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Badalaty'))),
      TextDirection.ltr,
    );
    await tester.runAsync(
      () => db.save('settings', {'language': 'ar', 'name': 'Owner'}, id: id),
    );
    container.invalidate(recordsProvider);
    await tester.runAsync(() => container.read(recordsProvider.future));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.text('بدلاتي'))),
      TextDirection.rtl,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة سجل'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'إجازة'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'مكتب'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'مكتب'));
    await tester.pumpAndSettle();
    expect(find.text('قيمة السجل'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ السجل'));
    await tester.pumpAndSettle();
    final dayRecord = find.byType(DayRecordTile);
    await tester.scrollUntilVisible(
      dayRecord,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: dayRecord, matching: find.text('مكتب')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(GlassNavigationBar),
        matching: find.text('الرئيسية'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة سجل'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'بدل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدل السفر'));
    await tester.pumpAndSettle();
    expect(find.text('الوجبات'), findsOneWidget);
    expect(find.text('المبيت'), findsOneWidget);
    expect(find.text('الزملاء'), findsNothing);
    await tester.tap(find.text('العميل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شركة أ'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'حفظ');
    await tester.scrollUntilVisible(
      save,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(AddRecordPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('بدلاتي'), findsOneWidget);
    final entries = (await db.readAll()).entries;
    expect(entries.single['owner'], 149);
    expect(entries.single['clientName'], 'شركة أ');

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'floating tabs follow locale and leave the last setting reachable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final db = Store(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.save('settings', {'language': 'en', 'name': 'Owner'});
      final container = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BadalatyApp(),
        ),
      );
      await tester.runAsync(() => container.read(recordsProvider.future));
      await tester.pumpAndSettle();

      final bar = find.byType(GlassNavigationBar);
      Finder tab(String title) =>
          find.descendant(of: bar, matching: find.text(title));
      expect(
        tester.getCenter(tab('Home')).dx,
        lessThan(tester.getCenter(tab('Settings')).dx),
      );
      expect(tester.widget<GlassNavigationBar>(bar).selectedIndex, 0);
      Rect target(String label) => tester.getRect(
        find.descendant(of: bar, matching: find.widgetWithText(InkWell, label)),
      );
      expect(target('Home').width, greaterThanOrEqualTo(48));
      expect(target('History').left - target('Home').right, closeTo(4, 0.01));

      await tester.runAsync(
        () => db.save('settings', {
          'language': 'ar',
          'theme': 'dark',
          'name': 'Owner',
        }, id: id),
      );
      container.invalidate(recordsProvider);
      await tester.runAsync(() => container.read(recordsProvider.future));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(tab('الرئيسية')).dx,
        greaterThan(tester.getCenter(tab('الإعدادات')).dx),
      );

      for (final (index, label) in [
        (1, 'السجلات'),
        (2, 'المأموريات'),
        (3, 'التقارير'),
      ]) {
        await tester.tap(tab(label));
        await tester.pump();
        if (index == 1) {
          final route = ModalRoute.of(
            tester.element(find.byType(HistoryPage)),
          )!;
          expect(route.transitionDuration, Duration.zero);
          expect(route.reverseTransitionDuration, Duration.zero);
        }
        await tester.pumpAndSettle();
        expect(tester.widget<GlassNavigationBar>(bar).selectedIndex, index);
        expect(find.widgetWithText(AppBar, label), findsOneWidget);
        if (index == 3) {
          for (final filter in ['كل العملاء', 'كل المأموريات', 'كل الأنواع']) {
            expect(find.text(filter), findsOneWidget);
          }
          await tester.tap(find.text('كل الأنواع'));
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(PopupMenuItem<String>, 'بدل السفر'),
            findsOneWidget,
          );
          await tester.tap(
            find.widgetWithText(PopupMenuItem<String>, 'بدل السفر'),
          );
          await tester.pumpAndSettle();
          expect(find.text('كل الأنواع'), findsNothing);
        }
      }
      await tester.tap(tab('الإعدادات'));
      await tester.pumpAndSettle();
      expect(tester.widget<GlassNavigationBar>(bar).selectedIndex, 4);
      expect(find.widgetWithText(AppBar, 'الإعدادات'), findsOneWidget);

      final backups = find.widgetWithText(ListTile, 'النسخ الاحتياطي');
      await tester.scrollUntilVisible(backups, 180);
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      final glass = find.descendant(of: bar, matching: find.byType(ClipRRect));
      expect(
        tester.getBottomLeft(backups).dy,
        lessThan(tester.getTopLeft(glass).dy),
      );
      await tester.tap(backups);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, 'استعادة نسخة احتياطية'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final (locale, choose, allowance, history, settings, rtl) in [
    ('en', 'Add entry', 'Allowance', 'History', 'Settings', false),
    ('ar', 'إضافة سجل', 'بدل', 'السجلات', 'الإعدادات', true),
  ]) {
    testWidgets(
      'navigation arrows render in the correct direction in $locale',
      (tester) async {
        final db = Store(NativeDatabase.memory());
        addTearDown(db.close);
        await db.save('settings', {'language': locale, 'name': 'Owner'});
        final state = ProviderContainer(
          overrides: [storeProvider.overrideWithValue(db)],
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: state,
            child: const BadalatyApp(),
          ),
        );
        await tester.runAsync(() => state.read(recordsProvider.future));
        await tester.pumpAndSettle();

        void expectDirection(Finder icons, int count) {
          expect(icons, findsNWidgets(count));
          final mirrors = find.descendant(
            of: icons,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Transform && widget.transform.entry(0, 0) == -1,
            ),
          );
          expect(mirrors, findsNWidgets(rtl ? count : 0));
        }

        await tester.tap(find.widgetWithText(FilledButton, choose));
        await tester.pumpAndSettle();
        expectDirection(find.byIcon(Icons.chevron_right), 3);
        expectDirection(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.arrow_back),
          ),
          1,
        );
        await tester.tap(find.widgetWithText(ListTile, allowance));
        await tester.pumpAndSettle();
        expectDirection(find.byIcon(Icons.chevron_right), 3);

        for (var i = 0; i < 2; i++) {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        Finder tab(String text) => find.descendant(
          of: find.byType(GlassNavigationBar),
          matching: find.text(text),
        );
        await tester.tap(tab(history));
        await tester.pumpAndSettle();
        final previous = find.byIcon(Icons.arrow_back);
        final next = find.byIcon(Icons.arrow_forward);
        expectDirection(previous, 1);
        expectDirection(next, 1);
        expect(tester.getCenter(previous).dx > tester.getCenter(next).dx, rtl);

        await tester.tap(tab(settings));
        await tester.pumpAndSettle();
        final disclosures = find.byIcon(Icons.chevron_right);
        await tester.scrollUntilVisible(disclosures.first, 120);
        expectDirection(disclosures.first, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
