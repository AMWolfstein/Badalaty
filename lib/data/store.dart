import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../allowances/calculation.dart';

typedef Record = Map<String, dynamic>;

class Store extends GeneratedDatabase {
  Store(super.executor);
  factory Store.local() => Store(
    LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File('${directory.path}/badalaty.sqlite'),
      );
    }),
  );

  static const kinds = [
    'client',
    'employee',
    'team',
    'assignment',
    'day',
    'settings',
    'entry',
  ];
  static const _schema = '''
    CREATE TABLE records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      kind TEXT NOT NULL CHECK(kind IN ('client','employee','team','assignment','day','settings','entry')),
      day TEXT, client INTEGER REFERENCES records(id),
      assignment INTEGER REFERENCES records(id),
      payload TEXT NOT NULL CHECK(json_valid(payload)),
      CHECK(day IS NULL OR length(day) = 10)
    )
  ''';
  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(_schema);
      await _audit();
    },
    onUpgrade: (_, from, to) async {
      if (from < 2) await _audit();
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _audit() async {
    await customStatement(
      'CREATE TABLE audit (id INTEGER PRIMARY KEY, entry INTEGER NOT NULL, at TEXT NOT NULL, before_value TEXT, after_value TEXT)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS records_kind_day ON records(kind, day)',
    );
  }

  Future<List<Record>> readAll() async =>
      (await customSelect(
            'SELECT id, kind, payload FROM records ORDER BY day DESC, id DESC',
          ).get())
          .map(
            (row) => <String, dynamic>{
              ..._decode(row.read<String>('payload')),
              'id': row.read<int>('id'),
              'kind': row.read<String>('kind'),
            },
          )
          .toList();

  Future<int> save(
    String kind,
    Record value, {
    int? id,
  }) => transaction(() async {
    final records = await readAll();
    final previous = records.where((r) => r['id'] == id).firstOrNull;
    if (id != null && previous?['kind'] != kind) {
      throw StateError('Unknown record');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final record =
        <String, dynamic>{
            ...value,
            'createdAt': previous?['createdAt'] ?? now,
            'updatedAt': now,
          }
          ..remove('id')
          ..remove('kind');
    if (kind == 'entry') {
      final sequence = records
          .where((r) => r['kind'] == 'entry')
          .fold<int>(
            -1,
            (max, r) =>
                (r['rotation'] as int) > max ? r['rotation'] as int : max,
          );
      final rotation = previous?['rotation'] as int? ?? sequence + 1;
      record['rotation'] = rotation;
      final category = Category.values.byName(record['category'] as String);
      if (category == Category.shared) {
        final people = List<Record>.from(record['people'] as List);
        if (people.isEmpty ||
            people.map((p) => p['id']).toSet().length != people.length) {
          throw ArgumentError('Duplicate participants');
        }
        final allocation = sharedAllowance(
          record['base'] as int,
          people.length,
          rotation,
        );
        record.addAll({
          'total': allocation.total,
          'owner': allocation.shares.first,
          'multiplier': allocation.multiplier,
          'shares': allocation.shares,
        });
      } else if (category == Category.travel) {
        final accommodation = accommodationAllowance(
          record['lodgingRate'] as int,
          record['basisPoints'] as int,
        );
        record['lodging'] = record['hasLodging'] == true ? accommodation : 0;
        record['meals'] = record['hasMeals'] == true ? record['mealRate'] : 0;
        record['owner'] = (record['lodging'] as int) + (record['meals'] as int);
        record['total'] = record['owner'];
      } else {
        final base = record['base'] as int;
        if (base < 0 || base > maxAmount) {
          throw ArgumentError('Invalid ride amount');
        }
        record['owner'] = base;
        record['total'] = base;
      }
    }
    final payload = jsonEncode(record);
    final variables = [
      Variable(kind),
      Variable<String>(record['day'] as String?),
      Variable<int>(record['client'] as int?),
      Variable<int>(record['assignment'] as int?),
      Variable(payload),
    ];
    final recordId =
        id ??
        await customInsert(
          'INSERT INTO records(kind,day,client,assignment,payload) VALUES(?,?,?,?,?)',
          variables: variables,
        );
    if (id != null) {
      await customUpdate(
        'UPDATE records SET kind=?,day=?,client=?,assignment=?,payload=? WHERE id=?',
        variables: [...variables, Variable(id)],
      );
    }
    if (kind == 'entry') await _writeAudit(recordId, previous, record);
    return recordId;
  });

  Future<void> removeEntry(int id) => transaction(() async {
    final previous = (await readAll()).firstWhere(
      (r) => r['id'] == id && r['kind'] == 'entry',
    );
    await customUpdate(
      'DELETE FROM records WHERE id=?',
      variables: [Variable(id)],
    );
    await _writeAudit(id, previous, null);
  });

  Future<void> _writeAudit(int id, Record? before, Record? after) async {
    await customStatement(
      'INSERT INTO audit(entry,at,before_value,after_value) VALUES(?,?,?,?)',
      [
        id,
        DateTime.now().toUtc().toIso8601String(),
        before == null ? null : jsonEncode(before),
        after == null ? null : jsonEncode(after),
      ],
    );
  }

  Future<String> backup() => transaction(() async {
    final audit = await customSelect('SELECT * FROM audit ORDER BY id').get();
    final body = jsonEncode({
      'records': await readAll(),
      'audit': audit.map((row) => row.data).toList(),
    });
    return jsonEncode({
      'version': 1,
      'sha256': sha256.convert(utf8.encode(body)).toString(),
      'body': body,
    });
  });

  Future<void> restore(String backup) async {
    final envelope = _decode(backup);
    final body = envelope['body'] as String;
    if (envelope['version'] != 1 ||
        sha256.convert(utf8.encode(body)).toString() != envelope['sha256']) {
      throw const FormatException('Invalid backup');
    }
    final document = _decode(body);
    final records = List<Record>.from(document['records'] as List);
    final audit = List<Record>.from(document['audit'] as List);
    final byId = {for (final record in records) record['id'] as int: record};
    if (byId.length != records.length) {
      throw const FormatException('Duplicate record IDs');
    }
    for (final record in records) {
      if (!kinds.contains(record['kind']) ||
          (record['client'] != null &&
              byId[record['client']]?['kind'] != 'client') ||
          (record['assignment'] != null &&
              byId[record['assignment']]?['kind'] != 'assignment')) {
        throw const FormatException('Invalid record reference');
      }
      if (record['kind'] == 'entry') validateEntry(record);
    }
    await transaction(() async {
      await customStatement('PRAGMA defer_foreign_keys = ON');
      await customStatement('DELETE FROM records');
      await customStatement('DELETE FROM audit');
      for (final record in records) {
        final payload = Map.of(record)
          ..remove('id')
          ..remove('kind');
        await customStatement(
          'INSERT INTO records(id,kind,day,client,assignment,payload) VALUES(?,?,?,?,?,?)',
          [
            record['id'],
            record['kind'],
            record['day'],
            record['client'],
            record['assignment'],
            jsonEncode(payload),
          ],
        );
      }
      for (final row in audit) {
        await customStatement(
          'INSERT INTO audit(id,entry,at,before_value,after_value) VALUES(?,?,?,?,?)',
          [
            row['id'],
            row['entry'],
            row['at'],
            row['before_value'],
            row['after_value'],
          ],
        );
      }
    });
  }
}

Record _decode(String value) => jsonDecode(value) as Record;

void validateEntry(Record entry) {
  final total = entry['total'] as int;
  final owner = entry['owner'] as int;
  final day = entry['day'] as String;
  if (dayKey(DateTime.parse(day)) != day || owner < 0 || owner > total) {
    throw const FormatException('Invalid entry');
  }
  switch (Category.values.byName(entry['category'] as String)) {
    case Category.shared:
      final people = entry['people'] as List;
      final shares = List<int>.from(entry['shares'] as List);
      final expected = sharedAllowance(
        entry['base'] as int,
        people.length,
        entry['rotation'] as int,
      );
      if (shares.length != people.length ||
          shares.first != owner ||
          expected.total != total ||
          expected.multiplier != entry['multiplier'] ||
          List.generate(
            shares.length,
            (index) => shares[index] == expected.shares[index],
          ).contains(false)) {
        throw const FormatException('Invalid distribution');
      }
    case Category.travel:
      if (total != owner ||
          (entry['meals'] as int) + (entry['lodging'] as int) != total) {
        throw const FormatException('Invalid travel totals');
      }
    case Category.ride:
      if (total != owner || entry['base'] != total) {
        throw const FormatException('Invalid ride amount');
      }
  }
}
