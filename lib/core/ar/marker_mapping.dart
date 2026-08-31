import '../models/lesson.dart';

String markerAssetForLesson(Lesson lesson) {
  final override = lesson.arPayload?.markerImage;
  if (override != null) return override;
  // Root-relative, no `assets/` prefix -- matches the scheme every
  // explicit arPayload.markerImage override in curriculum_data.dart uses
  // (e.g. '/markers/Q1W1.jpg'). This branch is otherwise dead in production
  // data today (23/24 lessons set an override; the remaining lesson has no
  // arPayload at all), but keeping it consistent avoids an unresolvable
  // path if it's ever exercised.
  return '/markers/Q${lesson.quarter}W${lesson.week}.jpg';
}

/// Extracts the `Q<n>W<n>` pattern from a Vuforia trackable name (e.g.
/// "DemocritusAtomQ1W1" -> lesson with quarter 1, week 1) and finds the
/// matching lesson. Case-insensitive because trackable names in the Unity
/// scene are inconsistently cased (e.g. "q3w2inclined_plane_slide_playground"
/// vs "DemocritusAtomQ1W1"). Returns null if no `Q<n>W<n>` pattern is found
/// in the name, or if no lesson matches the extracted quarter/week.
Lesson? lessonForTrackableName(List<Lesson> orderedLessons, String trackableName) {
  final match = RegExp(r'[Qq](\d+)[Ww](\d+)').firstMatch(trackableName);
  if (match == null) return null;
  final quarter = int.parse(match.group(1)!);
  final week = int.parse(match.group(2)!);
  for (final lesson in orderedLessons) {
    if (lesson.quarter == quarter && lesson.week == week) return lesson;
  }
  return null;
}
