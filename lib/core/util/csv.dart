/// Minimal RFC 4180 CSV reader/writer.
///
/// Written by hand rather than pulled in as a dependency because the two
/// things this app does with CSV are narrow and well understood: exporting an
/// item-analysis table, and importing a student roster a teacher typed in
/// Excel or Google Sheets. What those files really need is correct handling
/// of quoted fields — a student name with a comma ("Dela Cruz, Juan") or a
/// question containing one would otherwise silently split into two columns.
library;

/// Escapes one field for output. A field is quoted only when it has to be —
/// if it contains a comma, a double quote, or a line break — and embedded
/// quotes are doubled, per RFC 4180.
String csvEscapeField(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuoting =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuoting) return text;
  return '"${text.replaceAll('"', '""')}"';
}

/// Renders [rows] as a CSV document. Every row is escaped field by field.
///
/// Lines are joined with CRLF, which is what RFC 4180 specifies and what
/// Excel on Windows expects; a leading UTF-8 BOM is included so Excel opens
/// non-ASCII text (Filipino names, the `·` and `–` characters this app uses)
/// in the right encoding instead of mojibake.
String encodeCsv(List<List<Object?>> rows, {bool withBom = true}) {
  final body = rows
      .map((row) => row.map(csvEscapeField).join(','))
      .join('\r\n');
  return withBom ? '﻿$body' : body;
}

/// Parses a CSV document into rows of raw string fields.
///
/// Handles quoted fields, doubled quotes inside them, embedded newlines, a
/// leading UTF-8 BOM, and both LF and CRLF line endings. Blank lines are
/// dropped — a trailing newline at the end of a file is normal and must not
/// produce a phantom empty row.
List<List<String>> parseCsv(String input) {
  final text = input.startsWith('﻿') ? input.substring(1) : input;

  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    // A line that held nothing but whitespace is not a record.
    if (row.any((f) => f.trim().isNotEmpty)) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];

    if (inQuotes) {
      if (char == '"') {
        // A doubled quote inside a quoted field is one literal quote.
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }

    switch (char) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        // Swallow the LF of a CRLF pair so it doesn't start a second row.
        if (i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      case '\n':
        endRow();
      default:
        field.write(char);
    }
  }
  // Whatever is buffered when the input runs out is the final record; an
  // input ending in a newline leaves it empty, and endRow() drops that.
  endRow();

  return rows;
}
