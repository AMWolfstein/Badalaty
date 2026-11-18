import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_localizations.dart';

extension Labels on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
  String formattedNumber(int number) =>
      NumberFormat.decimalPattern(l.localeName).format(number);
  String money(int number) => '${formattedNumber(number)} ${l.egp}';
}

extension RecordLabels on AppLocalizations {
  String categoryName(String category) => switch (category) {
    'shared' => shared,
    'travel' => travel,
    _ => ride,
  };
  String statusName(String status) => switch (status) {
    'planned' => planned,
    'active' => active,
    'completed' => completed,
    'cancelled' => cancelled,
    'recorded' => recorded,
    'missing' => missing,
    'leave' => leave,
    'office' => office,
    'holiday' => holiday,
    'weekend' => weekend,
    'noAllowance' => noAllowance,
    'future' => future,
    _ => none,
  };
}
