import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Narrow upload interface `LessonContentUploadService` depends on — makes
/// the service trivially fakeable in tests without mocking the full
/// `FirebaseStorage`/`Reference` SDK surface.
abstract class StorageUploader {
  Future<String> upload(String path, Uint8List bytes);
}

/// How long an upload is allowed to sit with no completion before we give up
/// on it. The Storage SDK retries a stalled/flaky `putData` transfer on its
/// own, silently, with no surfaced error and no bound on how long it keeps
/// trying — from the teacher's side that reads as "picks the file, then
/// hangs on 'Uploading...' forever." Capping it here turns that into a clear,
/// retryable failure instead.
const _uploadTimeout = Duration(seconds: 60);

/// Real, production `StorageUploader` backed by `firebase_storage`.
class FirebaseStorageUploader implements StorageUploader {
  FirebaseStorageUploader({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> upload(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    final task = ref.putData(bytes);
    try {
      await task.timeout(_uploadTimeout);
    } on TimeoutException {
      // Best-effort cancel of the still-running transfer — its result no
      // longer matters here, but leaving it uncancelled would keep retrying
      // in the background for a file the caller has already been told
      // failed.
      unawaited(task.cancel());
      throw StateError(
        "Upload timed out — check your connection and try again.",
      );
    }
    return ref.getDownloadURL();
  }
}

/// Uploads a teacher's lesson content file (PDF or PPTX) to Firebase
/// Storage under lessons/{lessonId}/{fileName}. The PPTX-to-slide-images
/// conversion itself is NOT this class's job — that's the Cloud Function
/// (Task 8), triggered automatically once this upload lands in Storage.
class LessonContentUploadService {
  LessonContentUploadService({required StorageUploader uploader})
    : _uploader = uploader;

  final StorageUploader _uploader;

  Future<String> uploadLessonContent({
    required String lessonId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _uploader.upload('lessons/$lessonId/$fileName', bytes);
  }
}
