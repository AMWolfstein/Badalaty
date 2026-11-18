import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../allowances/calculation.dart';
import '../data/state.dart';
import '../data/store.dart';

const platformChannel = MethodChannel('badalaty/platform');

Future<void> requestReminderPermission() async {
  if (Platform.isAndroid) {
    await platformChannel.invokeMethod<void>('permission');
  }
}

Future<void> publishPlatformData(List<Record> records) async {
  if (!Platform.isAndroid) return;
  await platformChannel.invokeMethod<void>(
    'publish',
    jsonEncode(platformSnapshot(records, DateTime.now())),
  );
}

Record platformSnapshot(List<Record> records, DateTime now) {
  final settings = records.settings;
  final dates = <String, Record>{};
  final weekday = settings['workweek'] as List? ?? [7, 1, 2, 3, 4];
  for (var i = 0; i < 90; i++) {
    final date = DateTime(now.year, now.month, now.day + i);
    final key = dayKey(date);
    final trip = records.activeOn(key);
    final entries = records.entries.where((e) => e['day'] == key).toList();
    final status = records
        .ofKind('day')
        .where((record) => record['day'] == key)
        .firstOrNull?['status'];
    final excluded = [
      ...recordedDayStatuses,
      'holiday',
      'noAllowance',
      'weekend',
    ].contains(status);
    final needsReminder =
        !excluded &&
        (trip == null
            ? weekday.contains(date.weekday) && entries.isEmpty
            : !entries.any(
                (entry) =>
                    entry['assignment'] == trip['id'] &&
                    entry['category'] == 'travel',
              ));
    dates[key] = {
      'amount': ownerTotal(entries),
      if (trip != null)
        'assignment':
            '${records.byId(trip['client'])?['name'] ?? ''} · ${trip['name']}',
      'count': entries.length + (recordedDayStatuses.contains(status) ? 1 : 0),
      if (needsReminder) 'reminder': trip == null ? 'general' : 'travel',
    };
  }
  return {
    'mode': settings['language'] ?? 'system',
    'theme': settings['theme'] ?? 'system',
    'reminders': settings['reminders'] == true,
    'hour': settings['hour'] ?? 18,
    'minute': settings['minute'] ?? 0,
    'days': dates,
  };
}
