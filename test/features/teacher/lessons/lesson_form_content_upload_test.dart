import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/teacher/lessons/lesson_form.dart';

void main() {
  testWidgets('uploading a .pptx sets contentStatus to processing on submit', (tester) async {
    // The form's content exceeds the default 800x600 test surface; enlarge
    // it so every field (including the new upload button) is reachable by
    // tap() without needing scrollUntilVisible for each interaction.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TeacherLesson? submitted;

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: LessonForm(
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            // Test-only injection point — see Step 3's implementation note:
            // the real upload call is abstracted behind a function the
            // widget accepts, so this test can simulate "a file was picked
            // and uploaded" without touching real file-picker/Storage APIs.
            uploadContentOverride: (lessonId, fileName, bytes) async => (
              url: 'https://fake-storage.example/slides.pptx',
              isConversionNeeded: true,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('lesson-title')), 'Volcanoes');
    await tester.tap(find.byKey(const Key('lesson-upload-content')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.contentStatus, 'processing');
    expect(submitted!.contentImageUrls, ['https://fake-storage.example/slides.pptx']);
  });

  testWidgets('uses the SAME lesson id for the Storage upload and the submitted new lesson',
      (tester) async {
    // Regression test for the final whole-branch review's Fix 1: for a
    // brand-new lesson (widget.initial == null), _pickAndUploadContent and
    // _handleSubmit used to independently derive
    // `'teacher-${DateTime.now().millisecondsSinceEpoch}'` at different
    // wall-clock moments, so the uploaded file landed under one lesson id
    // in Storage while the Firestore doc was created under a different
    // one — the Cloud Function's later Firestore update then targeted a
    // document that didn't exist. The lesson id must now be derived once
    // and reused for both.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TeacherLesson? submitted;
    String? uploadedForLessonId;

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: LessonForm(
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            uploadContentOverride: (lessonId, fileName, bytes) async {
              uploadedForLessonId = lessonId;
              return (
                url: 'https://fake-storage.example/slides.pptx',
                isConversionNeeded: true,
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('lesson-title')), 'Volcanoes');
    await tester.tap(find.byKey(const Key('lesson-upload-content')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    expect(uploadedForLessonId, isNotNull);
    expect(submitted, isNotNull);
    expect(submitted!.id, uploadedForLessonId);
  });

  testWidgets(
      'submits the server-converted result instead of stale local "processing" state '
      'when the Cloud Function finishes converting before Save is clicked', (tester) async {
    // Regression test for the final whole-branch review's Fix 5: the
    // Cloud Function can flip a lesson doc's contentStatus to 'ready' with
    // real slide URLs in the time between upload and Save being clicked.
    // Since LessonRepository.updateLesson does a full `.set()` overwrite,
    // submitting the form's stale local 'processing' snapshot would
    // permanently clobber that real result. The form must re-fetch the
    // current doc via `refetchLesson` right before submit and prefer it.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TeacherLesson? submitted;
    final existing = TeacherLesson(
      id: 'teacher-123',
      title: 'Volcanoes',
      subject: SubjectKey.chemistry,
      createdAt: '2026-08-01T00:00:00.000Z',
    );

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: LessonForm(
            initial: existing,
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            uploadContentOverride: (lessonId, fileName, bytes) async => (
              url: 'https://fake-storage.example/raw.pptx',
              isConversionNeeded: true,
            ),
            refetchLesson: (lessonId) async => existing.copyWith(
              contentStatus: 'ready',
              contentImageUrls: const ['https://fake-storage.example/slide-1.png'],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('lesson-upload-content')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-submit')));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.contentStatus, 'ready');
    expect(submitted!.contentImageUrls, ['https://fake-storage.example/slide-1.png']);
  });

  testWidgets(
      'shows an error toast and re-enables the button when the upload throws',
      (tester) async {
    // Regression test for round 6's item 1: a throwing upload used to be an
    // unhandled Future error with zero feedback. It must now surface a
    // human-readable error toast and leave the button re-enabled (not stuck
    // in a permanent busy state) so the teacher can retry.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    TeacherLesson? submitted;

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: LessonForm(
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            uploadContentOverride: (lessonId, fileName, bytes) async {
              throw Exception('storage permission denied');
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('lesson-title')), 'Volcanoes');
    await tester.tap(find.byKey(const Key('lesson-upload-content')));
    await tester.pumpAndSettle();

    // No unhandled exception reached the test binding (pumpAndSettle above
    // would have surfaced it), and an error toast is shown.
    expect(find.byType(ShadToast), findsOneWidget);

    // The button re-enabled (not stuck disabled in a permanent busy state).
    final button = tester.widget<ShadButton>(
      find.byKey(const Key('lesson-upload-content')),
    );
    expect(button.onPressed, isNotNull);

    expect(submitted, isNull);
  });
}
