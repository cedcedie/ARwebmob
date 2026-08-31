### Task 5: `LessonContentUploadService` — Firebase Storage upload

**Files:**
- Modify: `pubspec.yaml` (add `firebase_storage`, `file_picker`)
- Create: `lib/core/services/lesson_content_upload_service.dart`
- Test: `test/core/services/lesson_content_upload_service_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks. Defines its own narrow
  `StorageUploader` interface (below) rather than depending on
  `firebase_storage`'s full `FirebaseStorage`/`Reference` API surface
  directly — this codebase's established pattern
  (`fake_cloud_firestore` for Firestore) has no equivalent fake for
  `firebase_storage`, and `FirebaseStorage`/`Reference` are large concrete
  SDK classes with many members, not designed to be faked wholesale. A
  narrow, single-purpose interface this class owns is easy to fake for
  real in tests and easy to adapt the real SDK to in production.
- Produces: `abstract class StorageUploader` (one method:
  `Future<String> upload(String path, Uint8List bytes)`),
  `class FirebaseStorageUploader implements StorageUploader` (the real,
  production adapter wrapping `FirebaseStorage.instance`), and
  `class LessonContentUploadService` with constructor
  `LessonContentUploadService({required StorageUploader uploader})`, method
  `Future<String> uploadLessonContent({required String lessonId, required String fileName, required Uint8List bytes})`
  — uploads to `lessons/{lessonId}/{fileName}` and returns the download
  URL. Consumed by Task 6's lesson form, which constructs
  `LessonContentUploadService(uploader: FirebaseStorageUploader())` for
  real use.

- [ ] **Step 1: Add dependencies**

Edit `pubspec.yaml`, add under `dependencies:`:
```yaml
  firebase_storage: ^12.3.0
  file_picker: ^8.1.0
```
Run: `flutter pub get`

- [ ] **Step 2: Write the failing test**

```dart
// test/core/services/lesson_content_upload_service_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ar_science_explorer/core/services/lesson_content_upload_service.dart';

class _FakeStorageUploader implements StorageUploader {
  String? lastPath;
  Uint8List? lastBytes;

  @override
  Future<String> upload(String path, Uint8List bytes) async {
    lastPath = path;
    lastBytes = bytes;
    return 'https://fake-storage.example/$path';
  }
}

void main() {
  test('uploads to lessons/{lessonId}/{fileName} and returns the download URL', () async {
    final fakeUploader = _FakeStorageUploader();
    final service = LessonContentUploadService(uploader: fakeUploader);

    final url = await service.uploadLessonContent(
      lessonId: 'teacher-1',
      fileName: 'slides.pptx',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(fakeUploader.lastPath, 'lessons/teacher-1/slides.pptx');
    expect(fakeUploader.lastBytes, [1, 2, 3]);
    expect(url, 'https://fake-storage.example/lessons/teacher-1/slides.pptx');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/core/services/lesson_content_upload_service_test.dart`
Expected: FAIL — file doesn't exist yet.

- [ ] **Step 4: Implement**

```dart
// lib/core/services/lesson_content_upload_service.dart
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Narrow upload interface `LessonContentUploadService` depends on — makes
/// the service trivially fakeable in tests without mocking the full
/// `FirebaseStorage`/`Reference` SDK surface.
abstract class StorageUploader {
  Future<String> upload(String path, Uint8List bytes);
}

/// Real, production `StorageUploader` backed by `firebase_storage`.
class FirebaseStorageUploader implements StorageUploader {
  FirebaseStorageUploader({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}

/// Uploads a teacher's lesson content file (PDF or PPTX) to Firebase
/// Storage under lessons/{lessonId}/{fileName}. The PPTX-to-slide-images
/// conversion itself is NOT this class's job — that's the Cloud Function
/// (Task 8), triggered automatically once this upload lands in Storage.
class LessonContentUploadService {
  LessonContentUploadService({required StorageUploader uploader}) : _uploader = uploader;

  final StorageUploader _uploader;

  Future<String> uploadLessonContent({
    required String lessonId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _uploader.upload('lessons/$lessonId/$fileName', bytes);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/services/lesson_content_upload_service_test.dart`
Expected: PASS (1 test).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/services/lesson_content_upload_service.dart \
        test/core/services/lesson_content_upload_service_test.dart
git commit -m "feat: LessonContentUploadService — Firebase Storage upload for lesson content"
```

---

