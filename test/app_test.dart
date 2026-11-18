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
  testWidgets('switches direction and saves travel through the Arabic form', (
    tester,
  ) async {
    final db = Store(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.save('settings', {'language': 'system'});
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
      () => db.save('settings', {'language': 'ar'}, id: id),
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
      final id = await db.save('settings', {'language': 'en'});
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
        () => db.save('settings', {'language': 'ar', 'theme': 'dark'}, id: id),
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
}
