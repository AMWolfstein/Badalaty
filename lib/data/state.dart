import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'store.dart';

final storeProvider = Provider<Store>((ref) {
  final db = Store.local();
  ref.onDispose(db.close);
  return db;
});
final recordsProvider = FutureProvider(
  (ref) => ref.watch(storeProvider).readAll(),
);

const recordedDayStatuses = {'leave', 'office'};

extension Records on List<Record> {
  Iterable<Record> ofKind(String kind) =>
      where((record) => record['kind'] == kind);
  Record? byId(Object? id) => where((record) => record['id'] == id).firstOrNull;
  Record get settings => ofKind('settings').firstOrNull ?? {};
  Iterable<Record> get entries => ofKind('entry');
  Iterable<Record> get recordedDays =>
      ofKind('day').where((r) => recordedDayStatuses.contains(r['status']));
  Iterable<Record> get activity => where(
    (r) =>
        r['kind'] == 'entry' ||
        (r['kind'] == 'day' && recordedDayStatuses.contains(r['status'])),
  );

  Record? activeOn(String day) => ofKind('assignment')
      .where(
        (a) =>
            a['status'] == 'active' &&
            day.compareTo(a['start'] as String) >= 0 &&
            day.compareTo(a['end'] as String) <= 0,
      )
      .firstOrNull;
}

extension RecordActions on WidgetRef {
  Future<void> saveRecord(String kind, Record record, {int? id}) async {
    await read(storeProvider).save(kind, record, id: id);
    invalidate(recordsProvider);
  }
}

int ownerTotal(Iterable<Record> entries) =>
    entries.fold(0, (sum, record) => sum + (record['owner'] as int));
