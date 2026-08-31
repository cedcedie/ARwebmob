### Task 6: Teacher lesson form — PPTX/PDF upload UI

**Files:**
- Modify: `lib/features/teacher/lessons/lesson_form.dart`
- Test: `test/features/teacher/lessons/lesson_form_content_upload_test.dart`

**Interfaces:**
- Consumes: `LessonContentUploadService` (Task 5), `file_picker`'s
  `FilePicker`.
- Produces: a file-picker button in the lesson form that uploads the
  selected `.pptx`/`.pdf`, sets `contentImageUrls: [uploadedUrl]` and
  `contentStatus: 'processing'` on submit (the Cloud Function, Task 8,
  later expands a PPTX's single uploaded-file URL into the real
  multi-slide-image array and flips `contentStatus` to `'ready'`; for a
  plain PDF, this task's own logic should set `contentStatus: 'ready'`
  immediately, since no conversion is needed).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/teacher/lessons/lesson_form_content_upload_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/features/teacher/lessons/lesson_form.dart';

void main() {
  testWidgets('uploading a .pptx sets contentStatus to processing on submit', (tester) async {
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/teacher/lessons/lesson_form_content_upload_test.dart`
Expected: FAIL — `LessonForm` doesn't have an `uploadContentOverride`
parameter or upload button yet.

- [ ] **Step 3: Implement**

Read `lib/features/teacher/lessons/lesson_form.dart`'s real current content
in full first (Task 3 of this plan already showed a snapshot above, but
re-verify before editing — other tasks in this plan may have touched it).
Add:

```dart
// Add to LessonForm's constructor:
  const LessonForm({
    super.key,
    this.initial,
    required this.quizOptions,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.uploadContentOverride, // test-only injection point
  });

  // ... existing fields ...
  final Future<({String url, bool isConversionNeeded})> Function(String fileName, Uint8List bytes)?
      uploadContentOverride;
```

```dart
// Add to LessonFormState:
  String? _uploadedContentUrl;
  bool _uploadedContentNeedsConversion = false;

  Future<void> _pickAndUploadContent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pptx', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;

    final isConversionNeeded = file!.extension?.toLowerCase() == 'pptx';
    final ({String url, bool isConversionNeeded}) uploadResult;
    if (widget.uploadContentOverride != null) {
      uploadResult = await widget.uploadContentOverride!(file.name, file.bytes!);
    } else {
      final lessonId = widget.initial?.id ?? 'teacher-${DateTime.now().millisecondsSinceEpoch}';
      final service = LessonContentUploadService(uploader: FirebaseStorageUploader());
      final url = await service.uploadLessonContent(
        lessonId: lessonId, fileName: file.name, bytes: file.bytes!,
      );
      uploadResult = (url: url, isConversionNeeded: isConversionNeeded);
    }

    setState(() {
      _uploadedContentUrl = uploadResult.url;
      _uploadedContentNeedsConversion = uploadResult.isConversionNeeded;
    });
  }
```

Add the button to the form's `build()` (near the existing content-related
fields):

```dart
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('lesson-upload-content'),
              onPressed: _pickAndUploadContent,
              icon: const Icon(Icons.upload_file),
              label: Text(_uploadedContentUrl == null ? 'Upload PPTX or PDF' : 'Content uploaded'),
            ),
```

Update `_handleSubmit()`'s `TeacherLesson(...)` construction to include:
```dart
      contentImageUrls: _uploadedContentUrl != null
          ? [_uploadedContentUrl!]
          : widget.initial?.contentImageUrls,
      contentStatus: _uploadedContentUrl == null
          ? widget.initial?.contentStatus
          : (_uploadedContentNeedsConversion ? 'processing' : 'ready'),
```

Add the needed imports: `dart:typed_data`, `package:file_picker/file_picker.dart`,
`../../../core/services/lesson_content_upload_service.dart` (this last one
brings in both `LessonContentUploadService` and `FirebaseStorageUploader`).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/teacher/lessons/lesson_form_content_upload_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass (this modifies an existing, tested file —
`lessons_screen_test.dart`/other `LessonForm` consumers must still pass
unchanged, since `uploadContentOverride` is optional and every other field
is untouched).

- [ ] **Step 6: Commit**

```bash
git add lib/features/teacher/lessons/lesson_form.dart \
        test/features/teacher/lessons/lesson_form_content_upload_test.dart
git commit -m "feat: teacher lesson form — PPTX/PDF upload UI"
```

---

