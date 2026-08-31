### Task 4: `TeacherLesson` gains `contentImageUrls` + `contentStatus`

**Files:**
- Modify: `lib/core/models/teacher_lesson.dart`
- Test: `test/core/models/teacher_lesson_content_test.dart`

**Interfaces:**
- Produces: two new optional fields on `TeacherLesson` —
  `List<String>? contentImageUrls` and `String? contentStatus`
  (`'processing'` | `'ready'`, or null). Consumed by every later task in
  this plan.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/models/teacher_lesson_content_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/models/subject_key.dart';
import 'package:ar_science_explorer/core/models/teacher_lesson.dart';

void main() {
  test('contentImageUrls and contentStatus round-trip', () {
    final json = {
      'id': 'teacher-1',
      'title': 'Volcanoes',
      'subject': 'chemistry',
      'contentImageUrls': ['https://example.com/slide1.png', 'https://example.com/slide2.png'],
      'contentStatus': 'ready',
    };

    final lesson = TeacherLesson.fromJson(json);

    expect(lesson.contentImageUrls, hasLength(2));
    expect(lesson.contentStatus, 'ready');
    expect(lesson.toJson()['contentStatus'], 'ready');
  });

  test('both fields default to null when absent', () {
    final lesson = TeacherLesson.fromJson(const {
      'id': 'teacher-2', 'title': 'No content yet', 'subject': 'biology',
    });

    expect(lesson.contentImageUrls, isNull);
    expect(lesson.contentStatus, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/teacher_lesson_content_test.dart`
Expected: FAIL — the two fields don't exist on `TeacherLesson` yet.

- [ ] **Step 3: Add the fields**

Read `lib/core/models/teacher_lesson.dart`'s real current content first
(it's grown since Phase 1 — this plan's earlier File Structure section
does not enumerate every existing field). Add inside the `const factory
TeacherLesson({...})` constructor, alongside the existing `pdfUrl` field:

```dart
    List<String>? contentImageUrls,
    String? contentStatus, // 'processing' | 'ready' | null
```

- [ ] **Step 4: Regenerate freezed/json_serializable code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/models/teacher_lesson_content_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Run the full suite to confirm nothing else broke**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/teacher_lesson.dart lib/core/models/teacher_lesson.freezed.dart \
        lib/core/models/teacher_lesson.g.dart test/core/models/teacher_lesson_content_test.dart
git commit -m "feat: TeacherLesson gains contentImageUrls + contentStatus (Part 8)"
```

---

