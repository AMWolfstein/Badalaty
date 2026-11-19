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
  final entriesByDay = <String, List<Record>>{};
  final statusByDay = <String, Object?>{};
  final activeTrips = <Record>[];
  final clients = <Object?, Record>{};
  for (final record in records) {
    switch (record['kind']) {
      case 'entry':
        if (record['day'] case final String day) {
          entriesByDay.putIfAbsent(day, () => []).add(record);
        }
      case 'day':
        if (record['day'] case final String day) {
          statusByDay.putIfAbsent(day, () => record['status']);
        }
      case 'assignment' when record['status'] == 'active':
        activeTrips.add(record);
      case 'client':
        clients[record['id']] = record;
    }
  }
  const excludedStatuses = {
    ...recordedDayStatuses,
    'holiday',
    'noAllowance',
    'weekend',
  };
  for (var i = 0; i < 90; i++) {
    final date = DateTime(now.year, now.month, now.day + i);
    final key = dayKey(date);
    final trip = activeTrips
        .where(
          (trip) =>
              (trip['start'] as String).compareTo(key) <= 0 &&
              (trip['end'] as String).compareTo(key) >= 0,
        )
        .firstOrNull;
    final entries = entriesByDay[key] ?? const <Record>[];
    final status = statusByDay[key];
    final excluded = excludedStatuses.contains(status);
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
            '${clients[trip['client']]?['name'] ?? ''} · ${trip['name']}',
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
