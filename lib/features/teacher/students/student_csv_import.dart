import '../../../core/models/student_record.dart';
import '../../../core/services/auth_service.dart' show normalizeStudentIdInput;
import '../../../core/services/student_account_service.dart';
import '../../../core/util/csv.dart';
import 'student_id_format.dart';
import 'students_providers.dart';

/// One parsed line of an import file, valid or not.
///
/// Invalid rows are kept rather than dropped: a teacher who exports 40
/// students from Excel needs to see *which* line was wrong and why, not a
/// count of how many silently vanished.
class StudentImportRow {
  const StudentImportRow({
    required this.lineNumber,
    required this.name,
    required this.studentId,
    required this.grade,
    required this.section,
    required this.password,
    required this.errors,
  });

  /// 1-based line number in the original file, counting the header — so it
  /// matches the row number the teacher sees in Excel.
  final int lineNumber;
  final String name;
  final String studentId;
  final String grade;
  final String section;
  final String password;
  final List<String> errors;

  bool get isValid => errors.isEmpty;

  StudentRecord toRecord() => blankStudentRecord(
    name: name,
    studentId: studentId,
    grade: grade,
    section: section,
  );
}

/// Result of reading an import file.
class StudentImportPlan {
  const StudentImportPlan({
    required this.rows,
    required this.fatalError,
    required this.missingColumns,
  });

  final List<StudentImportRow> rows;

  /// Set when the file could not be interpreted at all (empty, no header).
  /// When present, [rows] is empty and nothing can be imported.
  final String? fatalError;

  /// Required column names the header did not contain.
  final List<String> missingColumns;

  List<StudentImportRow> get validRows => rows.where((r) => r.isValid).toList();
  List<StudentImportRow> get invalidRows =>
      rows.where((r) => !r.isValid).toList();
  bool get canImport => fatalError == null && validRows.isNotEmpty;
}

/// Column headers this importer understands, in the order they appear in the
/// downloadable template. Several spellings are accepted per column because
/// the file will realistically be typed by hand in Excel or Sheets — a
/// teacher writing "Student ID" instead of "studentId" should not be met
/// with a parse failure.
const _columnAliases = <String, List<String>>{
  'name': ['name', 'full name', 'student name', 'pangalan'],
  'studentId': ['studentid', 'student id', 'id', 'lrn', 'student number'],
  'grade': ['grade', 'grade level', 'baitang'],
  'section': ['section', 'seksyon'],
  'password': ['password', 'pass', 'temporary password'],
};

String _normalizeHeader(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'[_\-]+'), ' ');

/// A ready-to-fill CSV the teacher can download, so the expected columns are
/// discoverable instead of documented somewhere they will never read.
String studentImportTemplateCsv() => encodeCsv([
  const ['Name', 'Student ID', 'Grade', 'Section', 'Password'],
  const ['Juan Dela Cruz', '12-3456', '7', 'Rizal', 'science123'],
  const ['Maria Santos', '123457', '7', 'Rizal', 'science456'],
]);

/// Parses and validates a roster CSV.
///
/// Everything is checked up front and reported together, so the teacher
/// fixes one file once rather than discovering errors one failed import at a
/// time. [existingStudentIds] lets already-registered students be flagged
/// before any write is attempted.
StudentImportPlan parseStudentImportCsv(
  String content, {
  Set<String> existingStudentIds = const {},
}) {
  final table = parseCsv(content);
  if (table.isEmpty) {
    return const StudentImportPlan(
      rows: [],
      fatalError:
          'That file is empty. Use the template if you are not sure of the '
          'format.',
      missingColumns: [],
    );
  }

  final header = table.first.map(_normalizeHeader).toList();
  final columnIndex = <String, int>{};
  for (final entry in _columnAliases.entries) {
    final index = header.indexWhere((h) => entry.value.contains(h));
    if (index >= 0) columnIndex[entry.key] = index;
  }

  final missing = _columnAliases.keys
      .where((key) => !columnIndex.containsKey(key))
      .toList();
  if (missing.isNotEmpty) {
    return StudentImportPlan(
      rows: const [],
      fatalError:
          'The first row of the file must name the columns. Missing: '
          '${missing.join(', ')}.',
      missingColumns: missing,
    );
  }

  final rows = <StudentImportRow>[];
  // Duplicates *within the file* are as much a problem as duplicates against
  // the database — importing the same id twice would create one student and
  // then fail confusingly on the second.
  final seenIds = <String, int>{};

  for (var i = 1; i < table.length; i++) {
    final cells = table[i];
    String cell(String column) {
      final index = columnIndex[column]!;
      return index < cells.length ? cells[index].trim() : '';
    }

    final name = cell('name');
    final rawId = cell('studentId');
    final grade = cell('grade');
    final section = cell('section');
    final password = cell('password');
    final studentId = normalizeStudentIdInput(rawId);

    final errors = <String>[];
    if (name.isEmpty) errors.add('Name is required');
    if (rawId.isEmpty) {
      errors.add('Student ID is required');
    } else if (!isValidStudentIdInput(rawId)) {
      errors.add('Student ID must be exactly 6 digits');
    }
    if (grade.isEmpty) errors.add('Grade is required');
    if (section.isEmpty) errors.add('Section is required');
    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < StudentAccountService.minPasswordLength) {
      errors.add(
        'Password must be at least '
        '${StudentAccountService.minPasswordLength} characters',
      );
    }
    if (studentId.isNotEmpty && seenIds.containsKey(studentId)) {
      errors.add('Duplicate of line ${seenIds[studentId]} in this file');
    } else if (studentId.isNotEmpty) {
      seenIds[studentId] = i + 1;
    }
    if (studentId.isNotEmpty && existingStudentIds.contains(studentId)) {
      errors.add('A student with this ID already exists');
    }

    rows.add(
      StudentImportRow(
        lineNumber: i + 1,
        name: name,
        studentId: studentId,
        grade: grade,
        section: section,
        password: password,
        errors: errors,
      ),
    );
  }

  if (rows.isEmpty) {
    return const StudentImportPlan(
      rows: [],
      fatalError: 'That file has column names but no students in it.',
      missingColumns: [],
    );
  }

  return StudentImportPlan(
    rows: rows,
    fatalError: null,
    missingColumns: const [],
  );
}

/// Outcome of one attempted import, per row.
class StudentImportOutcome {
  const StudentImportOutcome({required this.row, required this.error});

  final StudentImportRow row;

  /// Null when the student was created successfully.
  final String? error;

  bool get succeeded => error == null;
}
