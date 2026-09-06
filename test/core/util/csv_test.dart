import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/util/csv.dart';

void main() {
  group('encodeCsv', () {
    test('quotes only the fields that need it, and doubles inner quotes', () {
      final csv = encodeCsv([
        const ['plain', 'has,comma', 'has"quote', 'has\nnewline'],
      ], withBom: false);

      expect(csv, 'plain,"has,comma","has""quote","has\nnewline"');
    });

    test('writes a BOM by default so Excel reads UTF-8 correctly', () {
      // Without the BOM, Excel opens the file in the system codepage and
      // Filipino names with accents come out as mojibake.
      expect(
        encodeCsv([
          const ['a'],
        ]).codeUnitAt(0),
        0xFEFF,
      );
      expect(
        encodeCsv([
          const ['a'],
        ], withBom: false).startsWith('a'),
        isTrue,
      );
    });

    test('separates records with CRLF', () {
      expect(
        encodeCsv([
          const ['a'],
          const ['b'],
        ], withBom: false),
        'a\r\nb',
      );
    });
  });

  group('parseCsv', () {
    test('round-trips a quoted field containing a comma', () {
      final encoded = encodeCsv([
        const ['Name', 'Section'],
        const ['Dela Cruz, Juan', 'Rizal'],
      ]);

      expect(parseCsv(encoded), [
        ['Name', 'Section'],
        ['Dela Cruz, Juan', 'Rizal'],
      ]);
    });

    test('handles doubled quotes, embedded newlines, CRLF and a BOM', () {
      const input = '﻿a,"say ""hi""","two\nlines"\r\nb,c,d\r\n';

      expect(parseCsv(input), [
        ['a', 'say "hi"', 'two\nlines'],
        ['b', 'c', 'd'],
      ]);
    });

    test('drops blank lines rather than emitting phantom rows', () {
      // A trailing newline is normal at the end of a file and must not read
      // as an extra, empty student.
      expect(parseCsv('a,b\n\n\nc,d\n'), [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    });

    test('an empty document parses to no rows', () {
      expect(parseCsv(''), isEmpty);
      expect(parseCsv('\n  \n'), isEmpty);
    });
  });
}
