// test/core/services/lesson_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';

void main() {
  test('mergedLessons puts built-ins first, teacher-authored lessons appended', () {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    final teacherLesson = TeacherLesson(
      id: 'teacher-extra-1',
      title: 'Extra Credit: Volcanoes',
      subject: SubjectKey.physics,
      isPredefined: false,
    );

    final merged = repo.mergedLessons([teacherLesson]);

    expect(merged.length, kBuiltInLessons.length + 1);
    expect(merged.first.id, kBuiltInLessons.first.id);
    expect(merged.last.id, 'teacher-extra-1');
  });

  test('mergedLessons dedupes by id, built-in wins over a same-id teacher lesson', () {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    // A teacher lesson that collides with a built-in id should not create a
    // duplicate entry or shadow the built-in's real content.
    final colliding = TeacherLesson(
      id: 'q1w1',
      title: 'Should not appear',
      subject: SubjectKey.chemistry,
    );

    final merged = repo.mergedLessons([colliding]);

    expect(merged.length, kBuiltInLessons.length);
    expect(merged.where((l) => l.id == 'q1w1').single.title,
        kBuiltInLessons.firstWhere((l) => l.id == 'q1w1').title);
  });

  test('watchTeacherLessons streams /lessons documents as TeacherLesson', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    await firestore.collection('lessons').doc('teacher-1').set({
      'id': 'teacher-1',
      'title': 'Community Garden Ecology',
      'subject': 'biology',
    });

    final lessons = await repo.watchTeacherLessons().first;

    expect(lessons, hasLength(1));
    expect(lessons.first.title, 'Community Garden Ecology');
  });
}
