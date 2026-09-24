// lib/features/teacher/lessons/builtin_lesson_content_sheet.dart
//
// Built-in lessons are locked from full editing on purpose (their title,
// subject, and AR marker mapping are the authoritative curriculum -- see
// LessonRepository.mergedLessons' doc comment) -- but that also meant a
// built-in could never carry a teacher-uploaded PDF, since built-ins
// have no real content of their own beyond the AR payload. This is a
// narrower, purpose-built sheet: it can ONLY set a built-in lesson's
// content (PDF), nothing else about the lesson is touched or even
// editable here.
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/lesson.dart';
import '../../../core/models/teacher_lesson.dart';
import '../../../core/services/lesson_content_upload_service.dart';
import '../widgets/error_state.dart';

/// Result of a picked-and-uploaded file — mirrors LessonForm's own
/// `_UploadResult` shape so tests can inject the same fake.
typedef BuiltinContentUploadResult = ({String url, bool isConversionNeeded});

class BuiltinLessonContentSheet extends StatefulWidget {
  const BuiltinLessonContentSheet({
    super.key,
    required this.lesson,
    required this.onUpload,
    this.uploadContentOverride,
  });

  final Lesson lesson;

  /// Called once a file is picked and uploaded, with the resulting
  /// TeacherLesson doc to write (id/title/subject copied from [lesson] so
  /// the write is valid -- LessonRepository.mergedLessons only reads
  /// contentImageUrls/contentStatus back off of it, everything else is
  /// ignored for a built-in id).
  final Future<void> Function(TeacherLesson lesson) onUpload;

  /// Test-only injection point, same pattern as LessonForm's own.
  final Future<BuiltinContentUploadResult?> Function(
    String lessonId,
    String fileName,
    Uint8List bytes,
  )?
  uploadContentOverride;

  static Future<void> show(
    BuildContext context, {
    required Lesson lesson,
    required Future<void> Function(TeacherLesson lesson) onUpload,
    Future<BuiltinContentUploadResult?> Function(String, String, Uint8List)?
    uploadContentOverride,
  }) {
    return showShadDialog<void>(
      context: context,
      builder: (_) => BuiltinLessonContentSheet(
        lesson: lesson,
        onUpload: onUpload,
        uploadContentOverride: uploadContentOverride,
      ),
    );
  }

  @override
  State<BuiltinLessonContentSheet> createState() =>
      _BuiltinLessonContentSheetState();
}

class _BuiltinLessonContentSheetState extends State<BuiltinLessonContentSheet> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    try {
      final BuiltinContentUploadResult? result;
      if (widget.uploadContentOverride != null) {
        result = await widget.uploadContentOverride!(
          widget.lesson.id,
          'content',
          Uint8List(0),
        );
      } else {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
        final file = picked?.files.single;
        final bytes = file?.bytes;
        if (file == null || bytes == null) {
          result = null;
        } else {
          final service = LessonContentUploadService(
            uploader: SupabaseStorageUploader(),
          );
          final url = await service.uploadLessonContent(
            lessonId: widget.lesson.id,
            fileName: file.name,
            bytes: bytes,
          );
          result = (url: url, isConversionNeeded: false);
        }
      }

      if (!mounted) return;
      if (result == null) {
        setState(() => _isUploading = false);
        return;
      }

      final updated = TeacherLesson(
        id: widget.lesson.id,
        title: widget.lesson.title,
        subject: widget.lesson.subject,
        contentImageUrls: [result.url],
        contentStatus: result.isConversionNeeded ? 'processing' : 'ready',
      );
      await widget.onUpload(updated);

      if (!mounted) return;
      setState(() => _isUploading = false);
      Navigator.of(context).pop();
      ShadToaster.of(
        context,
      ).show(const ShadToast(description: Text('Content uploaded')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            humanizeSubmitError(error, actionLabel: 'upload this file'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text('Upload content — ${widget.lesson.title}'),
      description: const Text(
        'Only this lesson\'s content (PDF) is affected — its title, '
        'subject, and AR mapping stay exactly as the built-in curriculum '
        'defines them.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: _isUploading ? null : _pickAndUpload,
          child: Text(_isUploading ? 'Uploading...' : 'Choose file'),
        ),
      ],
    );
  }
}
