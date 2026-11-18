import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:badalaty/data/state.dart';
import 'package:badalaty/data/store.dart';
import 'package:badalaty/l10n/app_localizations_ar.dart';
import 'package:badalaty/l10n/app_localizations_en.dart';
import 'package:badalaty/reports/workbook.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Store store;

  setUp(() => store = Store(NativeDatabase.memory()));
  tearDown(() => store.close());

  test('office and leave share one day status and export as zero', () async {
    const day = '2026-11-18';
    final initialId = await store.save('day', {'day': day, 'status': 'office'});
    expect((await store.readAll()).recordedDays.single['status'], 'office');
    final updatedId = await store.save('day', {'day': day, 'status': 'leave'});
    expect(updatedId, initialId);
    final records = await store.readAll();
    expect(records.recordedDays.single['status'], 'leave');
    expect(records.entries, isEmpty);
    final archive = ZipDecoder().decodeBytes(
      workbook(
        [],
        AppLocalizationsEn(),
        'November',
        dayRecords: records.recordedDays.toList(),
      ),
    );
    final daily = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content,
    );
    expect(daily, contains('Leave'));
    expect(daily, contains('<c r="I3"><v>0</v></c>'));
    expect(daily, contains('<c r="J3"><v>0</v></c>'));
  });

  test(
    'records a seven-day assignment and reconciles each allowance type',
    () async {
      final client = await store.save('client', {'name': 'Company A'});
      final clientB = await store.save('client', {'name': 'Company B'});
      final employee = await store.save('employee', {
        'name': 'Colleague',
        'code': '0007',
      });
      final assignment = await store.save('assignment', {
        'name': 'Hurghada',
        'client': client,
        'start': '2026-11-01',
        'end': '2026-11-07',
        'status': 'active',
      });
      expect((await store.readAll()).entries, isEmpty);
      expect((await store.readAll()).activeOn('2026-11-07')?['id'], assignment);
      expect((await store.readAll()).activeOn('2026-11-08'), isNull);
      final common = {
        'day': '2026-11-01',
        'client': client,
        'clientName': 'Company A',
        'assignment': assignment,
        'assignmentName': 'Hurghada',
        'location': 'Hurghada',
      };
      final shared = {
        ...common,
        'category': 'shared',
        'base': 100,
        'people': [
          {'id': 0, 'name': 'Owner', 'code': '0012'},
          {'id': employee, 'name': 'Colleague', 'code': '0007'},
        ],
      };
      final entry = await store.save('entry', shared);
      for (var day = 1; day <= 7; day++) {
        await store.save('entry', {
          ...common,
          'day': '2026-11-0$day',
          'category': 'travel',
          'mealRate': 100,
          'lodgingRate': 70,
          'basisPoints': 7000,
          'hasMeals': true,
          'hasLodging': true,
        });
      }
      for (final amount in [42, 8]) {
        await store.save('entry', {
          ...common,
          'client': clientB,
          'clientName': 'Company B',
          'assignment': null,
          'assignmentName': null,
          'category': 'ride',
          'provider': 'Uber',
          'base': amount,
        });
      }
      await store.save('employee', {
        'name': 'Edited',
        'code': '9',
        'archived': true,
      }, id: employee);
      await store.save('settings', {
        'mealRate': 500,
        'lodgingRate': 500,
        'basisPoints': 10000,
      });
      final records = await store.readAll();
      expect(records.entries.length, 10);
      expect(ownerTotal(records.entries), 1143);
      expect(
        ownerTotal(records.entries.where((r) => r['day'] == '2026-11-01')),
        249,
      );
      expect(records.byId(entry)?['shares'], [50, 50]);

      for (final locale in [AppLocalizationsEn(), AppLocalizationsAr()]) {
        final zip = ZipDecoder().decodeBytes(
          workbook(records.entries.toList(), locale, '2026-11'),
        );
        expect(
          zip.files.where((f) => f.name.startsWith('xl/worksheets/')).length,
          6,
        );
        final distribution = utf8.decode(
          zip.findFile('xl/worksheets/sheet2.xml')!.content,
        );
        expect(distribution, contains(locale.employeeId));
        expect(distribution, contains('<t xml:space="preserve">0007</t>'));
        expect(distribution, contains('Colleague'));
        expect(
          distribution,
          contains('rightToLeft="${locale.localeName == 'ar' ? 1 : 0}"'),
        );
        final summary = utf8.decode(
          zip.findFile('xl/worksheets/sheet6.xml')!.content,
        );
        expect(summary, contains('<c r="H3"><v>1143</v></c>'));
        expect(summary, contains('<c r="D3"><v>100</v></c>'));
      }
      await store.save('entry', {...shared, 'base': 200}, id: entry);
      expect((await store.readAll()).byId(entry)?['shares'], [100, 100]);
      expect(
        await store
            .customSelect('SELECT * FROM audit WHERE entry=$entry')
            .get(),
        hasLength(2),
      );
      await store.removeEntry(entry);
      expect((await store.readAll()).byId(entry), isNull);
    },
  );

  test('backup preserves IDs and rolls back if a staged write fails', () async {
    final id = await store.save('client', {'name': 'Original'});
    final saved = await store.backup();
    await store.save('client', {'name': 'Edited'}, id: id);
    final envelope = jsonDecode(saved) as Record;
    final body = jsonDecode(envelope['body'] as String) as Record;
    (body['audit'] as List).add({'id': 1, 'entry': null});
    final badBody = jsonEncode(body);
    await expectLater(
      store.restore(
        jsonEncode({
          ...envelope,
          'body': badBody,
          'sha256': sha256.convert(utf8.encode(badBody)).toString(),
        }),
      ),
      throwsA(anything),
    );
    expect((await store.readAll()).byId(id)?['name'], 'Edited');
    await store.restore(saved);
    expect((await store.readAll()).byId(id)?['name'], 'Original');
  });

  test('migrates a version 1 database and preserves its records', () async {
    final directory = await Directory.systemTemp.createTemp('badalaty_test');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/old.sqlite');
    final legacy = NativeDatabase(
      file,
      setup: (database) {
        database.execute(
          'CREATE TABLE records (id INTEGER PRIMARY KEY, kind TEXT, day TEXT, client INTEGER, assignment INTEGER, payload TEXT)',
        );
        database.execute('INSERT INTO records(id,kind,payload) VALUES(1,?,?)', [
          'client',
          '{"name":"Legacy"}',
        ]);
        database.execute('PRAGMA user_version = 1');
      },
    );
    await store.close();
    store = Store(legacy);
    expect((await store.readAll()).byId(1)?['name'], 'Legacy');
    expect(await store.customSelect('SELECT * FROM audit').get(), isEmpty);
  });
}
