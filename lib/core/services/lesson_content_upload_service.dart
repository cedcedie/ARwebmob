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
