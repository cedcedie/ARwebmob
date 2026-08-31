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
