import 'package:badalaty/data/state.dart';
import 'package:badalaty/data/store.dart';
import 'package:badalaty/main.dart';
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
    final id = await db.save('settings', {'language': 'en'});
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
    expect(find.text('بدلاتي'), findsOneWidget);
    final entries = (await db.readAll()).entries;
    expect(entries.single['owner'], 149);
    expect(entries.single['clientName'], 'شركة أ');

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
