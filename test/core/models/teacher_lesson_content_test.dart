// test/core/models/teacher_lesson_content_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';

void main() {
  test('contentImageUrls and contentStatus round-trip', () {
    final json = {
      'id': 'teacher-1',
      'title': 'Volcanoes',
      'subject': 'chemistry',
      'contentImageUrls': ['https://example.com/slide1.png', 'https://example.com/slide2.png'],
      'contentStatus': 'ready',
    };

    final lesson = TeacherLesson.fromJson(json);

    expect(lesson.contentImageUrls, hasLength(2));
    expect(lesson.contentStatus, 'ready');
    expect(lesson.toJson()['contentStatus'], 'ready');
  });

  test('both fields default to null when absent', () {
    final lesson = TeacherLesson.fromJson(const {
      'id': 'teacher-2', 'title': 'No content yet', 'subject': 'biology',
    });

    expect(lesson.contentImageUrls, isNull);
    expect(lesson.contentStatus, isNull);
  });
}
