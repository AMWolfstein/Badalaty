import 'package:badalaty/data/store.dart';
import 'package:badalaty/widgets/platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'widget and reminder snapshot follow calendar dates and owner shares',
    () {
      final records = <Record>[
        {
          'kind': 'settings',
          'workweek': [1, 2, 3, 4, 5],
          'reminders': true,
        },
        {'kind': 'client', 'id': 1, 'name': 'Company A'},
        {
          'kind': 'assignment',
          'id': 2,
          'name': 'Hurghada',
          'client': 1,
          'status': 'active',
          'start': '2026-11-18',
          'end': '2026-11-20',
        },
        {'kind': 'day', 'day': '2026-11-19', 'status': 'holiday'},
        {
          'kind': 'entry',
          'day': '2026-11-18',
          'assignment': 2,
          'category': 'shared',
          'owner': 67,
          'total': 200,
        },
        {
          'kind': 'entry',
          'day': '2026-11-18',
          'assignment': 2,
          'category': 'ride',
          'owner': 42,
          'total': 42,
        },
        {
          'kind': 'entry',
          'day': '2026-11-20',
          'assignment': 2,
          'category': 'travel',
          'owner': 149,
          'total': 149,
        },
      ];
      final snapshot = platformSnapshot(
        records,
        DateTime(2026, 11, 18, 23, 59),
      );
      final days = snapshot['days'] as Map<String, Record>;
      expect(snapshot['hour'], 18);
      expect(days['2026-11-18'], {
        'amount': 109,
        'assignment': 'Company A · Hurghada',
        'count': 2,
        'reminder': 'travel',
      });
      expect(days['2026-11-19']?.containsKey('reminder'), false);
      expect(days['2026-11-20']?.containsKey('reminder'), false);
      expect(days['2026-11-21'], {'amount': 0, 'count': 0});
      expect(days['2026-11-23']?['reminder'], 'general');
      final after = platformSnapshot(records, DateTime(2026, 11, 19));
      expect((after['days'] as Map).containsKey('2026-11-18'), false);
    },
  );
}
