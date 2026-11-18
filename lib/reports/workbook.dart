import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../data/state.dart';
import '../data/store.dart';
import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';

const _spreadsheet =
    'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _rels =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _packageRels =
    'http://schemas.openxmlformats.org/package/2006/relationships';
const _content = 'http://schemas.openxmlformats.org/package/2006/content-types';

String _escape(Object? value) => (value?.toString() ?? '')
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

Uint8List workbook(List<Record> entries, AppLocalizations l, String metadata) {
  for (final entry in entries) {
    validateEntry(entry);
  }
  final daily = <List<Object?>>[
    [
      l.date,
      l.client,
      l.assignment,
      l.location,
      l.category,
      l.base,
      l.people,
      l.multiplier,
      l.total,
      l.owner,
      l.notes,
    ],
  ];
  final distribution = <List<Object?>>[
    [l.date, l.client, l.assignment, l.name, l.employeeId, l.people, l.amount],
  ];
  final travel = <List<Object?>>[
    [
      l.date,
      l.client,
      l.assignment,
      l.destination,
      l.meals,
      l.lodging,
      l.total,
    ],
  ];
  final rides = <List<Object?>>[
    [l.date, l.client, l.assignment, l.provider, l.amount, l.notes],
  ];
  final employees = <(String, String), int>{};
  final groups = <(String, String, String), List<Record>>{};
  final summary = <List<Object?>>[
    [
      l.client,
      l.assignment,
      l.category,
      l.teamTotal,
      l.ownerShared,
      l.travel,
      l.ride,
      l.owner,
    ],
  ];
  for (final e in entries) {
    final category = e['category'] as String;
    final common = [e['day'], e['clientName'], e['assignmentName']];
    final people = e['people'] as List?;
    daily.add([
      ...common,
      e['location'],
      l.categoryName(category),
      e['base'],
      people?.length,
      e['multiplier'],
      e['total'],
      e['owner'],
      e['notes'],
    ]);
    groups
        .putIfAbsent((
          e['clientName'] as String? ?? '',
          e['assignmentName'] as String? ?? '',
          category,
        ), () => [])
        .add(e);
    if (people != null) {
      final shares = e['shares'] as List;
      for (var i = 0; i < people.length; i++) {
        final person = people[i] as Record;
        final key = (person['code'] as String, person['name'] as String);
        final share = shares[i] as int;
        employees.update(
          key,
          (amount) => amount + share,
          ifAbsent: () => share,
        );
        distribution.add([...common, key.$2, key.$1, people.length, share]);
      }
    } else if (category == 'travel') {
      travel.add([
        ...common,
        e['location'],
        e['meals'],
        e['lodging'],
        e['total'],
      ]);
    } else {
      rides.add([
        ...common,
        e['provider'] == 'other' ? l.other : e['provider'],
        e['total'],
        e['notes'],
      ]);
    }
  }
  final shared = entries.where((e) => e['category'] == 'shared');
  int totals(Iterable<Record> records) =>
      records.fold(0, (sum, e) => sum + (e['total'] as int));
  if (employees.values.fold(0, (a, b) => a + b) != totals(shared)) {
    throw StateError('Reconciliation failed');
  }
  for (final MapEntry(key: (client, trip, category), value: lines)
      in groups.entries) {
    final owner = ownerTotal(lines);
    summary.add([
      client,
      trip,
      l.categoryName(category),
      category == 'shared' ? totals(lines) : 0,
      category == 'shared' ? owner : 0,
      category == 'travel' ? owner : 0,
      category == 'ride' ? owner : 0,
      owner,
    ]);
  }
  summary.insert(1, [
    l.total,
    '',
    '',
    totals(shared),
    ownerTotal(shared),
    ownerTotal(entries.where((e) => e['category'] == 'travel')),
    ownerTotal(entries.where((e) => e['category'] == 'ride')),
    ownerTotal(entries),
  ]);
  final sheets = {
    l.dailySheet: daily,
    l.distributionSheet: distribution,
    l.travelSheet: travel,
    l.rideSheet: rides,
    l.employeeSheet: <List<Object?>>[
      [l.employeeId, l.name, l.amount],
      for (final item in employees.entries)
        [item.key.$1, item.key.$2, item.value],
    ],
    l.periodSheet: summary,
  };

  final archive = Archive();
  void add(String name, String xml) {
    final bytes = utf8.encode(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>$xml',
    );
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  final indices = List.generate(sheets.length, (index) => index + 1);
  add(
    '[Content_Types].xml',
    '<Types xmlns="$_content"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${indices.map((i) => '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>').join()}</Types>',
  );
  add(
    '_rels/.rels',
    '<Relationships xmlns="$_packageRels"><Relationship Id="rId1" Type="$_rels/officeDocument" Target="xl/workbook.xml"/></Relationships>',
  );
  add(
    'xl/workbook.xml',
    '<workbook xmlns="$_spreadsheet" xmlns:r="$_rels"><sheets>${indices.map((i) => '<sheet name="${_escape(sheets.keys.elementAt(i - 1))}" sheetId="$i" r:id="rId$i"/>').join()}</sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="$_packageRels">${indices.map((i) => '<Relationship Id="rId$i" Type="$_rels/worksheet" Target="worksheets/sheet$i.xml"/>').join()}<Relationship Id="styles" Type="$_rels/styles" Target="styles.xml"/></Relationships>',
  );
  add(
    'xl/styles.xml',
    '<styleSheet xmlns="$_spreadsheet"><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><color rgb="FFFFFFFF"/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF124775"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
  );
  for (final i in indices) {
    final rows = sheets.values.elementAt(i - 1);
    final width = rows.first.length;
    final last = String.fromCharCode(64 + width);
    final xml = StringBuffer(
      '<worksheet xmlns="$_spreadsheet"><sheetViews><sheetView workbookViewId="0" rightToLeft="${l.localeName == 'ar' ? 1 : 0}"><pane ySplit="2" topLeftCell="A3" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols><col min="1" max="$width" width="23" customWidth="1"/></cols><sheetData>',
    );
    final data = [
      [metadata],
      ...rows,
    ];
    for (var row = 0; row < data.length; row++) {
      xml.write('<row r="${row + 1}">');
      for (var col = 0; col < data[row].length; col++) {
        final cell = data[row][col];
        final address = '${String.fromCharCode(65 + col)}${row + 1}';
        if (cell is int) {
          xml.write('<c r="$address"><v>$cell</v></c>');
        } else {
          xml.write(
            '<c r="$address" t="inlineStr"${row == 1 ? ' s="1"' : ''}><is><t xml:space="preserve">${_escape(cell)}</t></is></c>',
          );
        }
      }
      xml.write('</row>');
    }
    xml.write(
      '</sheetData><autoFilter ref="A2:$last${data.length}"/><mergeCells count="1"><mergeCell ref="A1:${last}1"/></mergeCells></worksheet>',
    );
    add('xl/worksheets/sheet$i.xml', xml.toString());
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
