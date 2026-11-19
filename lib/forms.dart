import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as liquid;
import 'package:intl/intl.dart';

import 'allowances/calculation.dart';
import 'data/store.dart';
import 'l10n/labels.dart';
import 'widgets/glass_design.dart';

Future<bool> confirm(BuildContext context, String message) async =>
    await liquid.GlassDialog.show<bool>(
      context: context,
      message: message,
      actions: [
        liquid.GlassDialogAction(
          label: context.l.cancel,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        liquid.GlassDialogAction(
          label: context.l.confirm,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    ) ??
    false;

void feedback(BuildContext context, String message) => liquid.GlassToast.show(
  context,
  message: message,
  type: liquid.GlassToastType.neutral,
);

Future<DateTime?> glassDateTimePicker(
  BuildContext context, {
  required DateTime initial,
  bool timeOnly = false,
}) {
  var selected = initial;
  final labels = context.l;
  final material = MaterialLocalizations.of(context);
  return liquid.GlassDialog.show<DateTime>(
    context: context,
    title: timeOnly ? labels.reminderTime : labels.date,
    maxWidth: 410,
    content: liquid.GlassDatePicker.wheel(
      initialDateTime: initial,
      mode: timeOnly
          ? liquid.GlassDatePickerMode.time
          : liquid.GlassDatePickerMode.date,
      minimumDate: timeOnly ? null : DateTime(1900),
      maximumDate: timeOnly ? null : DateTime(2200),
      use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      monthNames: List.generate(
        12,
        (index) =>
            DateFormat.MMMM(labels.localeName)
                .format(DateTime(2000, index + 1)),
      ),
      surfaceStyle: liquid.GlassSurfaceStyle.solid,
      onDateTimeChanged: (value) => selected = value,
    ),
    actions: [
      liquid.GlassDialogAction(
        label: labels.cancel,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
      liquid.GlassDialogAction(
        label: material.okButtonLabel,
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(selected),
      ),
    ],
  );
}

String dateLabel(BuildContext context, String day) =>
    DateFormat.yMMMd(context.l.localeName).format(DateTime.parse(day));

class DayField extends StatelessWidget {
  const DayField(
    this.label,
    this.day,
    this.onChange, {
    this.shortDate = false,
    super.key,
  });
  final String label;
  final String day;
  final bool shortDate;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) => GlassContentCard(
    child: liquid.GlassPicker(
      value: shortDate
          ? DateFormat.MMMd(context.l.localeName).format(DateTime.parse(day))
          : dateLabel(context, day),
      semanticLabel: label,
      surfaceStyle: liquid.GlassSurfaceStyle.solid,
      icon: Icon(
        Icons.calendar_today_outlined,
        size: 17,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () async {
        final result = await glassDateTimePicker(
          context,
          initial: DateTime.parse(day),
        );
        if (result != null && context.mounted) onChange(dayKey(result));
      },
    ),
  );
}

class Choice<T> extends StatelessWidget {
  const Choice(
    this.label,
    this.value,
    this.items,
    this.onChange, {
    this.compact = false,
    super.key,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChange;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = items.containsKey(value) ? value : items.keys.firstOrNull;
    final text = items[selected] ?? label;
    final scheme = Theme.of(context).colorScheme;
    final trigger = GlassContentCard(
      color: compact ? scheme.primaryContainer : null,
      child: compact
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            )
          : _FieldContent(
              label: label,
              value: text,
              icon: Icons.keyboard_arrow_down,
            ),
    );
    if (items.isEmpty) return trigger;
    return LayoutBuilder(
      builder: (context, constraints) => liquid.GlassMenu(
        trigger: trigger,
        semanticLabel: '$label, $text',
        menuSemanticLabel: label,
        menuWidth: compact || !constraints.hasBoundedWidth
            ? 240
            : constraints.maxWidth.clamp(185, 360),
        menuBorderRadius: 25,
        itemBorderRadius: 15,
        autoAdjustToScreen: true,
        maxStackHeight: 330,
        menuPadding: const EdgeInsets.all(7),
        selectionColor: scheme.primaryContainer.withValues(alpha: .8),
        items: [
          for (final item in items.entries)
            liquid.GlassMenuItem(
              title: item.value,
              semanticsSelected: item.key == selected,
              trailing: item.key == selected
                  ? Icon(Icons.check_rounded, color: scheme.primary, size: 19)
                  : null,
              onTap: () => onChange(item.key),
            ),
        ],
      ),
    );
  }
}

class _FieldContent extends StatelessWidget {
  const _FieldContent({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: theme.colorScheme.primary, size: 16),
        ],
      ),
    );
  }
}

class SearchRecords extends StatelessWidget {
  const SearchRecords(
    this.label,
    this.items,
    this.selected, {
    required this.onPick,
    this.multiple = false,
    super.key,
  });
  final String label;
  final Iterable<Record> items;
  final Set<int> selected;
  final ValueChanged<Set<int>> onPick;
  final bool multiple;

  @override
  Widget build(BuildContext context) => GlassContentCard(
    child: InkWell(
      child: _FieldContent(
        label: label,
        value: items
            .where((record) => selected.contains(record['id']))
            .map((record) => record['name'])
            .join(' · '),
        icon: Icons.search,
      ),
      onTap: () async {
        final selection = {...selected};
        var search = '';
        final result = await showDialog<Set<int>>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, change) => GlassPanelDialog(
              title: Text(label),
              content: SizedBox(
                width: 440,
                height: 330,
                child: Column(
                  children: [
                    liquid.GlassSearchBar(
                      placeholder: context.l.search,
                      surfaceStyle: liquid.GlassSurfaceStyle.solid,
                      onChanged: (value) =>
                          change(() => search = value.toLowerCase()),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final record in items.where(
                            (r) => '${r['name']} ${r['code'] ?? ''}'
                                .toLowerCase()
                                .contains(search),
                          ))
                            Semantics(
                              checked: multiple
                                  ? selection.contains(record['id'])
                                  : null,
                              child: GlassRow(
                                title: Text(record['name'] as String),
                                subtitle: record['code'] == null
                                    ? null
                                    : Text(record['code'] as String),
                                trailing: selection.contains(record['id'])
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      )
                                    : null,
                                onTap: () {
                                  final id = record['id'] as int;
                                  if (multiple) {
                                    change(() {
                                      if (!selection.remove(id)) {
                                        selection.add(id);
                                      }
                                    });
                                  } else {
                                    Navigator.pop(context, {id});
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                GlassSecondaryAction(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l.cancel),
                ),
                if (multiple)
                  GlassAction(
                    onPressed: () => Navigator.pop(context, selection),
                    child: Text(context.l.confirm),
                  ),
              ],
            ),
          ),
        );
        if (result != null) onPick(result);
      },
    ),
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  bool number = false,
  ValueChanged<String>? onChanged,
}) => Builder(
  builder: (context) {
    final theme = Theme.of(context);
    return GlassContentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            Semantics(
              label: label,
              child: liquid.GlassTextField(
                controller: controller,
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                surfaceStyle: liquid.GlassSurfaceStyle.solid,
                color: Colors.transparent,
                padding: EdgeInsets.zero,
                minHeight: 34,
                keyboardType: number
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  },
);

int? whole(String input) {
  final text = normalizedNumber(input);
  return RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
}

String normalizedNumber(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var value = input.trim().replaceAll('٫', '.');
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
  }
  return value;
}
