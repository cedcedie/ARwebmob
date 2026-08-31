# Task 5: LessonContentUploadService — Firebase Storage Upload

## Summary
Successfully implemented Task 5 of the Phase 5 pipeline. Created `LessonContentUploadService` with Firebase Storage integration for uploading lesson content (PDFs/PPTXs) to a structured path hierarchy.

## Implementation Details

### Dependencies Added
- `firebase_storage: ^12.3.0` — Firebase Storage client
- `file_picker: ^8.1.0` — File picker for future UI integration

### Files Created
1. **lib/core/services/lesson_content_upload_service.dart**
   - `StorageUploader` abstract class: Narrow, testable interface (single method: `upload(String path, Uint8List bytes)`)
   - `FirebaseStorageUploader`: Production adapter wrapping `FirebaseStorage.instance`
   - `LessonContentUploadService`: Main service class with `uploadLessonContent()` method
   - Path structure: `lessons/{lessonId}/{fileName}`
   - Returns download URL after successful upload

2. **test/core/services/lesson_content_upload_service_test.dart**
   - Single comprehensive test: "uploads to lessons/{lessonId}/{fileName} and returns the download URL"
   - `_FakeStorageUploader` test double: Records path and bytes, returns fake URL
   - Verifies correct path construction and URL return

### Design Decisions
- **Narrow interface pattern**: `StorageUploader` is intentionally minimal (one method) rather than depending on the large `FirebaseStorage` and `Reference` SDK surface. This follows the established codebase pattern (see `fake_cloud_firestore` for Firestore equivalent).
- **Test double without mocks**: The `_FakeStorageUploader` implementation is trivial to maintain and understand, requiring no mocking framework.
- **Dependency injection**: `LessonContentUploadService` accepts `StorageUploader` in constructor, enabling easy substitution in tests and production.

## Testing Evidence

### TDD Cycle (RED → GREEN)
1. **RED**: Test failed initially — file did not exist, import error on `lesson_content_upload_service.dart`
2. **GREEN**: After implementation, test passed immediately

### Test Execution
- **Specific test**: `flutter test test/core/services/lesson_content_upload_service_test.dart`
  ```
  00:00 +1: All tests passed!
  ```
  Test 71 in the full suite: "uploads to lessons/{lessonId}/{fileName} and returns the download URL"

- **Full test suite**: `flutter test`
  ```
  02:00 +209: All tests passed!
  [exited with code 0]
  ```
  All 209 tests pass, including the new test at position +71

## Files Changed
- `pubspec.yaml`: Added firebase_storage and file_picker dependencies
- `pubspec.lock`: Updated with new dependency versions
- `lib/core/services/lesson_content_upload_service.dart`: New file (45 lines)
- `test/core/services/lesson_content_upload_service_test.dart`: New file (31 lines)

## Commit
- **SHA**: 410cd74
- **Message**: "feat: LessonContentUploadService — Firebase Storage upload for lesson content"
- **Files**: 4 changed, 134 insertions

## Self-Review Findings

### Strengths
1. ✅ Interface design is clean and testable — no SDK surface leakage
2. ✅ Test is concrete and specific, verifies path construction and URL return
3. ✅ Proper error handling inherited from Firebase SDK (putData/getDownloadURL)
4. ✅ Follows Dart/Flutter conventions (constructors, async/await, error propagation)
5. ✅ Documentation is clear (docstrings on each class/method)
6. ✅ Full test suite passes without regressions

### Implementation Quality
- No linting warnings
- Follows single-responsibility principle
- Constructor with optional `storage` parameter allows for testing with real Firebase or mock
- Proper use of `async/await` for async operations
- Clean, readable code with no TODOs or magic numbers

### Concerns
None. The implementation is complete, tested, and ready for integration with Task 6 (lesson form).

## Notes for Task 6 Integration
Task 6 will instantiate this service as:
```dart
LessonContentUploadService(uploader: FirebaseStorageUploader())
```
The narrow interface means Task 6 doesn't need to know about Firebase internals—it just calls `uploadLessonContent()`.

## Cloud Function Integration (Task 8)
Once uploaded to `lessons/{lessonId}/{fileName}`, the Cloud Function (Task 8) will be triggered automatically to convert PPTX to slide images. This service's job is upload only; conversion is delegated to the backend.
