// test/core/services/lesson_repository_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/data/curriculum_data.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/services/lesson_repository.dart';

void main() {
  test(
    'mergedLessons puts built-ins first, teacher-authored lessons appended',
    () {
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
    },
  );

  test(
    'mergedLessons dedupes by id, built-in wins over a same-id teacher lesson',
    () {
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
      expect(
        merged.where((l) => l.id == 'q1w1').single.title,
        kBuiltInLessons.firstWhere((l) => l.id == 'q1w1').title,
      );
    },
  );

  test(
    'watchTeacherLessons streams /lessons documents as TeacherLesson',
    () async {
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
    },
  );

  test('createLesson writes a doc at /lessons/{lesson.id}', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    final lesson = TeacherLesson(
      id: 'teacher-new-1',
      title: 'New Lesson',
      subject: SubjectKey.biology,
    );

    await repo.createLesson(lesson);

    final doc = await firestore
        .collection('lessons')
        .doc('teacher-new-1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['title'], 'New Lesson');
  });

  test('updateLesson overwrites the existing doc', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    await firestore.collection('lessons').doc('teacher-1').set({
      'id': 'teacher-1',
      'title': 'Old Title',
      'subject': 'biology',
    });

    final updated = TeacherLesson(
      id: 'teacher-1',
      title: 'Updated Title',
      subject: SubjectKey.biology,
    );

    await repo.updateLesson(updated);

    final doc = await firestore.collection('lessons').doc('teacher-1').get();
    expect(doc.data()!['title'], 'Updated Title');
  });

  test(
    'archiveLesson sets isArchived: true without altering other fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);

      await firestore.collection('lessons').doc('teacher-1').set({
        'id': 'teacher-1',
        'title': 'Community Garden Ecology',
        'subject': 'biology',
        'summary': 'A lesson about gardens',
      });

      await repo.archiveLesson('teacher-1');

      final doc = await firestore.collection('lessons').doc('teacher-1').get();
      final data = doc.data()!;
      expect(data['isArchived'], isTrue);
      expect(data['title'], 'Community Garden Ecology');
      expect(data['subject'], 'biology');
      expect(data['summary'], 'A lesson about gardens');
    },
  );

  test('mergedLessons excludes archived teacher lessons by default', () {
    final firestore = FakeFirebaseFirestore();
    final repo = LessonRepository(firestore: firestore);

    final archived = TeacherLesson(
      id: 'teacher-archived-1',
      title: 'Archived Lesson',
      subject: SubjectKey.physics,
      isArchived: true,
    );
    final active = TeacherLesson(
      id: 'teacher-active-1',
      title: 'Active Lesson',
      subject: SubjectKey.physics,
    );

    final merged = repo.mergedLessons([archived, active]);

    expect(merged.any((l) => l.id == 'teacher-archived-1'), isFalse);
    expect(merged.any((l) => l.id == 'teacher-active-1'), isTrue);
  });

  test(
    'mergedLessons includes archived teacher lessons when includeArchived: true',
    () {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);

      final archived = TeacherLesson(
        id: 'teacher-archived-2',
        title: 'Archived Lesson 2',
        subject: SubjectKey.physics,
        isArchived: true,
      );

      final merged = repo.mergedLessons([archived], includeArchived: true);

      expect(merged.any((l) => l.id == 'teacher-archived-2'), isTrue);
    },
  );
}
