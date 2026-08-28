import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/auth_service.dart';

void main() {
  group('isStudentEmail', () {
    test('matches the student pattern {digits}@arscience.school', () {
      expect(isStudentEmail('123456@arscience.school'), true);
      expect(isStudentEmail('7@arscience.school'), true); // any digit count
    });

    test('rejects anything else as a teacher email', () {
      expect(isStudentEmail('teacher@school.edu'), false);
      expect(isStudentEmail('123456@gmail.com'), false);
      expect(isStudentEmail('abc@arscience.school'), false);
    });
  });

  group('studentEmailFromRawId', () {
    test('builds the plain-digit email with no dash', () {
      expect(studentEmailFromRawId('123456'), '123456@arscience.school');
    });

    test('strips a dash if the caller passes a formatted id by mistake', () {
      expect(studentEmailFromRawId('12-3456'), '123456@arscience.school');
    });
  });

  group('normalizeStudentIdInput', () {
    test('passes a literal email through unchanged', () {
      expect(
        normalizeStudentIdInput('123456@arscience.school'),
        '123456@arscience.school',
      );
    });

    test('strips non-digits from a raw or dash-formatted id', () {
      expect(normalizeStudentIdInput('12-3456'), '123456');
      expect(normalizeStudentIdInput('123456'), '123456');
    });
  });
}
