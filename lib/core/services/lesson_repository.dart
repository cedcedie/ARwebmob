// lib/core/services/lesson_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/curriculum_data.dart';
import '../models/lesson.dart';
import '../models/teacher_lesson.dart';

/// Reads teacher-authored lessons from `/lessons/{lessonId}` and merges them
/// with the built-in curriculum (`kBuiltInLessons`) — built-ins first, then
/// Firestore-authored ones, deduped by id (PROJECT_FLOW.md Part 4.2's
/// `mergedLessons` pattern; a built-in id always wins on collision, since the
/// built-in curriculum is the authoritative 24-lesson set).
class LessonRepository {
  LessonRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<TeacherLesson>> watchTeacherLessons() {
    return _firestore.collection('lessons').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => TeacherLesson.fromJson(doc.data())).toList(),
        );
  }

  List<Lesson> mergedLessons(List<TeacherLesson> teacherLessons) {
    final builtInIds = kBuiltInLessons.map((l) => l.id).toSet();
    final appended = teacherLessons
        .where((tl) => !builtInIds.contains(tl.id))
        .map(_toLesson);
    return [...kBuiltInLessons, ...appended];
  }

  Lesson _toLesson(TeacherLesson tl) {
    return Lesson(
      id: tl.id,
      title: tl.title,
      subject: tl.subject,
      summary: tl.summary ?? '',
      steps: tl.steps ?? const [],
      labExperimentId: tl.labExperimentId,
      arPayload: tl.arPayload,
      hasAR: tl.hasAR ?? false,
      pdfUrl: tl.pdfUrl,
      isUnlockedByDefault: false,
      curriculum: tl.curriculum,
      week: tl.week,
      quarter: tl.quarter,
    );
  }
}
