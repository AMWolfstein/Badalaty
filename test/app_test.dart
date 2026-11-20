import 'dart:async';

import 'package:badalaty/forms.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:badalaty/widgets/glass_design.dart';
import 'package:badalaty/data/state.dart';
import 'package:badalaty/data/store.dart';
import 'package:badalaty/main.dart';
import 'package:badalaty/records/add_record.dart';
import 'package:badalaty/history/history.dart';
import 'package:badalaty/updates/github_updates.dart';
import 'package:badalaty/updates/update_dialog.dart';
import 'package:badalaty/widgets/glass_navigation_bar.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final outcome in ['available', 'up to date', 'offline']) {
    testWidgets('startup update check is silent until ready ($outcome)', (
      tester,
    ) async {
      final db = Store(NativeDatabase.memory());
      addTearDown(db.close);
      await db.save('settings', {'name': 'Owner', 'language': 'ar'});
      final checked = Completer<UpdateCheck>();
      var calls = 0;
      final state = ProviderContainer(
        overrides: [
          storeProvider.overrideWithValue(db),
          startupUpdateCheckProvider.overrideWithValue(() {
            calls++;
            return checked.future;
          }),
        ],
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: state, child: const BadalatyApp()),
      );
      await tester.runAsync(() => state.read(recordsProvider.future));
      await tester.pumpAndSettle();

      final dialog = find.byType(UpdateDialog);
      expect(calls, 1);
      expect(dialog, findsNothing);
      expect(find.byType(GlassNavigationBar), findsOneWidget);

      if (outcome == 'offline') {
        checked.completeError(StateError('Offline'));
      } else {
        checked.complete((
          installed: '1.0.18',
          supported: true,
          release: outcome == 'available'
              ? GithubRelease.fromJson({
                  'package': 'com.amwolfstein.badalaty',
                  'version': '1.0.19',
                  'build': 20,
                  'sha256': 'a' * 64,
                })
              : null,
        ));
      }
      await tester.pumpAndSettle();

      if (outcome == 'available') {
        expect(dialog, findsOneWidget);
        expect(find.text('الإصدار 1.0.19 متاح'), findsOneWidget);
        expect(find.text('تنزيل وتثبيت'), findsOneWidget);
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();
      }
      expect(dialog, findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavigationBar),
          matching: find.bySemanticsLabel('التقارير'),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(dialog, findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('switches iOS 27 glass directly between Premium and Standard', (
    tester,
  ) async {
    final db = Store(NativeDatabase.memory());
    addTearDown(db.close);
    await db.save('settings', {'name': 'Owner', 'language': 'ar'});
    final state = ProviderContainer(
      overrides: [storeProvider.overrideWithValue(db)],
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: state, child: const BadalatyApp()),
    );
    await tester.runAsync(() => state.read(recordsProvider.future));
    await tester.pumpAndSettle();

    final bar = find.byType(GlassNavigationBar);
    void expectQuality(liquid.GlassQuality quality) {
      final glass = liquid.GlassTheme.of(tester.element(bar)).data;
      expect(glass.style, liquid.GlassStyle.ios27);
      expect(glass.light.quality, quality);
      expect(glass.dark.quality, quality);
      expect(find.byType(liquid.GlassAdaptiveScope), findsNothing);
      final premium = quality == liquid.GlassQuality.premium;
      final tabs = tester.widget<liquid.GlassTabBar>(
        find.descendant(of: bar, matching: find.byType(liquid.GlassTabBar)),
      );
      expect(tabs.settings != null, premium);
      expect(tabs.indicatorSettings != null, premium);
    }

    expectQuality(liquid.GlassQuality.premium);

    await tester.tap(
      find.descendant(of: bar, matching: find.bySemanticsLabel('الإعدادات')),
    );
    await tester.pumpAndSettle();
    final toggle = find.descendant(
      of: find.widgetWithText(GlassToggleRow, 'جودة الزجاج Premium'),
      matching: find.byType(liquid.GlassSwitch),
    );
    await tester.scrollUntilVisible(toggle, 120);
    await Scrollable.ensureVisible(tester.element(toggle), alignment: .4);
    await tester.pumpAndSettle();
    final tabBarElement = tester.element(bar);
    expect(tester.widget<liquid.GlassSwitch>(toggle).value, isTrue);

    for (final expected in [false, true, false]) {
      await tester.tap(toggle.hitTestable());
      await tester.pumpAndSettle();
      expect((await db.readAll()).settings['premiumGlass'], expected);
      final glassSwitch = tester.widget<liquid.GlassSwitch>(toggle);
      expect(glassSwitch.value, expected);
      expect(glassSwitch.settings != null, expected);
      expectQuality(
        expected ? liquid.GlassQuality.premium : liquid.GlassQuality.standard,
      );
      expect(tester.element(bar), same(tabBarElement));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'history wraps filters and separates the search controls in narrow RTL',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 690);
      addTearDown(tester.view.reset);
      final db = Store(NativeDatabase.memory());
      addTearDown(db.close);
      await db.save('settings', {
        'name': 'Owner',
        'language': 'ar',
        'theme': 'dark',
      });
      final state = ProviderContainer(
        overrides: [storeProvider.overrideWithValue(db)],
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: state, child: const BadalatyApp()),
      );
      await tester.runAsync(() => state.read(recordsProvider.future));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavigationBar),
          matching: find.bySemanticsLabel('السجلات'),
        ),
      );
      await tester.pumpAndSettle();

      final searchBar = find.byType(liquid.GlassSearchBar);
      await tester.scrollUntilVisible(
        searchBar,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(searchBar), alignment: .45);
      await tester.pumpAndSettle();

      final chips = find.byType(GlassFilterChip);
      expect(chips, findsNWidgets(6));
      final bounds = [for (var i = 0; i < 6; i++) tester.getRect(chips.at(i))];
      expect(bounds.map((rect) => rect.top).toSet().length, greaterThan(1));
      expect(bounds.first.left, greaterThan(bounds[1].left));
      for (final rect in bounds) {
        expect(rect.left, greaterThanOrEqualTo(glassPageInset));
        expect(rect.right, lessThanOrEqualTo(320 - glassPageInset));
        expect(
          tester.getTopLeft(searchBar).dy - rect.bottom,
          greaterThanOrEqualTo(glassItemGap),
        );
      }

      final rides = find.widgetWithText(GlassFilterChip, 'الانتقالات الداخلية');
      await tester.tap(rides.hitTestable());
      await tester.pumpAndSettle();
      expect(tester.widget<GlassFilterChip>(rides).selected, isTrue);
      final filterButton = find.byTooltip('تصفية السجلات');
      expect(
        tester.getTopLeft(searchBar).dx - tester.getTopRight(filterButton).dx,
        10,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is Choice),
        findsNothing,
      );
      await tester.tap(filterButton.hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((widget) => widget is Choice),
        findsNWidgets(3),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final (
        locale,
        appearance,
        settingsLabel,
        ratesLabel,
        mealsLabel,
        saveLabel,
      )
      in [
        (
          'ar',
          'dark',
          'الإعدادات',
          'أسعار بدل السفر الافتراضية',
          'الوجبات',
          'حفظ',
        ),
        ('en', 'light', 'Settings', 'Default travel rates', 'Meals', 'Save'),
      ]) {
    testWidgets(
      'saves travel rates above the keyboard without tab chrome in $locale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
        addTearDown(tester.view.reset);
        final db = Store(NativeDatabase.memory());
        addTearDown(db.close);
        await db.save('settings', {
          'name': 'Owner',
          'language': locale,
          'theme': appearance,
        });
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
        final bar = find.byType(GlassNavigationBar);
        await tester.tap(
          find.descendant(
            of: bar,
            matching: find.bySemanticsLabel(settingsLabel),
          ),
        );
        await tester.pumpAndSettle();

        final rates = find.widgetWithText(GlassRow, ratesLabel);
        await tester.scrollUntilVisible(rates, 130);
        await Scrollable.ensureVisible(tester.element(rates), alignment: .45);
        await tester.pumpAndSettle();
        await tester.tap(rates.hitTestable());
        await tester.pumpAndSettle();
        expect(bar, findsNothing);
        expect(find.byType(GlassHeader), findsOneWidget);
        expect(find.text(mealsLabel), findsOneWidget);

        final scheme = Theme.of(tester.element(find.text(mealsLabel)))
            .colorScheme;
        expect(
          scheme.brightness,
          appearance == 'dark' ? Brightness.dark : Brightness.light,
        );
        final fieldSurfaces = find.byWidgetPredicate(
          (widget) =>
              widget is liquid.GlassContainer &&
              widget.color == scheme.surfaceContainer,
        );
        expect(fieldSurfaces, findsNWidgets(3));

        await tester.enterText(find.byType(EditableText).first, '125');
        tester.view.viewInsets = const FakeViewPadding(bottom: 235);
        tester.view.padding = const FakeViewPadding(top: 24);
        await tester.pumpAndSettle();
        expect(find.text(mealsLabel), findsOneWidget);
        final save = find.widgetWithText(GlassAction, saveLabel);
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(640 - 235));
        await tester.tap(save);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect((await db.readAll()).settings['mealRate'], 125);
        expect(bar, findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

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

      final begin = find.widgetWithText(GlassAction, 'Get started');
      expect(tester.widget<GlassAction>(begin).onPressed, isNull);
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();
      expect(find.text('أهلًا بيك في بدلاتي'), findsOneWidget);
      await tester.tap(find.text('المظهر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();

      final name = find.byType(EditableText).first;
      await tester.enterText(name, '  أحمد  ');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassAction, 'ابدأ استخدام بدلاتي'));
      await tester.pumpAndSettle();
      expect(find.text('بدلاتي'), findsOneWidget);
      final settings = (await db.readAll()).settings;
      expect(settings['name'], 'أحمد');
      expect(settings['code'], isNull);
      expect(settings['language'], 'ar');
      expect(settings['theme'], 'dark');

      await tester.tap(find.widgetWithText(GlassAction, 'إضافة سجل'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassRow, 'بدل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بدل الانتقال'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DayField));
      await tester.pumpAndSettle();
      expect(find.byType(liquid.GlassDatePicker), findsOneWidget);
      final ok = MaterialLocalizations.of(tester.element(find.byType(DayField)))
          .okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(find.byType(liquid.GlassDatePicker), findsNothing);
      await tester.tap(find.text('العميل'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شركة أ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), '100');
      await tester.pumpAndSettle();
      final save = find.widgetWithText(GlassAction, 'حفظ');
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
        matching: find.bySemanticsLabel('الإعدادات'),
      ),
    );
    await tester.pumpAndSettle();
    final directory = find.widgetWithText(GlassRow, 'العملاء والزملاء');
    await tester.scrollUntilVisible(directory, 120);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(directory.hitTestable());
    await tester.pumpAndSettle();

    expect(find.byType(GlassFilterChip), findsNWidgets(2));
    for (final (kind, label, name) in [
      ('client', 'العملاء', 'عميل جديد'),
      ('employee', 'الزملاء', 'زميل جديد'),
    ]) {
      await tester.tap(find.widgetWithText(GlassFilterChip, label));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(GlassAction, 'إضافة'));
      await tester.pumpAndSettle();
      expect(
        find.byType(EditableText),
        findsNWidgets(kind == 'employee' ? 2 : 1),
      );
      await tester.enterText(find.byType(EditableText).first, name);
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(GlassAction, 'حفظ'));
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
    await tester.tap(find.widgetWithText(GlassAction, 'إضافة سجل'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(GlassRow, 'إجازة'), findsOneWidget);
    expect(find.widgetWithText(GlassRow, 'مكتب'), findsOneWidget);
    await tester.tap(find.widgetWithText(GlassRow, 'مكتب'));
    await tester.pumpAndSettle();
    expect(find.text('قيمة السجل'), findsOneWidget);
    await tester.tap(find.widgetWithText(GlassAction, 'حفظ السجل'));
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
        matching: find.bySemanticsLabel('الرئيسية'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GlassAction, 'إضافة سجل'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(GlassRow, 'بدل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدل السفر'));
    await tester.pumpAndSettle();
    final meals = find.descendant(
      of: find.widgetWithText(GlassToggleRow, 'الوجبات'),
      matching: find.byType(liquid.GlassSwitch),
    );
    expect(tester.widget<liquid.GlassSwitch>(meals).value, isTrue);
    await tester.tap(meals);
    await tester.pumpAndSettle();
    expect(tester.widget<liquid.GlassSwitch>(meals).value, isFalse);
    await tester.tap(meals);
    await tester.pumpAndSettle();
    expect(find.text('الوجبات'), findsOneWidget);
    expect(find.text('المبيت'), findsOneWidget);
    expect(find.text('الزملاء'), findsNothing);
    await tester.tap(find.text('العميل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شركة أ'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(GlassAction, 'حفظ');
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
          find.descendant(of: bar, matching: find.bySemanticsLabel(title));
      expect(
        tester.getCenter(tab('Home')).dx,
        lessThan(tester.getCenter(tab('Settings')).dx),
      );
      expect(tester.widget<GlassNavigationBar>(bar).selectedIndex, 0);
      expect(
        find.descendant(of: bar, matching: find.byType(liquid.GlassTabBar)),
        findsOneWidget,
      );
      expect(
        tester.getCenter(tab('History')).dx - tester.getCenter(tab('Home')).dx,
        greaterThanOrEqualTo(48),
      );

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
        expect(find.widgetWithText(GlassHeader, label), findsOneWidget);
        if (index == 3) {
          final startDate = find.widgetWithText(DayField, 'تاريخ البداية');
          final endDate = find.widgetWithText(DayField, 'تاريخ النهاية');
          expect(startDate, findsOneWidget);
          expect(endDate, findsOneWidget);
          expect(tester.getRect(startDate).top, tester.getRect(endDate).top);
          expect(
            tester.getRect(startDate).height,
            tester.getRect(endDate).height,
          );
          expect(
            tester.getTopLeft(startDate).dx - tester.getTopRight(endDate).dx,
            10,
          );
          for (final field in [startDate, endDate]) {
            expect(
              find.descendant(
                of: field,
                matching: find.byType(liquid.GlassContainer),
              ),
              findsOneWidget,
            );
          }
          await tester.tap(startDate);
          await tester.pumpAndSettle();
          expect(find.byType(liquid.GlassDatePicker), findsOneWidget);
          await tester.tap(find.text('إلغاء'));
          await tester.pumpAndSettle();

          for (final filter in ['كل العملاء', 'كل المأموريات', 'الكل']) {
            expect(find.text(filter), findsOneWidget);
          }
          await tester.tap(find.text('الكل'));
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(liquid.GlassMenuItem, 'بدل السفر'),
            findsOneWidget,
          );
          await tester.tap(
            find.widgetWithText(liquid.GlassMenuItem, 'بدل السفر'),
          );
          await tester.pumpAndSettle();
          expect(find.text('الكل'), findsNothing);
        }
      }
      await tester.tap(tab('الإعدادات'));
      await tester.pumpAndSettle();
      expect(tester.widget<GlassNavigationBar>(bar).selectedIndex, 4);
      expect(find.widgetWithText(GlassHeader, 'الإعدادات'), findsOneWidget);

      final backups = find.widgetWithText(GlassRow, 'النسخ الاحتياطي');
      await tester.scrollUntilVisible(backups, 180);
      await tester.drag(find.byType(ListView), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(backups.hitTestable(), findsOneWidget);
      await tester.tap(backups);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(GlassRow, 'استعادة نسخة احتياطية'),
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

        final recordPicker = find.byType(AddRecordPage);
        await tester.tap(find.widgetWithText(GlassAction, choose));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final openingX = tester.getTopLeft(recordPicker).dx;
        expect(rtl ? openingX < 0 : openingX > 0, isTrue);
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(recordPicker).dx, closeTo(0, .01));
        expectDirection(find.byIcon(Icons.chevron_right), 3);
        expectDirection(
          find.descendant(
            of: find.byType(GlassHeader),
            matching: find.byIcon(Icons.arrow_back),
          ),
          1,
        );
        await tester.tap(find.widgetWithText(GlassRow, allowance));
        await tester.pumpAndSettle();
        expectDirection(find.byIcon(Icons.chevron_right), 3);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final closingX = tester.getTopLeft(recordPicker).dx;
        expect(rtl ? closingX < 0 : closingX > 0, isTrue);
        await tester.pumpAndSettle();
        expect(recordPicker, findsNothing);
        Finder tab(String text) => find.descendant(
          of: find.byType(GlassNavigationBar),
          matching: find.bySemanticsLabel(text),
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
