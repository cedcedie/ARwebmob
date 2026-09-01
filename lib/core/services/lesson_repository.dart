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

  /// One-shot fetch of a single teacher-authored lesson doc by id, or
  /// `null` if no such doc exists — used by `LessonForm` to check whether
  /// a server-side PPTX conversion has already completed (`contentStatus:
  /// 'ready'` with real slide URLs) before the form's own submit would
  /// otherwise overwrite it with stale local `'processing'` state (final
  /// whole-branch review Fix 5).
  Future<TeacherLesson?> fetchLessonById(String lessonId) async {
    final doc = await _firestore.collection('lessons').doc(lessonId).get();
    final data = doc.data();
    if (data == null) return null;
    return TeacherLesson.fromJson(data);
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

    // A Firestore doc sharing a built-in's id is normally fully discarded
    // (the built-in curriculum's identity -- title, subject, AR mapping --
    // is authoritative and must never be silently overwritten). But
    // built-ins have no way to carry teacher-uploaded PDF/PPTX content of
    // their own, since that upload flow always writes through this same
    // /lessons/{id} doc -- so as a narrow, deliberate exception, ONLY
    // contentImageUrls/contentStatus get overlaid from a matching doc onto
    // the built-in Lesson, leaving every other field exactly as the
    // built-in curriculum defines it. See lessons_screen.dart's "Upload
    // Content" action on built-in rows, which writes only those two
    // fields (plus the id/title/subject required to satisfy TeacherLesson
    // itself) for exactly this purpose.
    final contentOverridesByLessonId = {
      for (final tl in teacherLessons)
        if (builtInIds.contains(tl.id)) tl.id: tl,
    };
    final builtIns = kBuiltInLessons.map((lesson) {
      final override = contentOverridesByLessonId[lesson.id];
      if (override == null) return lesson;
      return lesson.copyWith(
        contentImageUrls: override.contentImageUrls,
        contentStatus: override.contentStatus,
      );
    });

    final appended = teacherLessons
        .where((tl) => !builtInIds.contains(tl.id))
        .where((tl) => includeArchived || !tl.isArchived)
        .map(_toLesson);
    return [...builtIns, ...appended];
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
      contentImageUrls: tl.contentImageUrls,
      contentStatus: tl.contentStatus,
      isUnlockedByDefault: false,
      curriculum: tl.curriculum,
      week: tl.week,
      quarter: tl.quarter,
      linkedQuizId: tl.linkedQuizId,
    );
  }
}
