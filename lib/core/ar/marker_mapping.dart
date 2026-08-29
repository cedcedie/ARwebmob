import '../models/lesson.dart';

String markerAssetForLesson(Lesson lesson) {
  final override = lesson.arPayload?.markerImage;
  if (override != null) return override;
  return 'assets/markers/Q${lesson.quarter}W${lesson.week}.jpg';
}

Lesson? lessonForMarkerIndex(List<Lesson> orderedLessons, int markerIndex) {
  for (final lesson in orderedLessons) {
    if (lesson.arPayload?.modelIndex == markerIndex) return lesson;
  }
  return null;
}
