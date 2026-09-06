import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/features/teacher/students/student_csv_import.dart';

const _header = 'Name,Student ID,Grade,Section,Password';

void main() {
  group('parseStudentImportCsv', () {
    test('accepts a well-formed file and normalizes dashed student ids', () {
      final plan = parseStudentImportCsv(
        '$_header\n'
        'Juan Dela Cruz,12-3456,7,Rizal,science123\n'
        'Maria Santos,123457,8,Bonifacio,science456\n',
      );

      expect(plan.fatalError, isNull);
      expect(plan.canImport, isTrue);
      expect(plan.validRows, hasLength(2));
      // The dash is a display convention only — the stored id is 6 digits.
      expect(plan.rows.first.studentId, '123456');
      expect(plan.rows.first.toRecord().studentId, '123456');
    });

    test(
      'accepts alternative header spellings a teacher would actually type',
      () {
        final plan = parseStudentImportCsv(
          'Full Name,ID,Grade Level,Seksyon,Temporary Password\n'
          'Juan Dela Cruz,123456,7,Rizal,science123\n',
        );

        expect(plan.fatalError, isNull);
        expect(plan.validRows, hasLength(1));
      },
    );

    test('reports every problem on a row instead of only the first', () {
      final plan = parseStudentImportCsv(
        '$_header\n'
        ',12,,Rizal,abc\n',
      );

      final row = plan.rows.single;
      expect(row.isValid, isFalse);
      expect(row.errors, contains('Name is required'));
      expect(row.errors, contains('Student ID must be exactly 6 digits'));
      expect(row.errors, contains('Grade is required'));
      expect(row.errors, contains('Password must be at least 6 characters'));
    });

    test('flags a duplicate inside the file and names the earlier line', () {
      final plan = parseStudentImportCsv(
        '$_header\n'
        'Juan,123456,7,Rizal,science123\n'
        'Juan Again,12-3456,7,Rizal,science123\n',
      );

      expect(plan.rows.first.isValid, isTrue);
      expect(
        plan.rows.last.errors,
        contains('Duplicate of line 2 in this file'),
      );
    });

    test('flags a student who is already on the roster', () {
      final plan = parseStudentImportCsv(
        '$_header\n'
        'Juan,123456,7,Rizal,science123\n',
        existingStudentIds: const {'123456'},
      );

      expect(
        plan.rows.single.errors,
        contains('A student with this ID already exists'),
      );
      expect(plan.canImport, isFalse);
    });

    test('good rows stay importable even when other rows are broken', () {
      // The whole point of per-row validation: one bad line must not cost
      // the teacher the other 39.
      final plan = parseStudentImportCsv(
        '$_header\n'
        'Juan,123456,7,Rizal,science123\n'
        'Broken,nope,,,\n'
        'Maria,123457,7,Rizal,science456\n',
      );

      expect(plan.validRows.map((r) => r.studentId), ['123456', '123457']);
      expect(plan.invalidRows, hasLength(1));
      expect(plan.canImport, isTrue);
    });

    test('a name containing a comma survives, because fields are quoted', () {
      final plan = parseStudentImportCsv(
        '$_header\n'
        '"Dela Cruz, Juan",123456,7,Rizal,science123\n',
      );

      expect(plan.rows.single.name, 'Dela Cruz, Juan');
      expect(plan.rows.single.isValid, isTrue);
    });

    test(
      'explains an unusable file rather than importing nothing silently',
      () {
        expect(parseStudentImportCsv('').fatalError, isNotNull);
        expect(
          parseStudentImportCsv('$_header\n').fatalError,
          contains('no students'),
        );

        final wrongHeader = parseStudentImportCsv('Name,Age\nJuan,13\n');
        expect(wrongHeader.fatalError, contains('Missing'));
        expect(wrongHeader.missingColumns, contains('password'));
      },
    );

    test('the shipped template parses cleanly through its own importer', () {
      final plan = parseStudentImportCsv(studentImportTemplateCsv());

      expect(plan.fatalError, isNull);
      expect(plan.invalidRows, isEmpty);
      expect(plan.validRows, hasLength(2));
    });
  });
}
