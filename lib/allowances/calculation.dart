enum Category { shared, travel, ride }

class Allocation {
  const Allocation(this.total, this.multiplier, this.shares);
  final int total;
  final int multiplier;
  final List<int> shares;
}

const maxAmount = 1000000000;

Allocation sharedAllowance(int base, int count, int rotation) {
  if (base < 0 || base > maxAmount || count < 1 || rotation < 0) {
    throw ArgumentError('Invalid transportation inputs');
  }
  final multiplier = (count + 1) ~/ 2;
  final total = base * multiplier;
  final shares = List.filled(count, total ~/ count);
  for (var index = 0; index < total % count; index++) {
    shares[(rotation + index) % count]++;
  }
  return Allocation(total, multiplier, shares);
}

int accommodationAllowance(int base, int basisPoints) {
  if (base < 0 || base > maxAmount || basisPoints < 0 || basisPoints > 10000) {
    throw ArgumentError('Invalid accommodation inputs');
  }
  return (base * basisPoints + 5000) ~/ 10000;
}

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
