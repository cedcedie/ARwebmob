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
    'mergedLessons dedupes by id, never appending a second entry for a '
    'built-in id',
    () {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);

      // A teacher-authored doc sharing a built-in's id overrides that one
      // row in place (see the next test) -- it must never appear as a
      // second, separate entry alongside the built-in.
      final colliding = TeacherLesson(
        id: 'q1w1',
        title: 'Edited via the teacher UI',
        subject: SubjectKey.chemistry,
      );

      final merged = repo.mergedLessons([colliding]);

      expect(merged.length, kBuiltInLessons.length);
      expect(merged.where((l) => l.id == 'q1w1'), hasLength(1));
    },
  );

  test(
    'mergedLessons lets a teacher-authored doc override a built-in lesson\'s '
    'own fields (the Lessons screen\'s Edit action on a built-in row), while '
    'never touching kBuiltInLessons itself',
    () {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);
      final original = kBuiltInLessons.firstWhere((l) => l.id == 'q1w1');

      final edited = TeacherLesson(
        id: 'q1w1',
        title: 'Renamed by a teacher',
        subject: SubjectKey.chemistry,
        summary: 'A rewritten summary',
      );

      final merged = repo.mergedLessons([edited]);
      final result = merged.firstWhere((l) => l.id == 'q1w1');

      expect(result.title, 'Renamed by a teacher');
      expect(result.summary, 'A rewritten summary');
      // The compiled curriculum constant is never mutated -- clearing the
      // override (or simply never creating one) always falls back to it.
      expect(
        kBuiltInLessons.firstWhere((l) => l.id == 'q1w1').title,
        original.title,
      );
    },
  );

  test(
    'mergedLessons hides a built-in lesson once its override is archived, '
    'and includes it again with includeArchived: true',
    () {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);

      final archivedOverride = TeacherLesson(
        id: 'q1w1',
        title: kBuiltInLessons.first.title,
        subject: SubjectKey.chemistry,
        isArchived: true,
      );

      final visible = repo.mergedLessons([archivedOverride]);
      expect(visible.any((l) => l.id == 'q1w1'), isFalse);
      expect(visible.length, kBuiltInLessons.length - 1);

      final withArchived = repo.mergedLessons(
        [archivedOverride],
        includeArchived: true,
      );
      expect(withArchived.any((l) => l.id == 'q1w1'), isTrue);
      expect(withArchived.length, kBuiltInLessons.length);
    },
  );

  test(
    'archiveBuiltInLesson creates the override doc when none exists yet',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);
      final builtIn = kBuiltInLessons.first;

      await repo.archiveBuiltInLesson(builtIn);

      final doc = await firestore.collection('lessons').doc(builtIn.id).get();
      expect(doc.data()!['isArchived'], isTrue);
      expect(doc.data()!['title'], builtIn.title);

      final merged = repo.mergedLessons([
        TeacherLesson.fromJson(doc.data()!),
      ]);
      expect(merged.any((l) => l.id == builtIn.id), isFalse);
    },
  );

  test(
    'restoreBuiltInLesson clears isArchived without disturbing other fields',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = LessonRepository(firestore: firestore);
      final builtIn = kBuiltInLessons.first;

      await repo.archiveBuiltInLesson(builtIn);
      await repo.restoreBuiltInLesson(builtIn.id);

      final doc = await firestore.collection('lessons').doc(builtIn.id).get();
      expect(doc.data()!['isArchived'], isFalse);
      expect(doc.data()!['title'], builtIn.title);
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
