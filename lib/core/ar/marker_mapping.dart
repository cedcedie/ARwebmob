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

/// Whether [marker] (an `arPayload.markerImage`/`markerAssetForLesson` value)
/// is a real network URL -- true for a teacher-uploaded marker (a Firebase
/// Storage download URL), false for the built-in curriculum's bundled
/// `/markers/QxWy.jpg` scheme.
bool isNetworkMarker(String marker) =>
    marker.startsWith('http://') || marker.startsWith('https://');

/// Resolves a built-in `/markers/QxWy.jpg` value to the actual pubspec asset
/// path (`assets/markers/QxWy.jpg`) that `Image.asset`/`rootBundle.load`
/// expect. Only meaningful when [isNetworkMarker] is false -- a network URL
/// is used as-is.
String markerAssetPath(String marker) =>
    marker.startsWith('/') ? 'assets$marker' : 'assets/$marker';

/// Extracts a quarter/week pair from a Vuforia trackable name and finds the
/// matching lesson. `trackableName` is `ObserverBehaviour.TargetName` --
/// Vuforia's ImageTarget database entry name -- which in this project's
/// database is spelled out in full (e.g. "Quarter2Week1"), not the abbreviated
/// `Q<n>W<n>` some model GameObjects use (e.g. "DemocritusAtomQ1W1" or
/// "q3w2inclined_plane_slide_playground"). Matches "quarter"/"week" as
/// optional, so both the abbreviated and spelled-out forms resolve to the
/// same lesson. Case-insensitive because trackable/GameObject names in the
/// Unity scene are inconsistently cased. Returns null if no quarter/week
/// pattern is found in the name, or if no lesson matches the extracted values.
Lesson? lessonForTrackableName(
  List<Lesson> orderedLessons,
  String trackableName,
) {
  final match = RegExp(
    r'q(?:uarter)?\s*(\d+)\s*w(?:eek)?\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(trackableName);
  if (match == null) return null;
  final quarter = int.parse(match.group(1)!);
  final week = int.parse(match.group(2)!);
  for (final lesson in orderedLessons) {
    if (lesson.quarter == quarter && lesson.week == week) return lesson;
  }
  return null;
}
