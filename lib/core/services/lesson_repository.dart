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
  LessonRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<List<TeacherLesson>> watchTeacherLessons() {
    return _firestore
        .collection('lessons')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeacherLesson.fromJson(doc.data()))
              .toList(),
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
    return snapshot.docs
        .map((doc) => TeacherLesson.fromJson(doc.data()))
        .toList();
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
    await _firestore.collection('lessons').doc(lessonId).update({
      'isArchived': true,
    });
  }

  /// Soft-deletes a *built-in* lesson by setting `isArchived: true` on its
  /// `/lessons/{id}` override doc -- unlike [archiveLesson] this must
  /// tolerate the doc not existing yet (a built-in only ever gets a Firestore
  /// doc once a teacher first edits/uploads content for it), so it's a
  /// merged `set` seeded with the id/title/subject `TeacherLesson` requires,
  /// rather than an `update` that would throw NOT_FOUND on a fresh doc.
  /// The compiled `kBuiltInLessons` entry itself is never touched -- this
  /// only ever hides the lesson from `mergedLessons` (see `includeArchived`)
  /// and is fully reversible by clearing the same field, so it's independent
  /// of (and unaffected by) `StudentRepository.resetAllProgress`, which only
  /// ever touches `/students/{id}` docs.
  Future<void> archiveBuiltInLesson(Lesson builtIn) async {
    await _firestore.collection('lessons').doc(builtIn.id).set({
      'id': builtIn.id,
      'title': builtIn.title,
      'subject': builtIn.subject.firestoreValue,
      'isArchived': true,
    }, SetOptions(merge: true));
  }

  /// Restores a previously-archived built-in lesson (clears `isArchived`)
  /// without disturbing any other override field a teacher may have set.
  Future<void> restoreBuiltInLesson(String lessonId) async {
    await _firestore.collection('lessons').doc(lessonId).set({
      'isArchived': false,
    }, SetOptions(merge: true));
  }

  List<Lesson> mergedLessons(
    List<TeacherLesson> teacherLessons, {
    bool includeArchived = false,
  }) {
    final builtInIds = kBuiltInLessons.map((l) => l.id).toSet();

    // A Firestore doc sharing a built-in's id lets a teacher override that
    // lesson's own copy -- title/summary/steps/quarter/week/linkedQuizId/
    // pdfUrl/content, plus archiving it -- while the compiled
    // `kBuiltInLessons` entry itself never changes (so "the curriculum can
    // be edited" without ever losing the original if an override is later
    // cleared). See lessons_screen.dart's per-row Edit/Archive actions on
    // built-in rows.
    //
    // The one deliberately narrow exception is `arPayload`: only its
    // `modelIndex` and `markerImage` are teacher-overridable (a lesson can
    // be repointed at a different bundled 3D model, or get a reprinted
    // marker) -- `detectionMode`/`anchorHint`/`lessonSteps`/`title`/
    // `subtitle`/`description`/`keyIdeas` always stay the built-in's own
    // curated AR copy. `LessonForm` doesn't populate those richer fields
    // when it constructs an override's `arPayload` (it has no UI for them),
    // so overlaying that object wholesale would silently blank out the
    // curated post-scan description every time a teacher merely changed a
    // built-in's model index or any other field.
    final contentOverridesByLessonId = {
      for (final tl in teacherLessons)
        if (builtInIds.contains(tl.id)) tl.id: tl,
    };
    final builtIns = kBuiltInLessons
        .where((lesson) {
          final override = contentOverridesByLessonId[lesson.id];
          return includeArchived || override?.isArchived != true;
        })
        .map((lesson) {
          final override = contentOverridesByLessonId[lesson.id];
          if (override == null) return lesson;
          final overrideMarkerImage = override.arPayload?.markerImage;
          final mergedArPayload = override.arPayload == null
              ? (overrideMarkerImage == null || lesson.arPayload == null
                    ? lesson.arPayload
                    : lesson.arPayload!.copyWith(
                        markerImage: overrideMarkerImage,
                      ))
              : (lesson.arPayload?.copyWith(
                      modelIndex: override.arPayload!.modelIndex,
                      markerImage:
                          overrideMarkerImage ?? lesson.arPayload?.markerImage,
                    ) ??
                    override.arPayload);
          return lesson.copyWith(
            title: override.title,
            summary: override.summary ?? lesson.summary,
            steps: override.steps ?? lesson.steps,
            quarter: override.quarter ?? lesson.quarter,
            week: override.week ?? lesson.week,
            linkedQuizId: override.linkedQuizId ?? lesson.linkedQuizId,
            pdfUrl: override.pdfUrl ?? lesson.pdfUrl,
            contentImageUrls: override.contentImageUrls,
            contentStatus: override.contentStatus,
            hasAR: override.hasAR ?? lesson.hasAR,
            arPayload: mergedArPayload,
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
