import 'package:badalaty/allowances/calculation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('whole-pound shared allocations reconcile for 1–20 participants', () {
    for (final base in [0, 100, 200, 250]) {
      for (var people = 1; people <= 20; people++) {
        for (var rotation = 0; rotation < people; rotation++) {
          final split = sharedAllowance(base, people, rotation);
          final sorted = [...split.shares]..sort();
          expect(split.total, base * ((people + 1) ~/ 2));
          expect(split.shares.fold(0, (a, b) => a + b), split.total);
          expect(sorted.last - sorted.first, lessThanOrEqualTo(1));
        }
      }
    }
    expect(() => sharedAllowance(-1, 3, 0), throwsArgumentError);
    expect(sharedAllowance(100, 3, 0).shares, [67, 67, 66]);
    expect(sharedAllowance(100, 3, 1).shares, [66, 67, 67]);
    expect(sharedAllowance(100, 7, 0).shares, [58, 57, 57, 57, 57, 57, 57]);
  });

  test('accommodation uses integer basis points with half-up rounding', () {
    expect(accommodationAllowance(70, 7000), 49);
    expect(accommodationAllowance(1, 5000), 1);
    expect(accommodationAllowance(1, 4999), 0);
    expect((100 + accommodationAllowance(70, 7000)) * 7, 1043);
    expect(() => accommodationAllowance(70, 10001), throwsArgumentError);
  });
}
