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

  /// One-shot fetch of teacher-authored lessons, for callers that already
  /// have their own live-update trigger (e.g. `watchStudent`) and just need
  /// the current teacher-lesson snapshot to merge in — avoids opening (and
  /// tearing down) a fresh `snapshots()` subscription on every emission of
  /// some other stream, which `watchTeacherLessons().first` would otherwise
  /// do if called repeatedly inside an `asyncMap`.
  Future<List<TeacherLesson>> fetchTeacherLessons() async {
    final snapshot = await _firestore.collection('lessons').get();
    return snapshot.docs.map((doc) => TeacherLesson.fromJson(doc.data())).toList();
  }

  /// Creates (or overwrites) a teacher-authored lesson doc at
  /// `/lessons/{lesson.id}`.
  Future<void> createLesson(TeacherLesson lesson) async {
    await _firestore.collection('lessons').doc(lesson.id).set(lesson.toJson());
  }

  /// Overwrites an existing teacher-authored lesson doc with [lesson]'s data.
  Future<void> updateLesson(TeacherLesson lesson) async {
    await _firestore.collection('lessons').doc(lesson.id).set(lesson.toJson());
  }

  /// Soft-deletes a teacher-authored lesson by setting `isArchived: true`,
  /// without touching any other field — lessons may already be referenced by
  /// id elsewhere (e.g. `linkedQuizId`, students' `unlockedLessonIds`), so a
  /// hard delete would leave dangling references.
  Future<void> archiveLesson(String lessonId) async {
    await _firestore.collection('lessons').doc(lessonId).update({'isArchived': true});
  }

  List<Lesson> mergedLessons(
    List<TeacherLesson> teacherLessons, {
    bool includeArchived = false,
  }) {
    final builtInIds = kBuiltInLessons.map((l) => l.id).toSet();
    final appended = teacherLessons
        .where((tl) => !builtInIds.contains(tl.id))
        .where((tl) => includeArchived || !tl.isArchived)
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
