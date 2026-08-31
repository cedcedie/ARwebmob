import 'dart:typed_data';

import 'package:flutter/material.dart';
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
      MaterialApp(
        home: Scaffold(
          body: LessonForm(
            quizOptions: const [],
            onSubmit: (lesson) async => submitted = lesson,
            // Test-only injection point — see Step 3's implementation note:
            // the real upload call is abstracted behind a function the
            // widget accepts, so this test can simulate "a file was picked
            // and uploaded" without touching real file-picker/Storage APIs.
            uploadContentOverride: (fileName, bytes) async => (
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
}
